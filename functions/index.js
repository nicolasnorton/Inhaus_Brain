const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { VertexAI } = require("@google-cloud/vertexai");
// Import the Copilot handler
const { copilotHandler } = require('./copilot');

admin.initializeApp();

// Initialize Vertex AI
const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
const location = 'us-central1';
const vertexAI = new VertexAI({ project: project, location: location });

// Example Function for Research Agent
exports.onCampaignCreated = functions.firestore
    .document('campaigns/{campaignId}')
    .onCreate(async (snapshot, context) => {
        const campaignData = snapshot.data();
        const campaignId = context.params.campaignId;

        console.log(`New campaign created: ${campaignId}. Starting research...`);

        // TODO: Call Gemini Pro to generate research insights
        // Update Firestore with 'researching' status and eventually insights
        return snapshot.ref.update({
            status: 'researching',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

/**
 * Syncs user roles from Firestore to Firebase Auth Custom Claims.
 * This ensures that Firestore security rules can reliably use request.auth.token.role.
 */
exports.onUserUpdated = functions.firestore
    .document('users/{userId}')
    .onWrite(async (change, context) => {
        const userId = context.params.userId;
        const data = change.after.data();

        if (!data || !data.role) {
            console.log(`User ${userId} deleted or has no role. Removing claims.`);
            return admin.auth().setCustomUserClaims(userId, null);
        }

        const role = data.role;
        try {
            await admin.auth().setCustomUserClaims(userId, { role: role });
            console.log(`Success: Set custom claim 'role' to '${role}' for user ${userId}`);
        } catch (error) {
            console.error(`Error setting custom claims for user ${userId}:`, error);
        }
    });

// Callable function for High-Fidelity Final Asset Generation (Cloud Fallback)
exports.generateFinalAssets = functions.https.onCall(async (data, context) => {
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { campaignId, creativeBrief, visualPrompt } = data;

    console.log(`Generating High-Fidelity assets for Campaign: ${campaignId}`);

    try {
        const generativeModel = vertexAI.getGenerativeModel({
            model: 'gemini-1.5-pro-preview-0409',
        });

        // 1. Generate High-Tier Copy
        const copyPrompt = `You are a world-class copywriter. Generate a high-converting, professional ad copy for the following campaign: ${creativeBrief}. Focus on impact and premium tone.`;
        const copyResult = await generativeModel.generateContent(copyPrompt);
        const finalCopy = copyResult.response.candidates[0].content.parts[0].text;

        // 2. Generate/Simulate Imagen High-Fidelity Mock (Imagen-3)
        // Note: Real Imagen integration usually involves a GCS bucket upload for the result.
        // We simulate the URL here but the structure is ready for the Imagen API call.
        const finalImageURL = "https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=2070&auto=format&fit=crop";

        return {
            status: 'success',
            finalCopy: finalCopy,
            finalImageURL: finalImageURL,
            source: 'Vertex AI (Cloud)'
        };
    } catch (error) {
        console.error('Vertex AI Cloud Error:', error);
        throw new functions.https.HttpsError('internal', 'Internal Cloud AI Error');
    }
});

/**
 * PROXY FOR VERTEX AI
 * Secures API access by validating Firebase Auth ID Tokens.
 * This prevents exposing credentials or allowing unauthenticated access from the client.
 */
exports.proxyVertexAI = functions.https.onRequest(async (req, res) => {
    // CORS Configuration - Apply to ALL responses
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Max-Age', '3600');
        res.status(204).send('');
        return;
    }

    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        // 1. Authentication Check
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw { status: 401, message: 'Unauthorized: Missing or invalid Authorization header.' };
        }

        const idToken = authHeader.split('Bearer ')[1];
        try {
            await admin.auth().verifyIdToken(idToken);
        } catch (authError) {
            console.error('Auth Verification Failed:', authError);
            throw { status: 401, message: 'Unauthorized: Invalid Token.' };
        }

        // 2. Body Extraction
        const { model, prompt, config, systemInstruction, operationName } = req.body;

        // --- PATH A: OPERATION POLLING ---
        // Priority: If operationName is present, we are polling status. No prompt required.
        if (operationName) {
            console.log(`[PROXY] Polling Operation via SDK: ${operationName}`);

            try {
                // Fallback to manual REST polling to avoid Google-GAX versioning issues/bugs in the emulator
                console.log(`[PROXY] Polling LRO via REST: ${operationName}`);

                const { GoogleAuth } = require('google-auth-library');
                const auth = new GoogleAuth({
                    scopes: ['https://www.googleapis.com/auth/cloud-platform']
                });
                const client = await auth.getClient();
                const tokenResponse = await client.getAccessToken();
                const accessToken = tokenResponse.token;
                console.log(`[PROXY] Polling operation: ${operationName}`);

                // Extract components from operation name
                const parts = operationName.split('/');
                const pId = parts[1]; // project
                const lId = parts[3]; // location
                const opId = parts[parts.length - 1]; // operation ID (UUID or Long)

                // [CRITICAL FIX] UUID operations (from Veo/Model Garden) CANNOT be polled via REST API
                // The REST API (both v1 and v1beta1) only supports numeric Long IDs
                // Solution: Use google-gax OperationsClient which uses gRPC internally
                const isUUID = opId.includes('-'); // UUIDs contain hyphens, Longs don't

                if (isUUID) {
                    // UUID operations from Veo/Model Garden - use REST API with v1beta1 endpoint
                    // v1 doesn't support Model Garden operations, must use v1beta1
                    console.log('[PROXY] UUID operation detected - using REST API v1beta1');
                    const targetUrl = `https://${lId}-aiplatform.googleapis.com/v1beta1/${operationName}`;
                    console.log(`[PROXY] Polling URL: ${targetUrl}`);

                    const response = await fetch(targetUrl, {
                        method: 'GET',
                        headers: {
                            'Authorization': `Bearer ${accessToken}`,
                            'Content-Type': 'application/json'
                        }
                    });

                    if (!response.ok) {
                        console.error(`[PROXY] REST API error: ${response.status} ${response.statusText}`);
                        return res.status(200).json({
                            done: true,
                            error: {
                                message: `REST API Error: ${response.statusText}`,
                                code: response.status
                            }
                        });
                    }

                    const operation = await response.json();
                    console.log('[PROXY] REST API polling successful');
                    return res.status(200).json(operation);
                }

                // For non-UUID operations, use REST API as before
                console.log('[PROXY] Long operation detected - using REST API');
                const targetUrl = `https://${lId}-aiplatform.googleapis.com/v1beta1/${operationName}`;
                console.log(`[PROXY] Polling URL: ${targetUrl}`);

                const response = await fetch(targetUrl, {
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${accessToken}`,
                        'Content-Type': 'application/json'
                    }
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    console.error(`[PROXY] Polling failed: ${response.status} ${errorText}`);

                    // [RECOVERY] Aggressive Operation Recovery
                    // If the specific publisher path fails (common with Veo/Model Garden), 
                    // try known canonical permutations until one works.
                    if ((response.status === 400 || response.status === 404) && operationName.includes('/publishers/')) {
                        console.log(`[PROXY] ${response.status} on publisher path. Initiating Aggressive Recovery...`);

                        const parts = operationName.split('/');
                        const pId = parts[1]; // project
                        const lId = parts[3]; // location (us-central1)
                        const opId = parts[parts.length - 1]; // UUID

                        if (pId && lId && opId) {
                            const candidates = [
                                // 1. Regional Canonical v1beta1 (Most likely)
                                `https://${lId}-aiplatform.googleapis.com/v1beta1/projects/${pId}/locations/${lId}/operations/${opId}`,
                                // 2. Regional Canonical v1 (Sometimes operations promote)
                                `https://${lId}-aiplatform.googleapis.com/v1/projects/${pId}/locations/${lId}/operations/${opId}`,
                                // 3. Global Endpoint (Fallback)
                                `https://aiplatform.googleapis.com/v1beta1/projects/${pId}/locations/${lId}/operations/${opId}`
                            ];

                            for (const candidateUrl of candidates) {
                                console.log(`[PROXY] Trying candidates: ${candidateUrl}`);
                                try {
                                    const retryResp = await fetch(candidateUrl, {
                                        method: 'GET',
                                        headers: {
                                            'Authorization': `Bearer ${accessToken}`,
                                            'Content-Type': 'application/json'
                                        }
                                    });
                                    if (retryResp.ok) {
                                        console.log(`[PROXY] Recovery SUCCESS with: ${candidateUrl}`);
                                        const data = await retryResp.json();
                                        return res.status(200).json(data);
                                    }
                                } catch (e) {
                                    console.log(`[PROXY] Candidate failed: ${e.message}`);
                                }
                            }
                            console.warn('[PROXY] All recovery candidates failed.');
                        }
                    }

                    // Return 200 with error info so client can handle it gracefully instead of crashing
                    return res.status(200).json({
                        done: true,
                        error: {
                            message: `Polling HTTP Error ${response.status}: ${errorText}`,
                            code: response.status
                        }
                    });
                }

                const operationData = await response.json();

                // Mimic the SDK response structure [operation, null, rawResponse] for compatibility if needed, 
                // but the client just expects the operation object.
                // The client (Flutter) expects { done: boolean, response: ... }

                if (operationData.done) {
                    // Normalize the response for the client
                    // Vertex AI LROs usually have 'response' or 'error' field when done.
                    return res.status(200).json(operationData);
                } else {
                    return res.status(200).json(operationData);
                }
            } catch (error) {
                console.error('[PROXY] Polling Error:', error);
                res.status(500).json({ error: error.message });
                return;
            }
        }

        // --- VALIDATION FOR GENERATION REQUESTS ---
        if (!prompt && !req.body.instances) {
            throw { status: 400, message: 'Bad Request: Missing "prompt" or "instances" in body.' };
        }

        const modelId = model || 'gemini-2.0-flash';

        // --- PATH B: EMBEDDINGS (New) ---
        if (modelId.toLowerCase().includes('embedding') || req.body.instances) {
            const { GoogleAuth } = require('google-auth-library');
            const auth = new GoogleAuth({
                scopes: 'https://www.googleapis.com/auth/cloud-platform'
            });
            const client = await auth.getClient();
            const accessToken = await client.getAccessToken();
            const projectId = await auth.getProjectId();

            const endpoint = `https://us-central1-aiplatform.googleapis.com/v1/projects/${projectId}/locations/us-central1/publishers/google/models/${modelId}:predict`;

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    instances: req.body.instances || [{ content: prompt }]
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw { status: response.status, message: `Vertex Embedding Error: ${errText}` };
            }

            const data = await response.json();
            res.json(data);
            return;
        }

        // --- PATH C: IMAGE GENERATION (Imagen) ---
        if (modelId.toLowerCase().includes('imagen')) {
            const { GoogleAuth } = require('google-auth-library');
            const auth = new GoogleAuth({
                scopes: 'https://www.googleapis.com/auth/cloud-platform'
            });
            const client = await auth.getClient();
            const accessToken = await client.getAccessToken();
            const projectId = await auth.getProjectId();

            const endpoint = `https://us-central1-aiplatform.googleapis.com/v1/projects/${projectId}/locations/us-central1/publishers/google/models/${modelId}:predict`;

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    instances: [{ prompt: prompt }],
                    parameters: config || { sampleCount: 1, aspectRatio: "1:1" }
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw { status: response.status, message: `Vertex Imagen Error: ${errText}` };
            }

            const data = await response.json();
            // Wrap in a structure the client can easily detect as 'imagen'
            res.json({
                custom_type: 'imagen',
                predictions: data.predictions
            });
            return;
        }

        // --- PATH D: VIDEO GENERATION (Veo) ---
        if (modelId.toLowerCase().includes('veo')) {
            const { GoogleAuth } = require('google-auth-library');
            const auth = new GoogleAuth({
                scopes: 'https://www.googleapis.com/auth/cloud-platform'
            });
            const client = await auth.getClient();
            const accessToken = await client.getAccessToken();
            const projectId = await auth.getProjectId();

            const endpoint = `https://us-central1-aiplatform.googleapis.com/v1beta1/projects/${projectId}/locations/us-central1/publishers/google/models/${modelId}:predictLongRunning`;

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    instances: [{ prompt: prompt }],
                    parameters: config || { sampleCount: 1, aspectRatio: "16:9", durationSeconds: 5 }
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw { status: response.status, message: `Vertex Veo Error: ${errText}` };
            }

            const data = await response.json();
            // Check if it's an LRO (Long Running Operation)
            if (data.name && data.name.includes('/operations/')) {
                res.json({
                    custom_type: 'veo_lro',
                    operationName: data.name
                });
            } else if (data.predictions && data.predictions.length > 0) {
                // Immediate result (unlikely for video but possible)
                res.json({
                    custom_type: 'veo_result',
                    predictions: data.predictions
                });
            } else {
                throw { status: 500, message: 'Veo response unrecognized.' };
            }
            return;
        }

        // --- PATH C: TEXT GENERATION (Gemini) ---
        const generativeModel = vertexAI.getGenerativeModel({
            model: modelId,
            systemInstruction: systemInstruction, // Optional system prompt
            generationConfig: config // Pass through temperature, maxTokens, etc.
        });

        // Handle multimodal input 
        let requestContent;
        if (typeof prompt === 'string') {
            requestContent = prompt;
        } else {
            requestContent = prompt; // Array of parts
        }

        const result = await generativeModel.generateContent(requestContent);
        const response = await result.response;
        const candidates = response.candidates;

        if (!candidates || candidates.length === 0) {
            res.json({ candidates: [] });
            return;
        }

        res.json(response);



    } catch (error) {
        console.error('Vertex AI Proxy Error:', error);
        const status = error.status || 500;
        const message = error.message || 'Internal Server Error';
        res.status(status).json({ error: message });
    }
});

// Expose CopilotKit Runtime
exports.copilotRuntime = functions.https.onRequest(copilotHandler);

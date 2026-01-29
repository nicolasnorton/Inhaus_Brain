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

                let targetUrl = `https://us-central1-aiplatform.googleapis.com/v1beta1/${operationName}`;

                // [PERMANENT FIX] Handle Veo and other models that return UUIDs as Operation IDs.
                // The standard 'v1' operations endpoint often requires a 'Long' (numeric) ID.
                // To support UUIDs, we must:
                // 1. Use the 'v1beta1' endpoint.
                // 2. Use the location-specific regional host (e.g., us-central1-aiplatform).
                // 3. Keep the original model-specific path if it exists, as it's often more UUID-friendly.

                try {
                    // Extract location from operationName if present (format: projects/.../locations/{location}/...)
                    const locationMatch = operationName.match(/locations\/([^/]+)/);
                    const lId = locationMatch ? locationMatch[1] : 'us-central1';

                    // Construct targeted URL using regional host and v1beta1
                    targetUrl = `https://${lId}-aiplatform.googleapis.com/v1beta1/${operationName}`;

                    console.log(`[PROXY] Targeted Polling Path: ${targetUrl}`);

                    // If it's the publisher-specific path (Veo), we definitely want to keep it as is.
                    // If it was already a canonical path, it also works on this URL structure.
                } catch (rewriteErr) {
                    console.error('[PROXY] URL Construction Error:', rewriteErr);
                }

                // Retry logic for polling requests (transient network errors)
                const fetchWithRetry = async (url, options, retries = 3) => {
                    for (let i = 0; i < retries; i++) {
                        try {
                            const response = await fetch(url, options);
                            if (response.status === 404 && i < retries - 1) {
                                console.log(`[PROXY] 404 encountered, retrying (${i + 1}/${retries})...`);
                                await new Promise(r => setTimeout(r, 1000));
                                continue;
                            }
                            return response;
                        } catch (err) {
                            if (i === retries - 1) throw err;
                            await new Promise(r => setTimeout(r, 1000));
                        }
                    }
                };

                const response = await fetchWithRetry(targetUrl, {
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${accessToken}`,
                        'Content-Type': 'application/json'
                    }
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    console.error(`[PROXY] Polling failed: ${response.status} ${errorText}`);

                    // [RECOVERY] If we got a 400 (Invalid Argument - probably the Long vs UUID error)
                    // or a 404, let's try a canonical rewrite as a last-resort attempt.
                    if (response.status === 400 && operationName.includes('/publishers/')) {
                        console.log('[PROXY] 400 Detected on publisher path. Attempting canonical path repair...');
                        const match = operationName.match(/projects\/([^/]+)\/locations\/([^/]+)\/(?:.*)\/operations\/([^/]+)/);
                        if (match) {
                            const [, , lId, opId] = match;
                            const repairUrl = `https://${lId}-aiplatform.googleapis.com/v1beta1/projects/${match[1]}/locations/${lId}/operations/${opId}`;
                            console.log(`[PROXY] Retrying with repaired URL: ${repairUrl}`);
                            const retryResp = await fetch(repairUrl, {
                                method: 'GET',
                                headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' }
                            });
                            if (retryResp.ok) {
                                const data = await retryResp.json();
                                return res.status(200).json(data);
                            }
                            console.warn('[PROXY] Repair attempt also failed.');
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

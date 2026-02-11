const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { VertexAI } = require("@google-cloud/vertexai");
// Import the Copilot handler
const { copilotHandler } = require('./copilot');

admin.initializeApp();

// Initialize Vertex AI
const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
const location = 'us-central1';
const vertexAI = new VertexAI({ project: project, location: location });

/**
 * Helper function to convert GCS URIs (gs://bucket/path) to signed HTTPS URLs
 * that browsers can play without authentication issues.
 * 
 * This recursively searches through the operation response for GCS URIs and converts them.
 */
async function convertGcsUrisToSignedUrls(obj) {
    if (!obj || typeof obj !== 'object') {
        return obj;
    }

    // Handle arrays
    if (Array.isArray(obj)) {
        return Promise.all(obj.map(item => convertGcsUrisToSignedUrls(item)));
    }

    // Handle objects
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'string' && value.startsWith('gs://')) {
            // Convert GCS URI to signed URL
            try {
                console.log(`[PROXY] 🔗 Converting GCS URI to signed URL: ${value}`);
                const bucket = admin.storage().bucket();
                const filePath = value.replace(/^gs:\/\/[^\/]+\//, ''); // Remove gs://bucket-name/
                const bucketName = value.match(/^gs:\/\/([^\/]+)\//)?.[1];

                if (!bucketName) {
                    console.error(`[PROXY] ❌ Invalid GCS URI format: ${value}`);
                    result[key] = value;
                    continue;
                }

                // Get the correct bucket
                const actualBucket = admin.storage().bucket(bucketName);
                const file = actualBucket.file(filePath);

                // Generate signed URL valid for 1 hour
                const [signedUrl] = await file.getSignedUrl({
                    action: 'read',
                    expires: Date.now() + 60 * 60 * 1000, // 1 hour from now
                });

                console.log(`[PROXY] ✅ Generated signed URL: ${signedUrl.substring(0, 100)}...`);
                result[key] = signedUrl;
            } catch (error) {
                console.error(`[PROXY] ⚠️ Failed to generate signed URL for ${value}:`, error);
                // Fall back to converting gs:// to https://storage.googleapis.com/ format
                result[key] = value.replace('gs://', 'https://storage.googleapis.com/');
            }
        } else if (typeof value === 'object') {
            // Recursively process nested objects/arrays
            result[key] = await convertGcsUrisToSignedUrls(value);
        } else {
            result[key] = value;
        }
    }
    return result;
}


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
            model: 'gemini-2.5-pro',
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
const cors = require('cors')({ origin: true });

exports.proxyVertexAI = functions.https.onRequest((req, res) => {
    return cors(req, res, async () => {
        // Main logic continues here...


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
            const { model, prompt, config, systemInstruction, operationName, generationParams } = req.body;

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
                        // UUID operations from Veo/Model Garden - MUST use :fetchPredictOperation endpoint
                        // Model Garden operations have full path: projects/X/locations/Y/publishers/google/models/MODEL/operations/UUID
                        // These CANNOT be polled via standard REST GET - must use :fetchPredictOperation POST
                        const pollStartTime = Date.now();
                        console.log('[PROXY] 🎬 UUID operation detected - Model Garden operation');
                        console.log(`[PROXY] 📋 Full operation name (preserved): ${operationName}`);
                        console.log(`[PROXY] 🔍 Operation ID (UUID): ${opId}`);
                        console.log(`[PROXY] 📊 [TELEMETRY] veo_poll_start: operation=${operationName.substring(0, 80)}, timestamp=${new Date().toISOString()}`);

                        // Validate operation name format
                        if (!operationName.includes('/operations/')) {
                            console.error('[PROXY] ❌ Invalid operation name format - missing /operations/ segment');
                            return res.status(200).json({
                                done: true,
                                error: {
                                    message: 'Invalid operation name format',
                                    code: 400
                                }
                            });
                        }

                        // Extract model name from operation path
                        const modelMatch = operationName.match(/\/models\/([^\/]+)/);
                        const modelName = modelMatch ? modelMatch[1] : 'veo-3.0-fast-generate-preview';

                        // Construct :fetchPredictOperation endpoint
                        const fetchEndpoint = `https://${lId}-aiplatform.googleapis.com/v1/projects/${pId}/locations/${lId}/publishers/google/models/${modelName}:fetchPredictOperation`;

                        console.log(`[PROXY] 🎯 Model: ${modelName}`);
                        console.log(`[PROXY] 🔄 Polling method: fetchPredictOperation (POST)`);
                        console.log(`[PROXY] 🌐 Endpoint: ${fetchEndpoint}`);

                        const requestBody = {
                            operationName: operationName  // Send FULL operation name string
                        };
                        console.log(`[PROXY] 📤 Request body: ${JSON.stringify(requestBody)}`);

                        const response = await fetch(fetchEndpoint, {
                            method: 'POST',
                            headers: {
                                'Authorization': `Bearer ${accessToken}`,
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify(requestBody)
                        });

                        console.log(`[PROXY] 📡 Response status: ${response.status}`);

                        if (!response.ok) {
                            const errorBody = await response.text();
                            const pollDuration = Date.now() - pollStartTime;
                            console.error(`[PROXY] ❌ fetchPredictOperation error: ${response.status} ${response.statusText}`);
                            console.error(`[PROXY] 📄 Error body: ${errorBody}`);
                            console.error(`[PROXY] 📊 [TELEMETRY] veo_poll_error: status=${response.status}, duration=${pollDuration}ms, operation=${opId}`);
                            return res.status(200).json({
                                done: true,
                                error: {
                                    message: `fetchPredictOperation Error: ${response.statusText}`,
                                    code: response.status,
                                    details: errorBody
                                }
                            });
                        }

                        let operation = await response.json();
                        const pollDuration = Date.now() - pollStartTime;
                        console.log('[PROXY] ✅ fetchPredictOperation successful');
                        console.log(`[PROXY] ⏱️ Poll duration: ${pollDuration}ms`);
                        console.log(`[PROXY] 📋 Operation status: done=${operation.done || false}`);
                        console.log(`[PROXY] 🔍 Full operation response: ${JSON.stringify(operation, null, 2)}`);
                        console.log(`[PROXY] 📊 [TELEMETRY] veo_poll_success: duration=${pollDuration}ms, done=${operation.done || false}, operation=${opId}`);

                        // CRITICAL FIX: Convert GCS URIs to signed URLs for browser playback
                        if (operation.done && !operation.error) {
                            operation = await convertGcsUrisToSignedUrls(operation);
                        }

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

                    // CRITICAL FIX: Convert GCS URIs to signed URLs for browser playback
                    let finalOperationData = operationData;
                    if (operationData.done && !operationData.error) {
                        finalOperationData = await convertGcsUrisToSignedUrls(operationData);
                    }

                    if (finalOperationData.done) {
                        // Normalize the response for the client
                        // Vertex AI LROs usually have 'response' or 'error' field when done.
                        return res.status(200).json(finalOperationData);
                    } else {
                        return res.status(200).json(finalOperationData);
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

            const modelId = model || 'gemini-2.5-flash';

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
                        parameters: generationParams || config || { sampleCount: 1, aspectRatio: "1:1" }
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
                        parameters: generationParams || config || { sampleCount: 1, aspectRatio: "16:9", durationSeconds: 5 }
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
            console.log(`VertexAI Proxy: Calling Gemini model: ${modelId} for prompt length: ${typeof prompt === 'string' ? prompt.length : 'multimodal'}`);

            const regions = ['us-central1', 'us-east4', 'us-west1'];

            // AGGRESSIVE SANITIZATION: Replace legacy aliases with stable versioned IDs
            // We also add fallbacks to handle regional availability and model retirements
            let modelVariations = [modelId];

            if (modelId.includes('gemini-1.5-flash') || modelId.includes('gemini-2.5-flash') || modelId.includes('gemini-2.0-flash')) {
                // Try stable 2.5 Flash variants
                modelVariations = ['gemini-2.5-flash', 'gemini-2.5-flash-lite', 'gemini-3-flash-preview'];
            } else if (modelId.includes('gemini-1.5-pro') || modelId.includes('gemini-2.5-pro') || modelId.includes('gemini-2.0-pro')) {
                modelVariations = ['gemini-2.5-pro', 'gemini-3-pro-preview'];
            }

            console.log(`[PROXY] 🛡️ Model strategy: ${JSON.stringify(modelVariations)}`);

            let lastResError = null;
            let success = false;
            let finalResponse = null;

            for (const reg of regions) {
                for (const mVar of modelVariations) {
                    try {
                        console.log(`[PROXY] 🌐 Attempting Gemini ${mVar} in ${reg}...`);
                        const vAI = new VertexAI({ project: project, location: reg });
                        const genModel = vAI.getGenerativeModel({
                            model: mVar,
                            systemInstruction: systemInstruction,
                            generationConfig: { ...config, ...generationParams }
                        });

                        const result = await genModel.generateContent(prompt);
                        finalResponse = await result.response;
                        console.log(`[PROXY] ✅ Success with ${mVar} in ${reg}`);
                        success = true;
                        break;
                    } catch (err) {
                        console.warn(`[PROXY] ⚠️ Failed ${mVar} in ${reg}: ${err.message}`);
                        lastResError = err;
                    }
                }
                if (success) break;
            }

            if (!success) {
                console.error('[PROXY] ❌ ALL ATTEMPTS FAILED. Last error:', lastResError);
                throw lastResError || new Error('All regions and model variations failed.');
            }

            const candidates = finalResponse.candidates;
            if (!candidates || candidates.length === 0) {
                console.warn('[PROXY] ⚠️ Response has NO candidates. Likely safety filter.');
                // Return a clear error instead of 200 OK with empty list
                throw { status: 500, message: 'Gemini returned no candidates. This usually happens due to safety filters or model errors.' };
            }

            res.json(finalResponse);



        } catch (error) {
            console.error('Vertex AI Proxy Error:', error);
            const status = error.status || 500;
            const message = error.message || 'Internal Server Error';
            res.status(status).json({ error: message });
        }
    });
});

// Expose CopilotKit Runtime (Legacy - to be deprecated)
exports.copilotRuntime = functions.https.onRequest(copilotHandler);

// Expose Vertex AI Chat (Direct LangChain - Recommended)
const { vertexChatHandler } = require('./vertex-chat');
exports.vertexChat = functions.https.onRequest(vertexChatHandler);

/**
 * GHL WEBHOOK RECEIVER
 * Listens for events from GoHighLevel (Contact Created, Opportunity Update, etc.)
 * and syncs them to Firestore 'sales_leads' collection.
 */

exports.ghlWebhook = functions.https.onRequest(async (req, res) => {
    // 1. Validate Method
    if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
    }

    // 2. Extract Data
    const event = req.body;
    console.log(`[GHL Webhook] Received event: ${JSON.stringify(event)}`);

    try {
        const type = event.type; // e.g., 'ContactCreated', 'OpportunityStatusUpdate'
        // Note: GHL payload structure varies. Contact data is usually at root or in 'contact' object.
        // We'll map common fields to our SalesLead model.

        const leadId = event.id || event.contact_id;
        if (!leadId) {
            console.warn('[GHL Webhook] No ID found in payload. Ignoring.');
            return res.status(200).send('Ignored: No ID');
        }

        const leadData = {
            ghlId: leadId,
            name: event.name || `${event.first_name || ''} ${event.last_name || ''}`.trim(),
            email: event.email,
            phone: event.phone,
            company: event.company_name || event.company,
            status: _mapGhlStatus(event.status || 'new'), // Helper to map GHL status to LeadStatus
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            source: 'ghl_webhook',
            rawGhlData: event // Store raw data for debugging/completeness
        };

        // 3. Update Firestore
        // Use set(..., {merge: true}) to create or update
        await admin.firestore().collection('sales_leads').doc(leadId).set(leadData, { merge: true });

        console.log(`[GHL Webhook] Synced lead ${leadId} to Firestore.`);
        return res.status(200).send('Synced');

    } catch (error) {
        console.error('[GHL Webhook] Error processing event:', error);
        return res.status(500).send('Internal Server Error');
    }
});

/**
 * EXPORT NEW ANALYTICS FUNCTION
 */
const { exportEventsToBigQuery } = require('./analytics');
exports.exportEventsToBigQuery = exportEventsToBigQuery;


function _mapGhlStatus(ghlStatus) {
    const status = ghlStatus.toLowerCase();
    if (status.includes('won')) return 'closedWon';
    if (status.includes('lost') || status.includes('abandoned')) return 'closedLost';
    if (status.includes('negotiation')) return 'negotiation';
    if (status.includes('proposal') || status.includes('sent')) return 'proposalSent';
    if (status.includes('qualified')) return 'qualified';
    if (status.includes('contacted')) return 'contacted';
    return 'newLead';
}

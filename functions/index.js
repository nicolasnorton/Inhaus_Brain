const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { VertexAI } = require("@google-cloud/vertexai");

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

        // 2. Vertex AI Execution
        const { model, prompt, config, systemInstruction } = req.body;

        if (!prompt) {
            throw { status: 400, message: 'Bad Request: Missing "prompt" in body.' };
        }

        // Default to 'gemini-1.5-flash-001' if not specified
        const modelId = model || 'gemini-1.5-flash-001';

        // --- PATH A: IMAGE GENERATION (Imagen) ---
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

        // --- PATH B: TEXT GENERATION (Gemini) ---
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

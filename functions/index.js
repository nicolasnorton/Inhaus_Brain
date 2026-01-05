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

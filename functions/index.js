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

// Callable function for manual research trigger
exports.generateResearch = functions.https.onCall(async (data, context) => {
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { campaignId, prompt } = data;
    
    try {
        const generativeModel = vertexAI.getGenerativeModel({
            model: 'gemini-1.5-pro-preview-0409',
        });

        const request = {
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
        };

        const result = await generativeModel.generateContent(request);
        const response = result.response;
        const textArea = response.candidates[0].content.parts[0].text;

        return { result: textArea };
    } catch (error) {
        console.error('Vertex AI Error:', error);
        throw new functions.https.HttpsError('internal', 'Internal AI Error');
    }
});

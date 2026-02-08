const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const admin = require("firebase-admin");
const strategyTask = require('./campaign_strategy'); // Import the next step

// Initialize Vertex AI
const { VertexAI } = require("@google-cloud/vertexai");

const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
const location = 'us-central1';

/**
 * Task Handler: Perform Research on a new Campaign
 * This replaces the inline logic in onCampaignCreated.
 */
exports.performResearchTask = onTaskDispatched(
    {
        retryConfig: {
            maxAttempts: 3,
            minBackoffSeconds: 60,
        },
        rateLimits: {
            maxConcurrentDispatches: 10,
        },
        region: location,
    },
    async (req) => {
        const { campaignId } = req.data;
        console.log(`[TaskWorker] 🔬 Starting research for campaign: ${campaignId}`);

        try {
            // 1. Fetch Campaign Data
            const campaignRef = admin.firestore().collection('campaigns').doc(campaignId);
            const campaignSnap = await campaignRef.get();

            if (!campaignSnap.exists) {
                console.warn(`[TaskWorker] Campaign ${campaignId} not found, aborting task.`);
                return; // Don't retry if data is missing
            }

            const campaignData = campaignSnap.data();

            // 0. Cancellation Check
            if (campaignData.status === 'cancelled') {
                console.log(`[TaskWorker] 🛑 Campaign ${campaignId} was cancelled. Aborting research task.`);
                return;
            }

            // 2. Perform Research (Simulated for now, replace with actual AI call)
            // Simulating AI work
            await new Promise(resolve => setTimeout(resolve, 2000));

            const vertexAI = new VertexAI({ project: project, location: location });
            const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

            const prompt = `Analyze the following campaign brief and suggest 3 key research angles:\n\n${JSON.stringify(campaignData)}`;
            const result = await model.generateContent(prompt);
            const insights = result.response.candidates[0].content.parts[0].text;

            console.log(`[TaskWorker] 🧠 Research complete for ${campaignId}`);

            // 3. Update Firestore with results
            await campaignRef.update({
                researchStatus: 'completed',
                researchInsights: insights,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 4. Chain next task: Strategy
            console.log(`[TaskWorker] 🔗 Chaining next task: Strategy`);
            await strategyTask.enqueueStrategy(campaignId);

        } catch (error) {
            console.error(`[TaskWorker] ❌ Error processing research for ${campaignId}:`, error);
            // Throw error to trigger retry (up to maxAttempts)
            throw error;
        }
    }
);

/**
 * Helper to queue this task
 */
exports.enqueueResearch = async (campaignId) => {
    const queue = getFunctions().taskQueue("performResearchTask");

    try {
        await queue.enqueue(
            { campaignId: campaignId },
            {
                dispatchDeadlineSeconds: 60 * 5 // 5 minutes validity
            }
        );
        console.log(`[TaskEnqueuer] 📨 Enqueued research task for ${campaignId}`);
    } catch (error) {
        console.error(`[TaskEnqueuer] ❌ Failed to enqueue task for ${campaignId}:`, error);
        throw error;
    }
};

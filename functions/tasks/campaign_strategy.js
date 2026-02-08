const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const admin = require("firebase-admin");

// Initialize Vertex AI
const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
const location = 'us-central1';

/**
 * Task Handler: Perform Strategy on a Campaign
 * This is the second step in the chain, triggered after Research.
 */
exports.performStrategyTask = onTaskDispatched(
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
        console.log(`[TaskWorker] ♟️ Starting strategy for campaign: ${campaignId}`);

        try {
            // 1. Fetch Campaign Data
            const campaignRef = admin.firestore().collection('campaigns').doc(campaignId);
            const campaignSnap = await campaignRef.get();

            if (!campaignSnap.exists) {
                console.warn(`[TaskWorker] Campaign ${campaignId} not found, aborting strategy task.`);
                return;
            }

            const campaignData = campaignSnap.data();

            // 0. Cancellation Check
            if (campaignData.status === 'cancelled') {
                console.log(`[TaskWorker] 🛑 Campaign ${campaignId} was cancelled. Aborting strategy task.`);
                return;
            }

            // 2. Perform Strategy (Simulated)
            await new Promise(resolve => setTimeout(resolve, 2000));
            console.log(`[TaskWorker] ♟️ Strategy complete for ${campaignId}`);

            // 3. Update Firestore with results
            await campaignRef.update({
                strategyStatus: 'completed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 4. Chain next task? (e.g. Creative Brief)
            // const creativeTask = require('./campaign_creative');
            // await creativeTask.enqueueCreative(campaignId);

        } catch (error) {
            console.error(`[TaskWorker] ❌ Error processing strategy for ${campaignId}:`, error);
            throw error;
        }
    }
);

/**
 * Helper to queue this task
 */
exports.enqueueStrategy = async (campaignId) => {
    const queue = getFunctions().taskQueue("performStrategyTask");

    try {
        await queue.enqueue(
            { campaignId: campaignId },
            {
                dispatchDeadlineSeconds: 60 * 5
            }
        );
        console.log(`[TaskEnqueuer] 📨 Enqueued strategy task for ${campaignId}`);
    } catch (error) {
        console.error(`[TaskEnqueuer] ❌ Failed to enqueue strategy task for ${campaignId}:`, error);
        throw error;
    }
};

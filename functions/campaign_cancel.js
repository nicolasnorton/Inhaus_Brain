const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Callable Function: Cancel Campaign Generation
 * Sets the campaign status to 'cancelled', which stops the Cloud Task chain.
 */
exports.cancelCampaign = functions.https.onCall(async (data, context) => {
    // 1. Auth Check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { campaignId } = data;
    if (!campaignId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing campaignId.');
    }

    console.log(`[CancelCampaign] 🛑 User ${context.auth.uid} requesting cancellation for ${campaignId}`);

    try {
        const campaignRef = admin.firestore().collection('campaigns').doc(campaignId);
        const doc = await campaignRef.get();

        if (!doc.exists) {
            throw new functions.https.HttpsError('not-found', 'Campaign not found.');
        }

        const campaignData = doc.data();
        const requestUid = context.auth.uid;

        // 1.1 Permission Check (Owner or Agency Staff)
        // Assuming campaign has a 'createdBy' field. Frontend sets this on creation? 
        // We should check the field or allowed roles.
        // For safe measure, let's allow if createdBy matches OR if user claims has role.

        // Note: The frontend proposal_generator_screen.dart does NOT currently set 'createdBy',
        // but 'onCampaignCreated' trigger implies we might want to capture it.
        // CHECK: The frontend sets: 'proposalId', 'createdAt', 'status'. 
        // It does NOT set 'createdBy'.
        // We should blindly trust Agency Staff roles for now as per firestore rules.

        // Check for Agency Role (custom claims)
        const token = context.auth.token;
        const isAgency = token.role === 'superAdmin' || token.role === 'admin' || token.role === 'humanAgencyStaff';

        // Ideally we also allow the creator, but we need to create the field first.
        // Since firestore rules restrict creation to Agency Staff, we can assume anyone 
        // who *could* create it *is* Agency Staff.
        // So checking for Agency Role is sufficient and robust.

        if (!isAgency) {
            console.warn(`[CancelCampaign] 🛑 User ${requestUid} (Role: ${token.role}) denied cancellation.`);
            throw new functions.https.HttpsError('permission-denied', 'Only Agency Staff can cancel campaigns.');
        }

        // This flag is checked by the Task Workers (Research, Strategy, etc.)
        await campaignRef.update({
            status: 'cancelled',
            statusMessage: 'Cancelled by user.',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`[CancelCampaign] ✅ Campaign ${campaignId} marked as cancelled.`);
        return { success: true, message: 'Campaign cancellation requested.' };

    } catch (error) {
        console.error('[CancelCampaign] ❌ Error:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

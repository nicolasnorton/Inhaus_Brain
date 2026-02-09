const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { BigQuery } = require("@google-cloud/bigquery");

const bigquery = new BigQuery();
const DATASET_ID = "inhaus_brain_analytics";
const TABLE_ID = "event_log";

/**
 * Trigger: On Create of a new event document in `users/{userId}/events/{eventId}`.
 * Action: Inserts the event into BigQuery `inhaus_brain_analytics.event_log`.
 */
exports.exportEventsToBigQuery = functions.firestore
    .document("users/{userId}/events/{eventId}")
    .onCreate(async (snapshot, context) => {
        const eventId = context.params.eventId;
        const userId = context.params.userId;
        const data = snapshot.data();

        if (!data) {
            console.warn(`[Analytics] Event ${eventId} has no data.`);
            return null;
        }

        // Prepare BigQuery Row
        // Ensure schema matches `bigquery_schema_proposal.sql`
        const row = {
            event_id: eventId,
            timestamp: BigQuery.timestamp(data.timestamp ? data.timestamp.toDate() : new Date()),
            agent_id: data.agentId || null,
            session_id: data.sessionId || null,
            workflow_id: data.workflowId || null,
            event_type: data.type || "unknown",
            payload: JSON.stringify(data.payload || {}), // Store payload as JSON string
            severity: data.severity || "INFO",
            // Add userId metadata not in the main schema? 
            // The schema did not explicitly have user_id but maybe it should?
            // Wait, the schema proposal had: agent_id, session_id, workflow_id.
            // Let's stick to the schema.
            // Maybe we add client_id if available in payload?
        };

        try {
            await bigquery
                .dataset(DATASET_ID)
                .table(TABLE_ID)
                .insert([row]);

            console.log(`[Analytics] ✅ Exported event ${eventId} (${row.event_type}) to BigQuery.`);
        } catch (error) {
            console.error(`[Analytics] ❌ Failed to export event ${eventId}:`, error);

            if (error.name === 'PartialFailureError') {
                error.errors.forEach(err => {
                    console.error(`[Analytics] Row error:`, err);
                });
            }
            // We do NOT retry indefinitely to avoid spamming logs/costs if schema mismatch
            // Firestore triggers retry on error by default if not caught properly, 
            // but here we catch and log, effectively swallowing the error to stop retry loop 
            // for non-transient errors (like schema mismatch).
        }
    });

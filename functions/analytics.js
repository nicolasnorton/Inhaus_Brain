/**
 * Inhaus Brain v1.3 - Data Pipeline Export
 * Exports events from Firestore to BigQuery
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { BigQuery } = require("@google-cloud/bigquery");

const bigquery = new BigQuery();
const datasetId = "inhaus_brain_analytics";
const tableId = "event_log_v2";

/**
 * Triggers when a new document is added to {users}/{userId}/events/{eventId}
 * Streams the event data to BigQuery for analysis.
 */
exports.exportEventsToBigQuery = onDocumentCreated("users/{userId}/events/{eventId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }

    const data = snapshot.data();
    const userId = event.params.userId;
    const eventId = event.params.eventId;

    const row = {
        event_id: eventId,
        user_id: userId,
        event_name: data.name,
        timestamp: data.timestamp ? data.timestamp.toDate().toISOString() : new Date().toISOString(),
        platform: data.platform || 'unknown',
        parameters: JSON.stringify(data.parameters || {}), // Store params as JSON string for flexibility

        // Extract key metrics for top-level query speed if present
        model_id: data.parameters?.model_id || null,
        latency_ms: data.parameters?.latency_ms || null,
        is_cache_hit: data.parameters?.is_cache_hit || false,
        input_tokens: data.parameters?.input_tokens || 0,
        output_tokens: data.parameters?.output_tokens || 0,
    };

    try {
        await bigquery
            .dataset(datasetId)
            .table(tableId)
            .insert([row]);

        console.log(`Exported event ${eventId} to BigQuery`);
    } catch (error) {
        if (error.name === 'PartialFailureError') {
            // Handle partial errors (common with streaming inserts)
            error.errors.forEach(err => {
                console.error(`BigQuery Partial Error: ${err.message}`, err.row);
            });
        }
        console.error("Error exporting to BigQuery:", error);
    }
});

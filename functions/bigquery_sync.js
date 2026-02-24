/**
 * Inhaus Brain — BigQuery Sync (Firestore → BigQuery)
 *
 * Firestore triggers that sync critical collections into BigQuery tables
 * inside the `inhaus_brain_warehouse` dataset.  These give Brain total recall
 * over conversations, proposals, clients, agent tasks, and more.
 *
 * Tables are auto-created (insertRows with autoCreate) on first write.
 */

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { BigQuery } = require("@google-cloud/bigquery");

const bigquery = new BigQuery();
const DATASET = "inhaus_brain_warehouse";

// ── helpers ──────────────────────────────────────────────────────

function safeString(v, fallback = "") {
    if (v === null || v === undefined) return fallback;
    if (typeof v === "string") return v;
    return JSON.stringify(v);
}

function safeTimestamp(v) {
    if (!v) return new Date().toISOString();
    if (v.toDate) return v.toDate().toISOString();          // Firestore Timestamp
    if (typeof v === "number") return new Date(v).toISOString();
    return new Date(v).toISOString();
}

async function upsertRow(tableId, row) {
    try {
        await bigquery
            .dataset(DATASET)
            .table(tableId)
            .insert([row], { raw: false, skipInvalidRows: true, ignoreUnknownValues: true });
        console.log(`BQ-Sync ✅ ${tableId}: ${row.id || row.proposal_id || row.client_id || "row"}`);
    } catch (err) {
        if (err.name === "PartialFailureError") {
            (err.errors || []).forEach((e) =>
                console.error(`BQ-Sync partial: ${e.message}`, e.row)
            );
        } else {
            console.error(`BQ-Sync ❌ ${tableId}:`, err.message || err);
        }
    }
}

// ── Proposals ────────────────────────────────────────────────────

exports.syncProposalsToBQ = onDocumentWritten("proposals/{proposalId}", async (event) => {
    const data = event.data?.after?.data();
    if (!data) return; // deleted

    await upsertRow("proposals", {
        proposal_id: event.params.proposalId,
        client_id: safeString(data.clientId),
        client_name: safeString(data.clientName),
        services: JSON.stringify(data.services || []),
        total_price: data.totalPrice || 0,
        margin: data.margin || 0,
        status: safeString(data.status, "draft"),
        created_by: safeString(data.createdBy),
        created_at: safeTimestamp(data.createdAt),
        updated_at: safeTimestamp(data.updatedAt),
    });
});

// ── Clients ──────────────────────────────────────────────────────

exports.syncClientsToBQ = onDocumentWritten("clients/{clientId}", async (event) => {
    const data = event.data?.after?.data();
    if (!data) return;

    await upsertRow("client_profiles", {
        client_id: event.params.clientId,
        name: safeString(data.name),
        industry: safeString(data.industry),
        contacts: JSON.stringify(data.contacts || []),
        active_since: safeTimestamp(data.createdAt),
        monthly_budget: data.monthlyBudget || 0,
        updated_at: safeTimestamp(data.updatedAt),
    });
});

// ── Agent Tasks ──────────────────────────────────────────────────

exports.syncAgentTasksToBQ = onDocumentWritten("agent_tasks/{taskId}", async (event) => {
    const data = event.data?.after?.data();
    if (!data) return;

    await upsertRow("agent_tasks", {
        task_id: event.params.taskId,
        agent_name: safeString(data.agentName),
        input_summary: safeString(data.input).substring(0, 2000),
        output_summary: safeString(data.result).substring(0, 2000),
        status: safeString(data.status, "pending"),
        duration_ms: data.durationMs || 0,
        created_at: safeTimestamp(data.createdAt),
    });
});

// ── Global Events (telemetry → BigQuery) ─────────────────────────
// This supplements the existing analytics.js pipeline which listens
// on users/{userId}/events.  This one listens on the top-level
// global_events collection that TelemetryService will now also write to.

exports.syncGlobalEventsToBQ = onDocumentWritten("global_events/{eventId}", async (event) => {
    const data = event.data?.after?.data();
    if (!data) return;

    await upsertRow("telemetry_events", {
        event_id: event.params.eventId,
        user_id: safeString(data.userId),
        event_name: safeString(data.name),
        parameters: JSON.stringify(data.parameters || {}),
        model_id: safeString(data.parameters?.model_id),
        strategy: safeString(data.parameters?.strategy),
        latency_ms: data.parameters?.latency_ms || 0,
        success: data.parameters?.success ?? true,
    });
});

// ── BrainWeave Sessions (Flow Space → BigQuery) ──────────────────

exports.syncBrainWeaveSessionsToBQ = onDocumentWritten("brainweave_sessions/{sessionId}", async (event) => {
    const data = event.data?.after?.data();
    if (!data) return;

    await upsertRow("brainweave_sessions", {
        session_id: event.params.sessionId,
        client_id: safeString(data.clientId),
        project_id: safeString(data.projectId),
        owner_id: safeString(data.ownerId),
        current_phase: safeString(data.currentPhase),
        session_logs: JSON.stringify(data.sessionLogs || []),
        queue_task_ids: JSON.stringify(data.queueTaskIds || []),
        created_at: safeTimestamp(data.createdAt),
        updated_at: safeTimestamp(data.updatedAt),
    });
});


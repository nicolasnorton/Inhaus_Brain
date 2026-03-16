'use strict';

/**
 * BrainWeave BigQuery Streaming Function
 * =====================================================
 * Implements the 4 Ars Contexta cloud-native hooks as Firestore triggers on
 * the `brainweave_sessions/{sessionId}` collection.
 *
 * Hooks:
 *   1. SessionStart  (onCreate)  — Initialize session metadata row in BQ.
 *   2. PostToolUse   (onUpdate)  — Validation (kernel primitives) + Schema checking.
 *   3. AutoCommit    (onUpdate)  — Commit (Storage versioning) + audit_logs write.
 *   4. Stop          (onDelete)  — Archive terminal session state to BQ.
 */

const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { BigQuery } = require('@google-cloud/bigquery');

if (!getApps().length) initializeApp();

const db = getFirestore();
const bigquery = new BigQuery();

const BQ_DATASET = 'inhaus_brain_analytics';
const BQ_TABLE = 'brainweave_sessions';

// ── 15 Kernel Primitives expected in every session document ─────────────────
const KERNEL_PRIMITIVES = [
    'clientId', 'projectId', 'ownerId', 'currentPhase',
    'sessionLogs', 'queueTaskIds', 'createdAt', 'updatedAt',
    // Extended primitives from Ars Contexta v0.8.0 schema:
    'domainContext', 'insights', 'reflections', 'reweaveTargets',
    'verifyReport', 'rethinkProposals', 'schemaVersion',
];

/**
 * Hook 1 — SessionStart
 * Fires on session document creation.
 */
exports.brainweaveSessionStart = onDocumentCreated(
    'brainweave_sessions/{sessionId}',
    async (event) => {
        const sessionId = event.params.sessionId;
        const data = event.data?.data() ?? {};

        const row = {
            session_id: sessionId,
            client_id: data.clientId ?? '',
            owner_id: data.ownerId ?? '',
            phase: data.currentPhase ?? 'brainweaveRecord',
            event_type: 'session_orient',
            log_count: (data.sessionLogs ?? []).length,
            schema_version: data.schemaVersion ?? 'v1',
            occurred_at: new Date().toISOString(),
        };

        try {
            await bigquery.dataset(BQ_DATASET).table(BQ_TABLE).insert([row]);
            console.log(`[SessionStart] Inserted BQ row for session ${sessionId}`);
        } catch (err) {
            console.error(`[SessionStart] BQ insert failed:`, err);
        }
    }
);

/**
 * Hook 2 — PostToolUse (Validation)
 * Fires on session document update.
 */
exports.brainweavePostToolUseValidate = onDocumentUpdated(
    'brainweave_sessions/{sessionId}',
    async (event) => {
        const sessionId = event.params.sessionId;
        const beforeData = event.data?.before?.data() ?? {};
        const afterData = event.data?.after?.data() ?? {};

        // Guard: If the only change was our validation write, skip to prevent infinite loop
        const beforeLogs = (beforeData.sessionLogs ?? []).length;
        const afterLogs = (afterData.sessionLogs ?? []).length;
        if (afterData._lastValidatedAt && beforeData._lastValidatedAt === afterData._lastValidatedAt) {
            return; // Already validated in a previous invocation
        }

        const missingPrimitives = KERNEL_PRIMITIVES.filter(
            (p) => !(p in afterData)
        );

        if (missingPrimitives.length > 0) {
            const warning = `[PostToolUse-Validate] Missing primitives: ${missingPrimitives.join(', ')}`;
            console.warn(warning);
            try {
                await db.collection('brainweave_sessions').doc(sessionId).update({
                    sessionLogs: FieldValue.arrayUnion(warning),
                    _lastValidatedAt: FieldValue.serverTimestamp(),
                });
            } catch (err) {
                console.error('[PostToolUse-Validate] Could not append validation warning:', err);
            }
        } else {
            console.log(`[PostToolUse-Validate] Session ${sessionId} passes all 15 kernel primitives.`);
        }
    }
);

/**
 * Hook 3 — AutoCommit
 * Fires on session document update.
 * Writes a versioned JSON snapshot to Firebase Storage and appends an
 * immutable audit_log entry for tamper-evident oversight.
 */
exports.brainweaveAutoCommit = onDocumentUpdated(
    'brainweave_sessions/{sessionId}',
    async (event) => {
        const sessionId = event.params.sessionId;
        const afterData = event.data?.after?.data() ?? {};
        const ownerId = afterData.clientId ?? 'unknown';
        const phase = afterData.currentPhase ?? 'unknown';

        // 1. Write versioned Storage snapshot
        try {
            const bucket = getStorage().bucket();
            const timestamp = Date.now();
            const path = `brainweave/${ownerId}/sessions/${sessionId}/snapshots/${phase}_${timestamp}.json`;
            const file = bucket.file(path);
            await file.save(JSON.stringify({ sessionId, phase, snapshot: afterData, snapshotAt: new Date().toISOString() }, null, 2), {
                contentType: 'application/json',
                metadata: { cacheControl: 'no-cache' },
            });
            console.log(`[AutoCommit] Snapshot written to ${path}`);
        } catch (err) {
            console.error('[AutoCommit] Storage snapshot failed:', err);
        }

        // 2. Append tamper-evident audit log
        try {
            await db.collection('audit_logs').add({
                type: 'brainweave_auto_commit',
                sessionId,
                ownerId,
                phase,
                timestamp: FieldValue.serverTimestamp(),
                details: `AutoCommit: session ${sessionId} transitioned to phase ${phase}`,
            });
            console.log(`[AutoCommit] Audit log written for session ${sessionId}`);
        } catch (err) {
            console.error('[AutoCommit] Audit log write failed:', err);
        }
    }
);

/**
 * Hook 4 — Stop
 * Fires on session document deletion.
 */
exports.brainweaveStop = onDocumentDeleted(
    'brainweave_sessions/{sessionId}',
    async (event) => {
        const sessionId = event.params.sessionId;
        const data = event.data?.data() ?? {};

        const row = {
            session_id: sessionId,
            client_id: data.clientId ?? '',
            owner_id: data.ownerId ?? '',
            phase: data.currentPhase ?? 'unknown',
            event_type: 'stop',
            log_count: (data.sessionLogs ?? []).length,
            queue_count: (data.queueTaskIds ?? []).length,
            schema_version: data.schemaVersion ?? 'v1',
            occurred_at: new Date().toISOString(),
        };

        try {
            await bigquery.dataset(BQ_DATASET).table(BQ_TABLE).insert([row]);
            console.log(`[Stop] Archived terminal session ${sessionId} to BQ`);
        } catch (err) {
            console.error(`[Stop] BQ archive failed:`, err);
        }
    }
);

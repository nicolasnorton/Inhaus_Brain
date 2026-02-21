const admin = require('firebase-admin');
const { GoogleAuth } = require('google-auth-library');
const functions = require('firebase-functions');
const cors = require('cors')({ origin: true });

// Initialize Stitch API Client (ADC)
const auth = new GoogleAuth({
    scopes: 'https://www.googleapis.com/auth/cloud-platform'
});

const STITCH_API_BASE = 'https://stitch.googleapis.com/v1';

/**
 * Helper: Get rate limit key for user
 */
function getRateLimitKey(userId) {
    const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const hour = new Date().getHours();
    return `rate_limits/stitch_gen/${userId}/${date}_${hour}`;
}

/**
 * Helper: Check and increment rate limit
 * Limit: 20 generations per hour per user
 */
async function checkRateLimit(userId) {
    const limit = 20;
    const key = getRateLimitKey(userId);
    const docRef = admin.firestore().doc(key);

    return admin.firestore().runTransaction(async (t) => {
        const doc = await t.get(docRef);
        const current = doc.exists ? doc.data().count : 0;

        if (current >= limit) {
            throw { status: 429, message: `Rate limit exceeded. Max ${limit} generations per hour.` };
        }

        t.set(docRef, { count: current + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    });
}

/**
 * Helper: Call Stitch API with ADC
 */
async function callStitchApi(endpoint, method, body = null) {
    // Priority: User-provided key (v2.0 Upgrade)
    const stitchApiKey = process.env.STITCH_API_KEY || "AQ.Ab8RN6KS-HoUsjuh06F9INNNmo7LMRLFjhZ6Dfq5tOVrEfqnPw";
    let authHeaders = {};

    if (stitchApiKey) {
        console.log('[Stitch Proxy] 🔑 Using STITCH_API_KEY.');
        authHeaders = {
            'X-Goog-Api-Key': stitchApiKey
        };
    } else {
        const client = await auth.getClient();
        const tokenResponse = await client.getAccessToken();
        const accessToken = tokenResponse.token;
        authHeaders = {
            'Authorization': `Bearer ${accessToken}`
        };
    }

    const url = `${STITCH_API_BASE}${endpoint}`;
    console.log(`[Stitch Proxy] 🌐 Calling ${method} ${url}`);

    const options = {
        method: method,
        headers: {
            ...authHeaders,
            'Content-Type': 'application/json'
        }
    };

    if (body) {
        options.body = JSON.stringify(body);
    }

    // Retries with exponential backoff
    let attempts = 0;
    const maxAttempts = 3;
    let lastError = null;

    while (attempts < maxAttempts) {
        try {
            attempts++;
            const response = await fetch(url, options);

            if (!response.ok) {
                const errorText = await response.text();
                // 429 or 500s -> Retry
                if (response.status === 429 || response.status >= 500) {
                    throw new Error(`Stitch API ${response.status}: ${errorText}`);
                }
                // Client error (400, 403, 404) -> Throw immediately
                throw { status: response.status, message: errorText };
            }

            return await response.json();
        } catch (e) {
            lastError = e;
            if (e.status && e.status < 500 && e.status !== 429) throw e; // Don't retry client errors

            console.warn(`[Stitch Proxy] ⚠️ Attempt ${attempts} failed: ${e.message}`);
            if (attempts >= maxAttempts) break;

            // Wait 1s, 2s, 4s
            await new Promise(r => setTimeout(r, Math.pow(2, attempts - 1) * 1000));
        }
    }

    throw lastError || new Error('Stitch API request failed after retries');
}

/**
 * PROXY STITCH FUNCTION
 */
exports.proxyStitch = functions.https.onRequest((req, res) => {
    return cors(req, res, async () => {
        // 1. Method Validation
        if (req.method !== 'POST' && req.method !== 'GET') {
            return res.status(405).send('Method Not Allowed');
        }

        try {
            // 2. Authentication (Firebase ID Token)
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                throw { status: 401, message: 'Unauthorized: Missing or invalid Authorization header.' };
            }
            const idToken = authHeader.split('Bearer ')[1];
            const decodedToken = await admin.auth().verifyIdToken(idToken);
            const userId = decodedToken.uid;

            // 3. Routing & Logic
            // Mapping: /path/to/resource -> forward to Stitch
            // The client sends the target endpoint relative to /v1/ in the URL or query params?
            // Let's use specific actions based on body 'action' or path convention.
            // Simplified: The client posts to this cloud function with 'action' and 'payload'.

            // Actually, RESTful is cleaner.
            // Parse req.path? Cloud Functions generic onRequest path structure:
            // If deployed as /proxyStitch, req.path might be used if using express app.
            // But this is a simple function. Let's look at req.body or query params.
            // Standardizing on POST with 'action' in body is easiest for a single function endpoint without Express.

            const defaultBody = req.body || {};
            const action = defaultBody.action || req.query.action;
            const payload = defaultBody.payload || {};

            console.log(`[Stitch Proxy] 🚀 Action: ${action}, User: ${userId}`);

            let result;

            switch (action) {
                case 'create_project':
                    // payload: { name, description }
                    result = await callStitchApi('/projects', 'POST', {
                        display_name: payload.name,
                        description: payload.description
                    });
                    break;

                case 'list_projects':
                    // payload: { pageSize, pageToken }
                    const query = new URLSearchParams(payload).toString();
                    result = await callStitchApi(`/projects?${query}`, 'GET');
                    break;

                case 'get_project':
                    // payload: { projectId }
                    result = await callStitchApi(`/projects/${payload.projectId}`, 'GET');
                    break;

                case 'generate_screen':
                    // payload: { projectId, prompt, screenId(opt) }
                    // Rate Limit Check
                    await checkRateLimit(userId);

                    result = await callStitchApi(`/projects/${payload.projectId}/screens:generate`, 'POST', {
                        prompt: payload.prompt,
                        screen_id: payload.screenId // if updating
                    });
                    break;

                case 'get_screen_code':
                    // payload: { projectId, screenId }
                    result = await callStitchApi(`/projects/${payload.projectId}/screens/${payload.screenId}/code`, 'GET');
                    break;

                case 'get_screen_image':
                    // payload: { projectId, screenId }
                    // This might return binary? Or JSON with url/base64?
                    // Assuming JSON with image_url or base64 data
                    result = await callStitchApi(`/projects/${payload.projectId}/screens/${payload.screenId}/image`, 'GET');

                    // Cache Option: Upload to Firebase Storage if it's base64
                    if (result.image_bytes) {
                        const bucket = admin.storage().bucket();
                        const filename = `stitch_cache/${payload.projectId}/${payload.screenId}_${Date.now()}.png`;
                        const file = bucket.file(filename);
                        await file.save(Buffer.from(result.image_bytes, 'base64'), {
                            metadata: { contentType: 'image/png' },
                            public: true
                        });
                        // Replace bytes with public URL
                        result.image_url = file.publicUrl();
                        delete result.image_bytes;
                    }
                    break;

                case 'extract_design_context':
                    // payload: { projectId, screenId }
                    result = await callStitchApi(`/projects/${payload.projectId}/screens/${payload.screenId}:extractDesignContext`, 'POST');
                    break;

                case 'build_site':
                    // payload: { projectId, routes }
                    result = await callStitchApi(`/projects/${payload.projectId}/sites:build`, 'POST', {
                        routes: payload.routes
                    });
                    break;

                default:
                    throw { status: 400, message: `Unknown action: ${action}` };
            }

            res.status(200).json(result);

        } catch (error) {
            console.error('[Stitch Proxy] ❌ Error:', error);
            const status = error.status || 500;
            const message = error.message || (typeof error === 'string' ? error : JSON.stringify(error));
            res.status(status).json({ error: message, details: error.stack || null });
        }
    });
});

# Testing Guide: Veo Polling Fix

**Deployment Date:** 2026-01-30  
**Branch:** `fix/veo-polling-operation-name`  
**App URL:** https://brain.inhauscorp.com/ ⭐ (Use this for OAuth)  
**Alternative URL:** https://inhausbrain.web.app (OAuth may not work)  
**Function URL:** https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI

---

## ✅ Deployment Status

### Successfully Deployed:
1. **Cloud Function** (`proxyVertexAI`)
   - Enhanced UUID operation detection
   - `fetchPredictOperation` endpoint implementation
   - Comprehensive telemetry logging

2. **Flutter Web App**
   - Extended timeout logic (600s)
   - Progressive backoff strategy
   - Enhanced user feedback messages
   - Improved error handling

---

## 🧪 Testing Instructions

### **Test 1: Video Generation Flow**

#### Step 1: Login
1. Navigate to **https://brain.inhauscorp.com/** (OAuth-enabled domain)
2. Sign in with your Google account or email/password
3. Wait for the dashboard to load

#### Step 2: Open AI Assistant
1. Click the AI Assistant button (usually in the bottom-right corner or toolbar)
2. Wait for the assistant overlay to appear

#### Step 3: Request Video Generation
Try one of these prompts:
```
Generate a video showing a sunrise over mountains
```
```
Create a short video of ocean waves
```
```
Generate a video: A busy city street at night with neon lights
```

#### Step 4: Observe Polling Behavior
Watch for these new status messages:
- ✅ Initial: "✨ Generating your high-quality video... 🕐 This typically takes 2-5 minutes ⏳ Please wait..."
- ✅ Progress: "🎥 Still generating... (1m 30s elapsed) 🎬 Video is rendering..."
- ✅ Success: "✅ Video ready! Generated in 3m 45s"

#### Step 5: Verify Video Playback
- Video should load and play automatically
- No "BigBuckBunny.mp4" fallback unless generation truly failed
- Video URL should start with `https://storage.googleapis.com/` or be a GCS URL

---

## 📊 Monitoring & Logs

### **Cloud Function Logs**

View logs with:
```bash
npx firebase-tools functions:log --only proxyVertexAI
```

**What to look for:**

✅ **Success Indicators:**
```
[PROXY] 🎬 UUID operation detected - Model Garden operation
[PROXY] 📋 Full operation name (preserved): projects/...
[PROXY] 🔄 Polling method: fetchPredictOperation (POST)
[PROXY] ✅ fetchPredictOperation successful
[PROXY] 📊 [TELEMETRY] veo_poll_success: duration=...ms, done=true
```

❌ **Error Indicators to Watch:**
```
[PROXY] ❌ fetchPredictOperation error: 400
[PROXY] 📊 [TELEMETRY] veo_poll_error: status=400
```

### **Browser Console Logs**

Open browser DevTools (F12) → Console tab

**What to look for:**

✅ **Success Indicators:**
```
VideoService: 🎬 Starting REAL Veo video poll
VideoService: 🔄 Poll 1/60 (10s elapsed, next in 10s)
VideoService: ✅ REAL video generated in 180s (3m 0s)!
📊 [TELEMETRY] video_success: duration=180000ms, polls=18, url_type=gcs
```

❌ **Errors to Watch:**
```
VideoService: ⚠️ Poll error (1/5): Polling HTTP Error 400
VideoService: 🚨 CRITICAL: INVALID_ARGUMENT still occurring!
📊 [TELEMETRY] video_invalid_argument_error: operation=...
```

### **Network Tab Inspection**

Open DevTools → Network tab → Filter by "proxyVertexAI"

Look for:
1. **Initial Generation Request**
   - Method: POST
   - URL: `https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI`
   - Response: `{ "custom_type": "veo_lro", "operationName": "projects/..." }`

2. **Polling Requests**
   - Method: POST (multiple requests every 10-20s)
   - Request Body: `{ "operationName": "projects/.../operations/UUID" }`
   - Initial responses: `{ "done": false }`
   - Final response: `{ "done": true, "response": { "predictions": [...] } }`

---

## ✅ Expected Behavior

### **Successful Flow:**
1. User requests video → "✨ Generating your high-quality video..."
2. App polls every 10-20s → "🎥 Still generating... (elapsed time)"
3. After 2-5 minutes → "✅ Video ready! Generated in Xm Ys"
4. Video plays in the UI

### **Fallback Scenarios (Only After All Retries):**

1. **After 600s timeout:**
   - Message: "Video generation timed out. Using fallback image."
   - Shows high-quality Imagen storyboard

2. **On quota/rate limit:**
   - Message: "Video generation quota exceeded. Using fallback."
   - Immediate fallback to Imagen

3. **On persistent errors (after retries):**
   - Message: "Generation failed. Using fallback."
   - Attempts edge/on-device, then Imagen, then static

---

## 🐛 Known Issues: Fixed vs. Outstanding

### ✅ **FIXED in This Release:**
- ❌ **"Operation ID must be a Long"** error → ✅ Now uses full operation name with `fetchPredictOperation`
- ❌ 400 errors during polling → ✅ Proper UUID operation handling
- ❌ Immediate fallback to BigBuckBunny → ✅ Extended timeouts + retries
- ❌ No user feedback during generation → ✅ Rich status messages with emojis
- ❌ No retry logic → ✅ Exponential backoff + fresh generation retry

### ⚠️ **Potential Edge Cases:**

1. **Very slow operations (>10 min)**
   - Expected: Timeout after 600s, use Imagen fallback
   - Mitigation: Progressive backoff allows longer waits

2. **Network interruptions**
   - Expected: Exponential backoff, up to 5 consecutive errors tolerated
   - Mitigation: Auto-recovery with backoff

3. **Operation not found (404)**
   - Expected: Retry up to 20 times (common during propagation)
   - Mitigation: 404s don't count toward error limit

---

## 📈 Success Metrics

After testing, we expect:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Zero "must be a Long" errors | 0 | Search logs for `must be a Long` |
| Video generation success rate | >80% | Count successful vs. fallback |
| Average generation time | 2-4 min | Check `[TELEMETRY] video_success` logs |
| Fallback rate (Imagen/static) | <5% | Count `video_fallback_used` logs |
| User feedback clarity | 100% | Manual testing - are messages clear? |

---

## 🔍 Debugging Tips

### If Video Generation Fails:

1. **Check Cloud Function Logs**
   ```bash
   npx firebase-tools functions:log --only proxyVertexAI --limit 50
   ```
   Look for the full polling sequence

2. **Check Browser Console**
   - Look for `VideoService:` logs
   - Check for `[TELEMETRY]` entries
   - Note any error messages

3. **Check Network Requests**
   - Verify `operationName` is passed in request body
   - Check response status codes
   - Look for full operation name (not just UUID)

4. **Common Fixes:**
   - Clear browser cache and reload
   - Sign out and sign back in
   - Check Vertex AI quota in Google Cloud Console
   - Verify Vertex AI API is enabled

---

## 🎯 Test Scenarios

### **Scenario 1: Happy Path**
- Request video → Wait 2-5 min → Video plays
- **Expected:** Success with clear status updates

### **Scenario 2: Quota Exceeded**
- Make multiple requests quickly
- **Expected:** Immediate fallback to Imagen with message

### **Scenario 3: Network Interruption**
- Start generation → Disable network briefly → Re-enable
- **Expected:** Auto-recovery with backoff

### **Scenario 4: Timeout**
- Request video → Wait 10+ minutes
- **Expected:** Timeout message, Imagen fallback

### **Scenario 5: Retry Logic**
- Simulated by backend errors
- **Expected:** Fresh generation retry after 3x 400 errors

---

## 📝 Test Report Template

```markdown
## Test Report: [Date/Time]

### Test #1: [Scenario Name]
- **Prompt:** [What you asked for]
- **Result:** ✅ Success / ❌ Failed
- **Time:** [Generation time]
- **URL:** [Video URL or fallback type]
- **Notes:** [Any observations]

### Logs:
```
[Paste relevant logs here]
```

### Screenshots:
[Attach screenshots if needed]
```

---

## 🚀 Next Steps After Testing

1. **If Tests Pass:**
   - Merge `fix/veo-polling-operation-name` to `main`
   - Update WIKI.md with polling architecture
   - Create PR with test results
   - Monitor production telemetry

2. **If Tests Fail:**
   - Document failure mode
   - Capture logs and screenshots
   - Create GitHub issue with details
   - Investigate root cause

---

## 📞 Support

If you encounter issues:
1. Check this guide's debugging section
2. Review `POLLING_FIX_SUMMARY.md` for technical details
3. Check Cloud Function and browser logs
4. Report issues with full context (logs, screenshots, test scenario)

---

**Happy Testing! 🎬✨**

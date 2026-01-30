# Veo Parsing Fix - Testing Guide

## 1. Verify Deployment Version
Open `https://inhausbrain.web.app` (or your custom domain) and check the Chrome DevTools Console.

**REQUIRED LOG**:
> `VideoService: ⚠️ FORCE RELOAD CHECK: Running v1.0.9-CACHE-BUST-FINAL`

If you do not see this log, **YOU ARE RUNNING STALE CODE**.
- Try `Cmd+Shift+R` (Hard Refresh).
- Open `Application` tab -> `Service Workers` -> **Unregister**.
- Clear Site Data if necessary.

## 2. Generate Video
Type the following prompt in the chat:
> "create video of cats in space"

## 3. Monitor Logs
Watch the console for these milestones:

### A. Polling Start
> `VideoService: 🎬 Starting REAL Veo video poll ...`
> `VideoService: ⏱️ Max duration: ~600 seconds` (If it says 180s/36 polls, it's OLD code!)

### B. Success & Parsing
When the operation completes (after ~40-80s):
> `VideoService: 🔍 Parsing completed operation response...`
> `Veo full response: {...}`

**CHECK THIS JSON**:
- Does it look like `{"done": true, "response": {"videos": [{"gcsUri": "..."}]}}`?
- Or `{"done": true, "response": {"candidates": [...]}}`?

### C. Extraction
> `VideoService: ✅ Video URL extracted: gs://...`

## 4. Troubleshooting
If you see:
> `VideoService: 🚨 [LAST RESORT FALLBACK]`

Take a screenshot of the `Veo full response:` log line (it will be printed just before fallback in v1.0.9) and share it.

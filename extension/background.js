/* 
 * InhausBrain WebMCP Background Service Worker
 * 
 * Handles connections from InhausBrain web app and exposes browser APIs
 * as MCP tools (browser_control, screen_capture, input_sim).
 */

// Initialize side panel
chrome.sidePanel
  .setPanelBehavior({ openPanelOnActionClick: true })
  .catch((error) => console.error(error));

// Firebase Identity configuration
const FIREBASE_API_KEY = "AIzaSyBMuHqc2OlaQdgVXUvQSsbpU9_DDwb3nNA";

// State getter
async function getStoredState() {
  return new Promise((resolve) => {
    chrome.storage.local.get(['inhausAuthToken', 'inhausRefreshToken', 'inhausUserEmail', 'inhausConsentGranted'], (result) => {
      resolve({
        authToken: result.inhausAuthToken || null,
        refreshToken: result.inhausRefreshToken || null,
        userEmail: result.inhausUserEmail || null,
        consentGranted: result.inhausConsentGranted || false
      });
    });
  });
}

// Listen for connection from legitimate InhausBrain frontend
chrome.runtime.onMessageExternal.addListener(
  (request, sender, sendResponse) => {
    console.log("Received external message:", request);
    
    // Actions that can be handled synchronously
    if (request.action === 'check_status_sync') {
      sendResponse({ installed: true, version: "1.0.1" });
      return false;
    }

    // Actions that require stored state
    getStoredState().then(state => {
      try {
        if (request.action === 'check_status') {
          sendResponse({ installed: true, consent: state.consentGranted, version: "1.0.1" });
        } else if (request.action === 'request_consent') {
          chrome.storage.local.set({ 'inhausConsentGranted': true }).then(() => {
            sendResponse({ success: true, consent: true });
          });
        } else if (request.action === 'execute_tool') {
          handleToolExecution(request.toolName, request.args)
            .then(result => sendResponse({ success: true, result }))
            .catch(err => sendResponse({ success: false, error: err.toString() }));
        } else {
          sendResponse({ error: "Unknown action" });
        }
      } catch (err) {
        console.error("Error in external message handler:", err);
        sendResponse({ success: false, error: err.toString() });
      }
    }).catch(err => {
      console.error("Failed to get stored state for external message:", err);
      sendResponse({ success: false, error: "Internal extension error" });
    });
    
    return true; // Keep channel open for async response
  }
);

// Listen for WebMCP Native Messaging connections
chrome.runtime.onConnectNative.addListener((port) => {
  console.log("WebMCP Native Messaging host connected");

  port.onMessage.addListener(async (msg) => {
    console.log("Received WebMCP message:", msg);
    
    // WebMCP JSON-RPC basics
    if (!msg.jsonrpc || msg.jsonrpc !== "2.0") return;

    // Handle initialization
    if (msg.method === "initialize") {
      port.postMessage({
        jsonrpc: "2.0",
        id: msg.id,
        result: {
          protocolVersion: "2024-11-05", // WebMCP standard
          capabilities: { tools: {} },
          serverInfo: { name: "InhausBrain-Extension", version: "1.0.1" }
        }
      });
      return;
    }

    // Handle tool listing
    if (msg.method === "tools/list") {
      port.postMessage({
        jsonrpc: "2.0",
        id: msg.id,
        result: {
          tools: [
            {
              name: "browser_control",
              description: "Execute basic browser actions like listing tabs or opening URLs",
              inputSchema: {
                type: "object",
                properties: { command: { type: "string" }, url: { type: "string" }, tabId: { type: "number" } },
                required: ["command"]
              }
            },
            {
              name: "record_session",
              description: "Start or stop a screen recording of the browser session",
              inputSchema: {
                type: "object",
                properties: { command: { type: "string" } },
                required: ["command"]
              }
            }
          ]
        }
      });
      return;
    }

    // Handle tool execution
    if (msg.method === "tools/call") {
      try {
        const result = await handleToolExecution(msg.params.name, msg.params.arguments);
        port.postMessage({
          jsonrpc: "2.0",
          id: msg.id,
          result: { content: [{ type: "text", text: typeof result === 'string' ? result : JSON.stringify(result) }] }
        });
      } catch (err) {
        port.postMessage({
          jsonrpc: "2.0",
          id: msg.id,
          error: { code: -32603, message: err.toString() }
        });
      }
      return;
    }
  });

  port.onDisconnect.addListener(() => {
    console.log("WebMCP Native Messaging host disconnected:", chrome.runtime.lastError?.message);
  });
});

// Listen for internal extension messages
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  const handleAsync = async () => {
    try {
      if (request.action === 'set_consent') {
        await chrome.storage.local.set({ 'inhausConsentGranted': request.consent });
        sendResponse({ success: true });
      } else if (request.action === 'get_consent') {
        const state = await getStoredState();
        sendResponse({ consent: state.consentGranted, email: state.userEmail });
      } else if (request.action === 'check_auth') {
        const state = await getStoredState();
        sendResponse({ authenticated: !!state.authToken, email: state.userEmail });
      } else if (request.action === 'logout') {
        await chrome.storage.local.remove(['inhausAuthToken', 'inhausRefreshToken', 'inhausUserEmail']);
        sendResponse({ success: true });
      } else if (request.action === 'login') {
        const result = await handleFirebaseLogin(request.email, request.password);
        sendResponse(result);
      } else if (request.action === 'login_google') {
        const result = await handleGoogleLogin();
        sendResponse(result);
      } else if (request.action === 'chat_request') {
        const text = await handleChatRequest(request.prompt);
        sendResponse({ text });
      } else {
        // Explicitly close channel for unhandled messages
        sendResponse({ error: "Unhandled internal action" });
      }
    } catch (err) {
      console.error("Internal message handling error:", err);
      sendResponse({ success: false, error: err.toString() });
    }
  };

  const knownActions = [
    'set_consent', 'get_consent', 'check_auth', 'logout', 
    'login', 'login_google', 'chat_request'
  ];

  if (knownActions.includes(request.action)) {
    handleAsync();
    return true; // Keep channel open
  }
  
  return false;
});

async function handleFirebaseLogin(email, password) {
  try {
    let response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true })
    });

    let data = await response.json();
    
    if (!response.ok) {
      // Auto-create superadmin account if it doesn't exist yet (Firebase now returns INVALID_LOGIN_CREDENTIALS for both missing email and wrong password)
      if (data.error?.message === "INVALID_LOGIN_CREDENTIALS" && 
         (email === "nnorton@inhausbrain.com" || email === "nnorton@inhauscorp.com") && 
         password === "Cafeina88$") {
        
        response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, returnSecureToken: true })
        });
        data = await response.json();
        
        if (!response.ok) {
          return { success: false, error: data.error?.message || "Superadmin Auto-Signup failed" };
        }
      } else {
        return { success: false, error: data.error?.message || "Authentication failed" };
      }
    }

    // Success
    
    // Persist
    await chrome.storage.local.set({
      'inhausAuthToken': data.idToken,
      'inhausRefreshToken': data.refreshToken,
      'inhausUserEmail': data.email
    });

    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function handleGoogleLogin() {
  return new Promise((resolve, reject) => {
    // 1. Get Google OAuth token via Chrome Identity API
    chrome.identity.getAuthToken({ interactive: true }, async function(token) {
      if (chrome.runtime.lastError || !token) {
        return resolve({ success: false, error: chrome.runtime.lastError?.message || "Google Sign-In failed" });
      }

      try {
        // 2. Exchange Google Token for Firebase Credential via REST API
        const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${FIREBASE_API_KEY}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            postBody: `id_token=${token}&providerId=google.com`,
            requestUri: "http://localhost",
            returnIdpCredential: true,
            returnSecureToken: true
          })
        });

        const data = await response.json();
        
        if (!response.ok) {
           return resolve({ success: false, error: data.error?.message || "Firebase Identity Exchange Failed" });
        }

        // Success
        await chrome.storage.local.set({
          'inhausAuthToken': data.idToken,
          'inhausRefreshToken': data.refreshToken,
          'inhausUserEmail': data.email
        });

        resolve({ success: true });
      } catch (error) {
        resolve({ success: false, error: error.message });
      }
    });
  });
}

async function getActiveTabContent() {
  try {
    const tabs = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
    if (!tabs || tabs.length === 0) return null;
    const tab = tabs[0];
    
    if (!tab.url || tab.url.startsWith('chrome://') || tab.url.startsWith('edge://') || tab.url.startsWith('about:')) {
      return null;
    }

    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id, allFrames: true },
      func: () => {
        // Build a simplified Accessibility Tree-like text representation
        function getSimplifiedDom(element) {
          if (!element) return "";
          let result = "";
          
          function traverse(node, depth) {
            if (result.length > 15000) return; // hard limit
            if (node.nodeType === Node.TEXT_NODE) {
              const text = node.textContent.trim();
              if (text && text.length > 1) {
                result += '  '.repeat(depth) + text + '\n';
              }
              return;
            }
            if (node.nodeType !== Node.ELEMENT_NODE) return;
            
            const tag = node.tagName.toLowerCase();
            if (['script', 'style', 'noscript', 'svg', 'canvas', 'video', 'audio', 'iframe'].includes(tag)) return;
            
            // Skip hidden elements
            const style = window.getComputedStyle(node);
            if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return;

            const isInteractive = ['a', 'button', 'input', 'select', 'textarea'].includes(tag) || 
                                  node.hasAttribute('onclick') || 
                                  node.getAttribute('role') === 'button';
            
            if (isInteractive) {
              let selectorAttr = "";
              if (node.id) {
                selectorAttr = `#${node.id}`;
              } else if (node.name) {
                selectorAttr = `${tag}[name='${node.name}']`;
              } else if (node.placeholder) {
                selectorAttr = `${tag}[placeholder='${node.placeholder}']`;
              } else if (tag === 'a' || tag === 'button') {
                const text = (node.innerText || node.textContent || '').trim().split('\n')[0].replace(/'/g, "\\'");
                if (text) selectorAttr = `${tag}:contains('${text}')`;
              }
              
              const fallbackLabel = node.innerText?.trim()?.split('\n')[0] || node.getAttribute('aria-label') || tag;
              const finalSelector = selectorAttr || fallbackLabel;

              // Mark actionable elements cleanly with the best selector to use
              result += '  '.repeat(depth) + `*[Actionable <${tag}>: Use Selector "${finalSelector}"]*\n`;
            } else if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'li', 'span'].includes(tag)) {
               // Let text nodes handle content, but add structure depth
            }

            for (let child of node.childNodes) {
              traverse(child, depth + (isInteractive ? 1 : 0));
            }
          }

          traverse(element, 0);
          return result;
        }

        const m = document.querySelector('main') || document.body;
        return getSimplifiedDom(m);
      }
    });
    
    if (results && results[0] && results[0].result) {
      return `\n\n[Active Page Context: ${tab.title} (${tab.url})]\n${results[0].result}\n`;
    }
  } catch (e) {
    console.error("Failed to extract page content", e);
  }
  return null;
}

async function executeBrowserAction(action, params) {
  const tabs = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tabs || tabs.length === 0) return "No active tab found.";
  const tabId = tabs[0].id;

  try {
    switch (action) {
      case 'click':
        let clickRes = await chrome.scripting.executeScript({
          target: { tabId, allFrames: true },
          func: (selector) => {
            const findEl = (s) => {
              try { const e = document.querySelector(s); if(e) return e; } catch(e) {}
              if (s.includes(':contains')) {
                const m = s.match(/(.*?):contains\(['"]?(.*?)['"]?\)/);
                if (m) return Array.from(document.querySelectorAll(m[1]||'*')).find(e => e.textContent.includes(m[2]));
              }
              if (s.startsWith('/')) {
                try { return document.evaluate(s, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; } catch(e){}
              }
              return Array.from(document.querySelectorAll('a, button, [role="button"]')).find(e => e.textContent.trim().toLowerCase() === s.toLowerCase());
            };
            const el = findEl(selector);
            if (el) { el.click(); return true; }
            return false;
          },
          args: [params.selector]
        });
        if (clickRes && clickRes.some(r => r.result === true)) return `Clicked element ${params.selector}`;
        return `Failed to find element to click: ${params.selector}`;
      
      case 'type':
        let typeRes = await chrome.scripting.executeScript({
          target: { tabId, allFrames: true },
          func: (selector, text) => {
            const findEl = (s) => {
              try { const e = document.querySelector(s); if(e) return e; } catch(e) {}
              if (s.includes(':contains')) {
                const m = s.match(/(.*?):contains\(['"]?(.*?)['"]?\)/);
                if (m) return Array.from(document.querySelectorAll(m[1]||'*')).find(e => e.textContent.includes(m[2]));
              }
              if (s.startsWith('/')) {
                try { return document.evaluate(s, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; } catch(e){}
              }
              return Array.from(document.querySelectorAll('input, textarea, select')).find(e => {
                const lbl = (e.placeholder || e.name || e.id || e.getAttribute('aria-label') || '').toLowerCase();
                return lbl === s.toLowerCase() || lbl.includes(s.toLowerCase());
              });
            };
            const el = findEl(selector);
            if (el) {
              let textToType = text;
              const pressEnter = text.endsWith('[Enter]');
              if (pressEnter) textToType = textToType.replace('[Enter]', '');

              if (el.tagName.toLowerCase() === 'select') {
                const opt = Array.from(el.options).find(o => o.text.trim().toLowerCase() === textToType.toLowerCase() || o.value.toLowerCase() === textToType.toLowerCase());
                if (opt) el.value = opt.value;
              } else {
                el.value = textToType;
              }
              
              el.dispatchEvent(new Event('input', { bubbles: true }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
              
              if (pressEnter) {
                el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true }));
                el.dispatchEvent(new KeyboardEvent('keypress', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true }));
                el.dispatchEvent(new KeyboardEvent('keyup',   { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true }));
                // Try to find a wrapping form and submit as fallback
                const form = el.closest('form');
                if (form) form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
              }
              return true;
            }
            return false;
          },
          args: [params.selector, params.text]
        });
        if (typeRes && typeRes.some(r => r.result === true)) return `Typed '${params.text}' into ${params.selector}`;
        return `Failed to find element to type in: ${params.selector}`;
        
      case 'hover':
        let hoverRes = await chrome.scripting.executeScript({
          target: { tabId, allFrames: true },
          func: (selector) => {
            const findEl = (s) => {
              try { const e = document.querySelector(s); if(e) return e; } catch(e) {}
              if (s.includes(':contains')) {
                const m = s.match(/(.*?):contains\(['"]?(.*?)['"]?\)/);
                if (m) return Array.from(document.querySelectorAll(m[1]||'*')).find(e => e.textContent.includes(m[2]));
              }
              if (s.startsWith('/')) {
                try { return document.evaluate(s, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; } catch(e){}
              }
              return Array.from(document.querySelectorAll('a, button, [role="button"], li, div')).find(e => e.textContent.trim().toLowerCase() === s.toLowerCase());
            };
            const el = findEl(selector);
            if (el) { 
              el.dispatchEvent(new MouseEvent('mouseover', {bubbles: true, cancelable: true, view: window}));
              el.dispatchEvent(new MouseEvent('mouseenter', {bubbles: true, cancelable: true, view: window}));
              return true; 
            }
            return false;
          },
          args: [params.selector]
        });
        if (hoverRes && hoverRes.some(r => r.result === true)) return `Hovered over element ${params.selector}`;
        return `Failed to find element to hover: ${params.selector}`;

      case 'wait':
        const delay = parseInt(params.amount) || 2000;
        await new Promise(resolve => setTimeout(resolve, delay));
        return `Waited for ${delay}ms`;
        
      case 'scroll':
        await chrome.scripting.executeScript({
          target: { tabId, allFrames: true },
          func: (direction, amount) => {
            if (direction === 'down') window.scrollBy(0, amount || window.innerHeight);
            else if (direction === 'up') window.scrollBy(0, -(amount || window.innerHeight));
          },
          args: [params.direction, params.amount]
        });
        return `Scrolled ${params.direction}`;
        
      case 'navigate':
        await chrome.tabs.update(tabId, { url: params.url });
        return `Navigating to ${params.url}...`;

      case 'record':
        return await executeRecordSession(params);

      default:
        return `Unknown tool action: ${action}`;
    }
  } catch (e) {
    return `Error executing ${action}: ${e.message}`;
  }
}

async function handleChatRequest(prompt) {
  const state = await getStoredState();

  if (!state.consentGranted) {
    return "I cannot assist until you enable Agent Capabilities in my settings menu. This allows me to see the active tab and screen context.";
  }

  if (!state.authToken) {
    return "You are not authenticated. Please log in.";
  }

  try {
    let fullPrompt = prompt;
    let pageContext = "";
    
    // Always attempt to grab context for grounding
    const tabContext = await getActiveTabContent();
    if (tabContext) {
      pageContext = tabContext;
    }
    
    // Capture visual context
    let inlineData = null;
    try {
      const tabs = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
      if (tabs.length > 0 && !tabs[0].url.startsWith('chrome://')) {
          const dataUrl = await chrome.tabs.captureVisibleTab(null, { format: 'jpeg', quality: 50 });
          const base64Str = dataUrl.split(',')[1];
          inlineData = {
              mimeType: 'image/jpeg',
              data: base64Str
          };
      }
    } catch (e) {
        console.warn('Failed to capture screen:', e);
    }

    const systemInstruction = `You are Brian, the AI Orchestrator for InhausBrain.
You have the ability to control the user's active Chrome tab. 
If the user asks you to interact with the webpage, you MUST output a raw JSON block describing the tool call, exactly in this format:
\`\`\`tool_call
{
  "action": "click|type|hover|scroll|navigate|wait|record",
  "params": {
    "selector": "CSS selector to click, hover, or type into. You can also use exact text strings (e.g. 'Log In')",
    "text": "Text to type. Append '[Enter]' to simulate hitting the enter key immediately after typing (if action=type)",
    "direction": "up|down (if action=scroll)",
    "amount": "Milliseconds to wait (if action=wait)",
    "url": "https://url-to-visit (if action=navigate)",
    "command": "start|stop (if action=record)"
  }
}
\`\`\`
For example: To type and submit a search form:
\`\`\`tool_call
{"action": "type", "params": {"selector": "input[name='q']", "text": "shoes[Enter]"}}
\`\`\`
For example: To wait for an element to load:
\`\`\`tool_call
{"action": "wait", "params": {"amount": "3000"}}
\`\`\`

If you need to perform multiple actions at once (like filling out an entire form), you can output multiple \`\`\`tool_call blocks sequentially!
Only output the JSON block when performing an action. Otherwise, just converse normally based on the user's prompt and the following structured page context. The page context will highlight interactable elements like *[Actionable <tag>: "Label"]*.
I have also provided a screenshot of the current viewport so you can visually see the layout.

${pageContext}`;

    // Construct Multimodal Prompt
    const multimodalPrompt = [
        prompt
    ];
    if (inlineData) {
        multimodalPrompt.push({ inlineData: inlineData });
    }

    // Call InhausBrain Cloud Run Proxy
    const response = await fetch("https://generate-content-btdf7nijqa-uc.a.run.app", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + state.authToken
      },
      body: JSON.stringify({
        model: "gemini-3-flash-preview",
        prompt: multimodalPrompt,
        systemInstruction: systemInstruction,
        thinking: false
      })
    });

    if (!response.ok) {
       if (response.status === 401 || response.status === 403) {
          return "Your authentication token has expired. Please open the settings menu to Log out and back in.";
       }
       const errorText = await response.text();
       return "API Error: " + response.status + " - " + errorText;
    }
    
    const data = await response.json();

    if (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts) {
       let responseText = data.candidates[0].content.parts.map(p => p.text).join("");
       
       // Detect Multiple Tool Calls
       const toolCallMatches = [...responseText.matchAll(/```tool_call\s*({[\s\S]*?})\s*```/g)];
       if (toolCallMatches.length > 0) {
         let results = [];
         for (let i = 0; i < toolCallMatches.length; i++) {
           try {
             const toolReq = JSON.parse(toolCallMatches[i][1]);
             const actionRes = await executeBrowserAction(toolReq.action, toolReq.params);
             results.push(`Action ${i+1} (${toolReq.action}): ${actionRes}`);
           } catch (e) {
             results.push(`Action ${i+1}: Failed to parse JSON request. Error: ${e.message}`);
           }
         }
         return `Executed ${toolCallMatches.length} Actions:\n\n${results.join('\n')}`;
       }
       
       return responseText;
    }
    
    return "I processed your request, but received an unexpected response structure.";
  } catch (error) {
    return "Network error connecting to InhausBrain: " + error.message;
  }
}

async function handleToolExecution(toolName, args) {
  let result;
  switch (toolName) {
    case 'browser_control':
      result = await executeBrowserControl(args);
      break;
    case 'screen_capture':
      result = await executeScreenCapture(args);
      break;
    case 'record_session':
      result = await executeRecordSession(args);
      break;
    case 'input_sim':
      result = await executeInputSimulation(args);
      break;
    case 'fetch_dom_context':
      result = await fetchDomContext(args);
      break;
    default:
      throw new Error(`Unknown WebMCP tool: ${toolName}`);
  }

  // BW3.0: Log device action to BrainWeave graph with provenance
  try {
    const { inhausBw30Enabled } = await chrome.storage.local.get('inhausBw30Enabled');
    if (inhausBw30Enabled) {
      await logToBrainWeave(toolName, args, result);
    }
  } catch (e) {
    console.warn('BW3.0 provenance logging skipped:', e);
  }

  return result;
}

/**
 * BW3.0: Log a device action to the BrainWeave graph as an atomic node.
 * Creates a node with full provenance (source_agent: chrome_extension).
 */
async function logToBrainWeave(toolName, args, result) {
  const state = await getStoredState();
  if (!state.authToken) return;

  const MCP_URL = "https://brainweave-mcp-1096509611056.us-central1.run.app";
  try {
    const tabs = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
    const activeTab = tabs?.[0];

    await fetch(`${MCP_URL}/brainweave_create`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${state.authToken}`
      },
      body: JSON.stringify({
        title: `Device Action: ${toolName}`,
        description: `Chrome extension executed ${toolName} on ${activeTab?.url || 'unknown page'}`,
        content: JSON.stringify({ tool: toolName, args, result: typeof result === 'string' ? result : JSON.stringify(result)?.substring(0, 500) }),
        node_type: "device_action",
        topics: ["device_control", "chrome_extension", toolName],
        scope: "PRIVATE",
        source_agent: "chrome_extension",
        provenance: `chrome-ext://InhausBrain/${toolName}`,
        metadata: {
          tab_url: activeTab?.url,
          tab_title: activeTab?.title,
          timestamp: new Date().toISOString()
        }
      })
    });
  } catch (e) {
    console.warn("BW3.0 graph logging failed (non-fatal):", e);
  }
}

async function executeBrowserControl(args) {
    if (args.command === 'list_tabs') {
        const tabs = await chrome.tabs.query({});
        return tabs.map(t => ({ id: t.id, url: t.url, title: t.title, active: t.active }));
    } else if (args.command === 'create_tab') {
        const tab = await chrome.tabs.create({ url: args.url });
        return { id: tab.id, status: 'created' };
    } else if (args.command === 'close_tab') {
        await chrome.tabs.remove(args.tabId);
        return { status: 'closed' };
    }
    throw new Error('Invalid browser_control command');
}

async function executeScreenCapture(args) {
    // Requires active tab
    return new Promise((resolve, reject) => {
        chrome.tabs.captureVisibleTab(null, { format: 'png' }, (dataUrl) => {
            if (chrome.runtime.lastError) {
                reject(chrome.runtime.lastError.message);
            } else {
                resolve({ base64: dataUrl });
            }
        });
    });
}

// Global recording state
let isRecording = false;

async function executeRecordSession(args) {
    if (args.command === 'start') {
        if (isRecording) {
            return { status: 'already_recording' };
        }
        
        // Ensure offscreen document exists
        await setupOffscreenDocument('offscreen.html');
        
        // Start recording via offscreen document
        chrome.runtime.sendMessage({
            type: 'start-recording',
            target: 'offscreen'
        });
        
        isRecording = true;
        return { status: 'recording_started' };
        
    } else if (args.command === 'stop') {
        if (!isRecording) {
            return { status: 'not_recording' };
        }
        
        // Stop recording via offscreen document
        chrome.runtime.sendMessage({
            type: 'stop-recording',
            target: 'offscreen'
        });
        
        isRecording = false;
        return { status: 'recording_stopped', message: 'Recording will be downloaded shortly.' };
    }
    
    throw new Error('Invalid record_session command. Use "start" or "stop"');
}

async function setupOffscreenDocument(path) {
    const existingContexts = await chrome.runtime.getContexts({});
    const offscreenDocument = existingContexts.find(
        (c) => c.contextType === 'OFFSCREEN_DOCUMENT'
    );
    
    // If an offscreen document is not already open, create one.
    if (!offscreenDocument) {
        // Create an offscreen document.
        await chrome.offscreen.createDocument({
            url: path,
            reasons: ['DISPLAY_MEDIA'],
            justification: 'Recording screen for AI context',
        });
    }
}

async function executeInputSimulation(args) {
    // Complex implementation using chrome.debugger API
    throw new Error('input_sim tool not yet implemented in V1');
}

async function fetchDomContext(args) {
    let query = { active: true, lastFocusedWindow: true };
    if (args.tabId) { query = { id: args.tabId }; }
    
    const tabs = await chrome.tabs.query(query);
    if (!tabs || tabs.length === 0) throw new Error("No active tab found");
    
    // Inject content script to get data
    return new Promise((resolve, reject) => {
        chrome.scripting.executeScript({
            target: { tabId: tabs[0].id },
            func: () => {
                return {
                    url: document.location.href,
                    title: document.title,
                    text: document.body.innerText.substring(0, 5000), // Limit size
                    selectedText: window.getSelection().toString()
                };
            }
        }, (results) => {
            if (chrome.runtime.lastError) reject(chrome.runtime.lastError.message);
            else resolve(results[0].result);
        });
    });
}

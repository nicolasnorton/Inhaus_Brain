document.addEventListener('DOMContentLoaded', () => {
    // UI Elements
    const chatContainer = document.getElementById('chatContainer');
    const chatInput = document.getElementById('chatInput');
    const sendBtn = document.getElementById('sendBtn');
    const settingsBtn = document.getElementById('settingsBtn');
    const settingsOverlay = document.getElementById('settingsOverlay');
    const agentToggle = document.getElementById('agentToggle');

    // Authentication Guard
    chrome.runtime.sendMessage({ action: 'check_auth' }, (response) => {
        if (!response || !response.authenticated) {
            window.location.href = 'auth.html';
            return;
        }

        // Show user email in settings
        const emailSpan = document.createElement('div');
        emailSpan.style.fontSize = '12px';
        emailSpan.style.color = 'var(--text-secondary)';
        emailSpan.style.marginBottom = '12px';
        emailSpan.style.paddingBottom = '8px';
        emailSpan.style.borderBottom = '1px solid var(--border-color)';
        emailSpan.innerText = `Signed in as: ${response.email}`;
        settingsOverlay.insertBefore(emailSpan, settingsOverlay.firstChild);

        // Add Logout button
        const logoutBtn = document.createElement('button');
        logoutBtn.innerText = 'Log out';
        logoutBtn.style.marginTop = '12px';
        logoutBtn.style.width = '100%';
        logoutBtn.style.padding = '6px';
        logoutBtn.style.background = 'transparent';
        logoutBtn.style.border = '1px solid var(--border-color)';
        logoutBtn.style.color = 'var(--text-secondary)';
        logoutBtn.style.borderRadius = '4px';
        logoutBtn.style.cursor = 'pointer';
        
        logoutBtn.addEventListener('click', () => {
            chrome.runtime.sendMessage({ action: 'logout' }, () => {
                window.location.href = 'auth.html';
            });
        });
        
        settingsOverlay.appendChild(logoutBtn);
    });

    // Load initial consent state
    chrome.runtime.sendMessage({ action: 'get_consent' }, (response) => {
        if (response) agentToggle.checked = response.consent;
    });

    // Consent Toggle
    agentToggle.addEventListener('change', (e) => {
        chrome.runtime.sendMessage({ action: 'set_consent', consent: e.target.checked });
    });

    // Settings Menu Toggle
    settingsBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        settingsOverlay.classList.toggle('visible');
    });

    document.addEventListener('click', () => {
        if (settingsOverlay.classList.contains('visible')) {
            settingsOverlay.classList.remove('visible');
        }
    });

    settingsOverlay.addEventListener('click', (e) => e.stopPropagation());

    // Auto-resize textarea
    chatInput.addEventListener('input', function() {
        this.style.height = 'auto';
        this.style.height = (this.scrollHeight) + 'px';
        
        if (this.value.trim().length > 0) {
            sendBtn.classList.add('active');
        } else {
            sendBtn.classList.remove('active');
        }
    });

    // Handle Enter key (Shift+Enter for newline)
    chatInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    sendBtn.addEventListener('click', () => {
        if (chatInput.value.trim().length > 0) {
            sendMessage();
        }
    });

    function appendMessage(text, isUser = false) {
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${isUser ? 'user' : 'bot'}`;
        
        if (!isUser) {
            const nameDiv = document.createElement('div');
            nameDiv.className = 'bot-name';
            nameDiv.innerText = 'Brian';
            msgDiv.appendChild(nameDiv);
        }

        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        // Very basic markdown handling for code blocks
        if (text.includes('```')) {
            const parts = text.split('```');
            let htmlStr = '';
            for(let i=0; i<parts.length; i++) {
                if(i % 2 !== 0) {
                    htmlStr += `<pre><code>${parts[i].replace(/^.+\n/, '')}</code></pre>`;
                } else {
                    htmlStr += parts[i].replace(/\n/g, '<br>');
                }
            }
            contentDiv.innerHTML = htmlStr;
        } else {
            contentDiv.innerHTML = text.replace(/\n/g, '<br>');
        }

        msgDiv.appendChild(contentDiv);
        chatContainer.appendChild(msgDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }

    function appendThinking() {
        const msgDiv = document.createElement('div');
        msgDiv.id = 'thinkingIndicator';
        msgDiv.className = 'message bot';
        
        const nameDiv = document.createElement('div');
        nameDiv.className = 'bot-name';
        nameDiv.innerText = 'Brian';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'thinking';
        contentDiv.innerHTML = '<div class="dot"></div><div class="dot"></div><div class="dot"></div>';
        
        msgDiv.appendChild(nameDiv);
        msgDiv.appendChild(contentDiv);
        chatContainer.appendChild(msgDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight;
        return msgDiv;
    }

    function removeThinking() {
        const indicator = document.getElementById('thinkingIndicator');
        if (indicator) {
            indicator.remove();
        }
    }

    async function sendMessage() {
        const text = chatInput.value.trim();
        if (!text) return;

        // Reset UI
        chatInput.value = '';
        chatInput.style.height = 'auto';
        sendBtn.classList.remove('active');

        // Add user message
        appendMessage(text, true);
        appendThinking();

        // Send to background script which can forward to BrainWeave Cloud Run endpoints
        chrome.runtime.sendMessage({ 
            action: 'chat_request', 
            prompt: text 
        }, (response) => {
            removeThinking();
            if (chrome.runtime.lastError) {
                appendMessage("Error: Could not connect to background extension service.");
                return;
            }
            
            if (response && response.error) {
                appendMessage(`Error: ${response.error}`);
            } else if (response && response.text) {
                appendMessage(response.text);
            } else {
                appendMessage("Sorry, I could not process your request.");
            }
        });
    }
});

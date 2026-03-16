document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const loginBtn = document.getElementById('loginBtn');
    const errorMessage = document.getElementById('errorMessage');

    // Automatically check if already logged in
    chrome.runtime.sendMessage({ action: 'check_auth' }, (response) => {
        if (response && response.authenticated) {
            window.location.href = 'sidepanel.html';
        }
    });

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const email = emailInput.value.trim();
        const password = passwordInput.value;

        if (!email || !password) {
            errorMessage.innerText = "Please enter both email and password.";
            return;
        }

        loginBtn.disabled = true;
        loginBtn.innerText = "Signing in...";
        errorMessage.innerText = "";

        // Send credentials to background script to perform secure Auth POST via REST API
        chrome.runtime.sendMessage({ 
            action: 'login', 
            email: email, 
            password: password 
        }, handleLoginResponse);
    });

    // Google Sign-In Logic
    const googleBtn = document.getElementById('googleBtn');
    if (googleBtn) {
        googleBtn.addEventListener('click', () => {
            googleBtn.disabled = true;
            googleBtn.innerHTML = "Opening Google...";
            errorMessage.innerText = "";
            
            chrome.runtime.sendMessage({ action: 'login_google' }, (response) => {
                googleBtn.disabled = false;
                googleBtn.innerHTML = `
                    <svg viewBox="0 0 24 24" width="18" height="18">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                        <path d="M1 1h22v22H1z" fill="none"/>
                    </svg>Sign in with Google`;
                handleLoginResponse(response);
            });
        });
    }

    function handleLoginResponse(response) {
        if (chrome.runtime.lastError) {
            errorMessage.innerText = "Extension error: " + chrome.runtime.lastError.message;
            return;
        }

        if (response && response.success) {
            // Redirect back to chat interface
            window.location.href = 'sidepanel.html';
        } else {
            errorMessage.innerText = response?.error || "Authentication failed.";
        }
    }
});

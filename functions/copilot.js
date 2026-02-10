const { CopilotRuntime, GoogleGenerativeAIAdapter, copilotRuntimeNodeHttpEndpoint } = require('@copilotkit/runtime');
const functions = require('firebase-functions');
const express = require('express');

const app = express();

// Use JSON body parser
app.use(express.json());

// Middleware to handle Gemini API Key and Runtime setup
app.use(async (req, res, next) => {
    // Diagnostic Logging
    console.log(`[COPILOT] 📥 Request Method: ${req.method}`);
    console.log(`[COPILOT] 📥 Request Path: ${req.path}`);
    if (req.method === 'POST') {
        console.log(`[COPILOT] 📦 Request Body: ${JSON.stringify(req.body)}`);
        if (req.body && req.body.method === 'chat') {
            console.log(`[COPILOT] ⚠️ Stripping 'method: chat' for v1 compatibility`);
            delete req.body.method;
        }
    }

    // CORS Header is needed for all responses
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    try {
        let apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;

        if (!apiKey) {
            try {
                if (functions.config().google) {
                    apiKey = functions.config().google.api_key;
                }
            } catch (e) { }
        }

        if (!apiKey) {
            console.error('Gemini API Key is missing.');
            res.status(500).send('Configuration Error: API Key Missing');
            return;
        }

        req.runtime = new CopilotRuntime();
        req.serviceAdapter = new GoogleGenerativeAIAdapter({
            model: "gemini-1.5-pro-002",
            apiKey: apiKey,
        });


        next();
    } catch (error) {
        console.error('Error in Copilot Middleware:', error);
        res.status(500).send(`Internal Server Error: ${error.message}`);
    }
});

// Use the runtime handler
app.all('*', async (req, res) => {
    try {
        const handler = copilotRuntimeNodeHttpEndpoint({
            endpoint: '/',
            runtime: req.runtime,
            serviceAdapter: req.serviceAdapter,
        });

        await handler(req, res);
    } catch (error) {
        console.error('Error in Copilot Handler:', error);
        res.status(500).send(`Internal Server Error: ${error.message}`);
    }
});

// The exported function is the Express app
const copilotHandler = app;

module.exports = {
    copilotHandler,
};

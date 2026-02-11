const { CopilotRuntime, LangChainAdapter, copilotRuntimeNodeHttpEndpoint } = require('@copilotkit/runtime');
const { ChatVertexAI } = require('@langchain/google-vertexai');
const functions = require('firebase-functions');
const express = require('express');

const app = express();

// Use JSON body parser
app.use(express.json());

app.use(async (req, res, next) => {
    // Diagnostic Logging
    console.log(`[COPILOT] 📥 Request Method: ${req.method}`);
    console.log(`[COPILOT] 📥 Request Path: ${req.path}`);
    if (req.method === 'POST') {
        console.log(`[COPILOT] 📦 Request Body: ${JSON.stringify(req.body)}`);
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
        // Initialize Copilot Runtime
        req.runtime = new CopilotRuntime();

        // Use LangChainAdapter with ChatVertexAI
        // Vertex AI handles auth automatically via Application Default Credentials (ADC) in Cloud Functions
        req.serviceAdapter = new LangChainAdapter({
            chainFn: async ({ messages, tools }) => {
                let model = new ChatVertexAI({
                    model: "gemini-2.5-pro",
                    location: "us-central1",
                    maxOutputTokens: 8192,
                });

                if (tools && tools.length > 0) {
                    model = model.bindTools(tools);
                }

                return model.stream(messages);
            }
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

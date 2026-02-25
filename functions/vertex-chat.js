const { ChatVertexAI } = require('@langchain/google-vertexai');
const functions = require('firebase-functions');
const express = require('express');

const app = express();

// Use JSON body parser
app.use(express.json());

// CORS middleware
app.use((req, res, next) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    next();
});

// Main chat endpoint
app.post('*', async (req, res) => {
    try {
        console.log(`[VERTEX-CHAT] 📥 Request received`);

        const { messages, tools } = req.body;

        // Validate request
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({
                error: 'Invalid request: messages array required'
            });
        }

        console.log(`[VERTEX-CHAT] Processing ${messages.length} messages`);
        if (tools && tools.length > 0) {
            console.log(`[VERTEX-CHAT] ${tools.length} tools provided`);
        }

        // Set up SSE headers
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');

        // Initialize ChatVertexAI model
        let model = new ChatVertexAI({
            model: "gemini-3.1-pro-preview",
            location: "us-central1",
            maxOutputTokens: 8192,
        });

        // Bind tools if provided
        if (tools && tools.length > 0) {
            model = model.bindTools(tools);
        }

        // Convert messages to LangChain format
        const langchainMessages = messages.map(msg => {
            return {
                role: msg.role,
                content: msg.content
            };
        });

        console.log(`[VERTEX-CHAT] Starting stream...`);

        // Stream the response
        const stream = await model.stream(langchainMessages);

        let chunkCount = 0;
        for await (const chunk of stream) {
            if (chunk.content) {
                chunkCount++;
                const data = JSON.stringify({
                    type: 'content',
                    content: chunk.content,
                    delta: chunk.content,
                    messageId: `msg_${Date.now()}`
                });
                res.write(`data: ${data}\n\n`);
            }

            // Handle function calls if present
            if (chunk.additional_kwargs?.function_call) {
                const functionCall = chunk.additional_kwargs.function_call;
                const data = JSON.stringify({
                    type: 'function_call',
                    function_call: functionCall
                });
                res.write(`data: ${data}\n\n`);
            }
        }

        console.log(`[VERTEX-CHAT] ✅ Stream complete (${chunkCount} chunks)`);

        // Send completion signal
        res.write('data: [DONE]\n\n');
        res.end();

    } catch (error) {
        console.error('[VERTEX-CHAT] ❌ Error:', error);

        // Send error in SSE format
        const errorData = JSON.stringify({
            type: 'error',
            error: error.message,
            code: error.code || 'unknown'
        });
        res.write(`data: ${errorData}\n\n`);
        res.write('data: [DONE]\n\n');
        res.end();
    }
});

// Export the handler
const vertexChatHandler = app;

module.exports = {
    vertexChatHandler,
};

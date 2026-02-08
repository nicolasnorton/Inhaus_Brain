const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

/**
 * Cloud Run Long-Running Process Prototype
 * 
 * Unlike Cloud Functions which have a default 60s timeout (max 9m/60m depending on gen),
 * Cloud Run can be configured for up to 60 minutes request timeout easily.
 * This allows "Agentic Workflows" to run linearly without complex daisy-chaining of state.
 */

// Simulated heavy work step
const doStep = async (name, durationSec) => {
    console.log(`[${new Date().toISOString()}] Starting step: ${name}`);
    await new Promise(resolve => setTimeout(resolve, durationSec * 1000));
    console.log(`[${new Date().toISOString()}] Completed step: ${name}`);
    return `${name} Result`;
};

app.post('/execute-agent-flow', async (req, res) => {
    const { campaignId, phases } = req.body;
    console.log(`Received request for campaign: ${campaignId}`);

    // In Cloud Run, we can keep the request open for up to 60 mins.
    // This simplifies orchestration significantly: Just use code!

    try {
        // Step 1: Research (Simulated 2s)
        const research = await doStep('Research', 2);

        // Step 2: Strategy (Simulated 2s)
        // In a real app, this might depend on Research output
        const strategy = await doStep('Strategy', 2);

        // Step 3: Creative (Simulated 2s)
        const creative = await doStep('Creative', 2);

        // Final Response
        res.json({
            status: 'success',
            campaignId,
            results: { research, strategy, creative },
            totalTime: '6s (simulated)'
        });

    } catch (error) {
        console.error('Error in agent flow:', error);
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Cloud Run POC listening on port ${PORT}`);
});

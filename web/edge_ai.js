async function getAISystemStatus() {
    if (!window.ai || !window.ai.assistant) return "unsupported";
    try {
        const capabilities = await window.ai.assistant.capabilities();
        return capabilities.available; // 'readily', 'after-download', or 'no'
    } catch (e) {
        return "error";
    }
}

async function promptBuiltInAI(query) {
    console.log("EdgeAI: Prompting local model with:", query);
    if (!window.ai || !window.ai.assistant) {
        return null;
    }

    try {
        const capabilities = await window.ai.assistant.capabilities();
        if (capabilities.available === 'no') {
            return null;
        }

        const session = await window.ai.assistant.create();
        const response = await session.prompt(query);
        session.destroy();
        return response;
    } catch (e) {
        console.error("EdgeAI Error:", e);
        return null;
    }
}

window.getAISystemStatus = getAISystemStatus;
window.promptBuiltInAI = promptBuiltInAI;

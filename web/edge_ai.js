async function promptBuiltInAI(query) {
    if (!window.ai || !window.ai.assistant) {
        console.warn("Chrome Built-in AI (Prompt API) not available.");
        return null;
    }

    try {
        const capabilities = await window.ai.assistant.capabilities();
        if (capabilities.available === 'no') {
            console.warn("AI Assistant models not downloaded or available.");
            return null;
        }

        const session = await window.ai.assistant.create();
        const response = await session.prompt(query);
        session.destroy();
        return response;
    } catch (e) {
        console.error("Chrome AI Error:", e);
        return null;
    }
}

window.promptBuiltInAI = promptBuiltInAI;

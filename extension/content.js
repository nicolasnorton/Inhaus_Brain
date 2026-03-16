// Content script for extracting context and interacting with the DOM
// Currently lightweight, relies on Background script `executeScript` injections for heavy lifting.

console.log("InhausBrain Assistant Content Script loaded.");

// We could add mutation observers here to auto-notify BrainWeave if pages change,
// but for V1 we keep it pull-based from the background worker.

window.addEventListener('message', (event) => {
    // Optional: listen for specific in-page postMessage events 
    // if we want to bridge non-extension web contexts directly
});

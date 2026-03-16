let mediaRecorder;
let recordedChunks = [];

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.target !== 'offscreen') {
    return;
  }

  switch (message.type) {
    case 'start-recording':
      startRecording();
      break;
    case 'stop-recording':
      stopRecording();
      break;
  }
});

async function startRecording() {
  if (mediaRecorder && mediaRecorder.state === 'recording') {
    return;
  }

  // Request a MediaStream of the active tab.
  // Note: Tab audio works best.
  chrome.tabCapture.getMediaStreamId({ targetTabId: null }, (streamId) => {
    if (!streamId) {
      console.error('Failed to get media stream id:', chrome.runtime.lastError);
      return;
    }

    navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        mandatory: {
          chromeMediaSource: 'tab',
          chromeMediaSourceId: streamId,
        }
      }
    }).then((stream) => {
      recordedChunks = [];
      mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/webm' });

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(recordedChunks, { type: 'video/webm' });
        
        // Convert to object URL and download natively
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        document.body.appendChild(a);
        a.style.display = 'none';
        a.href = url;
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        a.download = `inhaus-recording-${timestamp}.webm`;
        a.click();
        
        // Cleanup
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
        // Stop all tracks to release the microphone/camera/tab indicator
        stream.getTracks().forEach((track) => track.stop());
        
        // Terminate offscreen doc
        window.close();
      };

      mediaRecorder.start();
    }).catch((error) => {
      console.error('Error getting user media:', error);
    });
  });
}

function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop();
  }
}

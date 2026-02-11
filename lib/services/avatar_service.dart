import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarService {
  final Ref ref;

  AvatarService(this.ref);

  /// Generates a Ready Player Me avatar URL given a configuration or ID.
  String getAvatarUrl(String avatarId) {
    // Standard RPM URL format
    return 'https://models.readyplayer.me/$avatarId.glb';
  }

  /// Returns a WebView-ready HTML snippet for a 3D scene with avatars.
  String getDialogueSceneHtml({
    required List<Map<String, String>> personas,
    required String initialMessage,
  }) {
    // This is a simplified fallback that can be expanded with Three.js or similar
    // for a real "DialogLab" feel.
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            background: #0f1116; 
            color: white; 
            font-family: sans-serif; 
            display: flex; 
            flex-direction: column; 
            align-items: center; 
            justify-content: center; 
            height: 100vh; 
            margin: 0;
            overflow: hidden;
          }
          .stage {
            width: 100%;
            height: 60%;
            display: flex;
            justify-content: space-around;
            align-items: flex-end;
          }
          .avatar {
            width: 150px;
            height: 150px;
            background: #232931;
            border-radius: 50%;
            border: 2px solid #3b82f6;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            transition: transform 0.3s;
          }
          .avatar.active {
            transform: scale(1.1);
            border-color: #fbbf24;
            box-shadow: 0 0 20px rgba(251, 191, 36, 0.4);
          }
          .speech-bubble {
            margin-top: 20px;
            padding: 20px;
            background: #1c2128;
            border-radius: 12px;
            max-width: 80%;
            text-align: center;
            border: 1px solid #ffffff1a;
          }
        </style>
      </head>
      <body>
        <div class="stage">
          ${personas.map((p) => '<div class="avatar" id="${p['id']}">${p['name']}</div>').join('')}
        </div>
        <div class="speech-bubble" id="dialogue-text">
          $initialMessage
        </div>
        <script>
          window.setActiveSpeaker = (id) => {
            document.querySelectorAll('.avatar').forEach(a => a.classList.remove('active'));
            const speaker = document.getElementById(id);
            if (speaker) speaker.classList.add('active');
          }
          
          window.setDialogueText = (text) => {
            document.getElementById('dialogue-text').innerText = text;
          }
        </script>
      </body>
      </html>
    ''';
  }
}

final avatarServiceProvider = Provider((ref) => AvatarService(ref));

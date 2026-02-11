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
    required List<Map<String, dynamic>> personas,
    required String initialMessage,
    String environmentId = 'office',
    String cameraAnchor = 'default',
  }) {
    final envStyle = _getEnvironmentStyles(environmentId);
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap" rel="stylesheet">
        <style>
          :root {
            --primary-blue: #3b82f6;
            --accent-gold: #fbbf24;
            --bg-color: ${envStyle['bg']};
          }
          
          body { 
            background: var(--bg-color); 
            color: white; 
            font-family: 'Inter', sans-serif; 
            display: flex; 
            flex-direction: column; 
            align-items: center; 
            justify-content: flex-end; 
            height: 100vh; 
            margin: 0;
            overflow: hidden;
            background-image: ${envStyle['overlay']};
            background-size: cover;
            background-position: center;
          }

          .environment-container {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -1;
            transition: all 1s ease-in-out;
          }

          .stage {
            width: 100%;
            height: 70%;
            display: flex;
            justify-content: center;
            align-items: flex-end;
            gap: 40px;
            padding-bottom: 20px;
            perspective: 1000px;
            transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
          }

          /* Camera Anchors */
          .camera-presenter .stage { transform: translateZ(200px) translateY(50px); }
          .camera-audience .stage { transform: translateZ(-200px) translateY(-20px); }
          .camera-orbit .stage { animation: orbit 20s infinite linear; }

          @keyframes orbit {
            0% { transform: rotateY(0deg); }
            100% { transform: rotateY(360deg); }
          }

          .avatar-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            transition: all 0.5s ease;
          }

          .avatar {
            width: 120px;
            height: 120px;
            background: #1e293b;
            border-radius: 50%;
            border: 3px solid rgba(255,255,255,0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            position: relative;
            overflow: hidden;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5);
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
          }

          .avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
          }

          .avatar.active {
            transform: scale(1.15) translateY(-10px);
            border-color: var(--accent-gold);
            box-shadow: 0 0 30px rgba(251, 191, 36, 0.4);
          }

          .avatar.active::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 10px;
            background: var(--accent-gold);
            filter: blur(8px);
          }

          .label {
            margin-top: 12px;
            font-size: 14px;
            font-weight: 700;
            color: rgba(255,255,255,0.7);
            text-transform: uppercase;
            letter-spacing: 1px;
            transition: color 0.3s;
          }

          .active .label {
            color: var(--accent-gold);
          }

          .speech-bubble {
            margin: 0 20px 40px 20px;
            padding: 24px 32px;
            background: rgba(15, 23, 42, 0.8);
            backdrop-filter: blur(12px);
            border-radius: 20px;
            max-width: 800px;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.1);
            box-shadow: 0 20px 50px rgba(0,0,0,0.3);
            animation: slideUp 0.6s ease-out;
          }

          @keyframes slideUp {
            from { transform: translateY(20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
          }

          #dialogue-text {
            font-size: 18px;
            line-height: 1.6;
            color: #f1f5f9;
          }
        </style>
      </head>
      <body class="camera-$cameraAnchor">
        <div class="environment-container" style="background: ${envStyle['bg']}; background-image: ${envStyle['overlay']};"></div>
        
        <div class="stage">
          ${personas.map((p) => '''
            <div class="avatar-container" id="container-${p['id']}">
              <div class="avatar" id="${p['id']}">
                ${p['avatar_url'] != null ? '<img src="${p['avatar_url']}" />' : '<span>${p['name'][0]}</span>'}
              </div>
              <div class="label">${p['name']}</div>
            </div>
          ''').join('')}
        </div>

        <div class="speech-bubble">
          <div id="dialogue-text">$initialMessage</div>
        </div>

        <script>
          window.setActiveSpeaker = (id) => {
            document.querySelectorAll('.avatar-container').forEach(a => a.classList.remove('active'));
            const container = document.getElementById('container-' + id);
            if (container) container.classList.add('active');
          }
          
          window.setDialogueText = (text) => {
            const el = document.getElementById('dialogue-text');
            el.style.opacity = 0;
            setTimeout(() => {
              el.innerText = text;
              el.style.opacity = 1;
            }, 300);
          }

          window.setCameraAnchor = (anchor) => {
            document.body.className = 'camera-' + anchor;
          }

          window.setGesture = (id, gesture) => {
            const avatar = document.getElementById(id);
            if (!avatar) return;
            
            if (gesture === 'nod') {
              avatar.animate([
                { transform: 'translateY(0)' },
                { transform: 'translateY(10px)' },
                { transform: 'translateY(0)' }
              ], { duration: 500, iterations: 2 });
            } else if (gesture === 'shake') {
              avatar.animate([
                { transform: 'translateX(0)' },
                { transform: 'translateX(10px)' },
                { transform: 'translateX(-10px)' },
                { transform: 'translateX(0)' }
              ], { duration: 400, iterations: 2 });
            }
          }
          
          // Initial speaker
          if ("${personas.isNotEmpty ? personas[0]['id'] : ''}") {
            window.setActiveSpeaker("${personas.isNotEmpty ? personas[0]['id'] : ''}");
          }
        </script>
      </body>
      </html>
    ''';
  }

  Map<String, String> _getEnvironmentStyles(String id) {
    switch (id) {
      case 'office':
        return {
          'bg': '#0f172a',
          'overlay': 'linear-gradient(rgba(15, 23, 42, 0.7), rgba(15, 23, 42, 0.7)), url("https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80")'
        };
      case 'zen_garden':
        return {
          'bg': '#064e3b',
          'overlay': 'linear-gradient(rgba(6, 78, 59, 0.6), rgba(6, 78, 59, 0.6)), url("https://images.unsplash.com/photo-1558449028-b53a39d100fc?auto=format&fit=crop&w=1200&q=80")'
        };
      case 'stage':
        return {
          'bg': '#450a0a',
          'overlay': 'linear-gradient(rgba(69, 10, 10, 0.8), rgba(69, 10, 10, 0.8)), url("https://images.unsplash.com/photo-1503095396549-807a8bc36675?auto=format&fit=crop&w=1200&q=80")'
        };
      default:
        return {'bg': '#0f1116', 'overlay': 'none'};
    }
  }
}

final avatarServiceProvider = Provider((ref) => AvatarService(ref));

import firebase_admin
from firebase_admin import credentials, firestore

try:
    cred = credentials.Certificate('/Users/nicolasnorton/AudioTherapy/audio_therapy_app/InhausBrain/mcp-api/sa-key.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    clients = db.collection('clients').get()
    print(f"Found {len(clients)} clients.")
    for c in clients:
        doc = c.to_dict()
        print(f"- {doc.get('name')} ({doc.get('clientType')})")
except Exception as e:
    print(f"Error: {e}")

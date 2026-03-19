from firebase_functions import https_fn, options
import json
import os

@https_fn.on_request(memory=options.MemoryOption.MB_128, invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["GET", "OPTIONS"]))
def agent_card(req: https_fn.Request) -> https_fn.Response:
    """
    A2A Discovery Endpoint
    Usually mapped to `/.well-known/agent-card.json` via Firebase Hosting rewrites.
    """
    if req.method != "GET" and req.method != "OPTIONS":
        return https_fn.Response("Method Not Allowed", status=405)
        
    # Standard A2A Payload Format
    card = {
        "agent_id": "urn:agent:inhausbrain-core",
        "name": "InhausBrain Orchestrator",
        "description": "Core routing and orchestration agent for the Inhaus ecosystem.",
        "capabilities": [
            "urn:capability:ucp-checkout",
            "urn:capability:research",
            "urn:capability:content-generation"
        ],
        # In a production system, this would be a real X.509/PEM public key
        "public_key": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1...",
        # The signature proving ownership of the DID or agent_id
        "signature": "mock_signature_for_discovery_compliance"
    }
    
    return https_fn.Response(
        json.dumps(card),
        status=200,
        headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        }
    )

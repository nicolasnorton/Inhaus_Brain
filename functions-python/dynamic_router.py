"""
Dynamic Router — Agentic Routing Strategy

Generates router prompts dynamically from the Firestore agent registry,
replacing the static router.md capabilities section.
"""


def build_router_prompt(agent_registry: list) -> str:
    """
    Build router prompt from agent metadata.
    
    Args:
        agent_registry: List of dicts with 'name' and 'description' keys.
        
    Returns:
        Complete router prompt string.
    """
    if not agent_registry:
        return ''

    agents_section = '\n'.join([
        f"- **{a.get('name', 'unknown')}**: {a.get('description', 'No description.')}"
        for a in agent_registry
    ])

    return f"""# Inhaus Brain — Dynamic Router

## Role
You are the **Root Router** for the Inhaus Brain system. Your SOLE responsibility 
is to analyze the user's request and route it to the most capable specialized agent.
You do NOT answer the question yourself unless it is simple small talk.

## Available Agents
{agents_section}

## Output Format
Return **ONLY** a valid JSON object. Do not include markdown formatting.

```json
{{
    "intent": "agent_name",
    "confidence": 0.95,
    "reasoning": "Brief explanation of why this agent was chosen"
}}
```

## Rules
1. If the request is simple small talk or greetings, route to "directChat".
2. If the request requires multiple agents, a full campaign, or multi-step 
   strategy, route to "pipeline".
3. Always pick the single most relevant agent.
4. Confidence must be between 0.0 and 1.0.
5. If unsure, default to "research" with lower confidence.

## Examples
User: "What are the latest trends in Gen Z banking?"
Output: {{"intent": "research", "confidence": 0.98, "reasoning": "Fact-finding request about market trends."}}

User: "Create a full launch strategy for our new app."
Output: {{"intent": "pipeline", "confidence": 0.95, "reasoning": "Multi-step strategic process."}}

User: "Write an Instagram caption for BDA's new savings account."
Output: {{"intent": "copywriting", "confidence": 0.92, "reasoning": "Social media copy request for specific client."}}
"""


def build_router_prompt_from_firestore(user_id: str) -> str:
    """
    Build router prompt by reading agent registry from Firestore.
    
    Args:
        user_id: The authenticated user's UID.
        
    Returns:
        Complete router prompt string, or empty string if no agents found.
    """
    from firebase_admin import firestore
    db = firestore.client()

    registry_ref = db.collection('workspaces').document(user_id) \
        .collection('agent_registry')
    
    agents = []
    for doc in registry_ref.stream():
        data = doc.to_dict()
        if data:
            agents.append({
                'name': data.get('name', doc.id),
                'description': data.get('description', ''),
            })

    if not agents:
        return ''

    return build_router_prompt(agents)

"""
Session Summarizer — Context Window Management Agent

When conversation history exceeds 75% of the context window or 20 messages,
compresses old messages into a summary and keeps only the last 4 messages.
Prevents context overflow that degrades response quality in long conversations.
"""

from typing import Optional, Tuple, List, Dict, Any


def estimate_tokens(text: str) -> int:
    """Rough token estimate: ~4 chars per token for English text."""
    return len(text) // 4


def maybe_summarize(
    session_messages: List[Dict[str, Any]],
    max_tokens: int = 128000,
    keep_recent: int = 4,
    message_threshold: int = 20,
) -> Tuple[Optional[str], List[Dict[str, Any]]]:
    """
    Check if session history needs summarization.
    
    Standard approach: when history exceeds 75% of context window,
    compress old messages into a summary and keep only the last N messages.
    
    Args:
        session_messages: Full list of conversation messages.
        max_tokens: Maximum context window size in tokens.
        keep_recent: Number of recent messages to always keep.
        message_threshold: Number of messages before triggering summarization.
        
    Returns:
        Tuple of (summary_or_none, messages_to_send).
        If no summarization needed, summary is None and all messages returned.
    """
    if not session_messages:
        return None, session_messages

    # Estimate total tokens in conversation
    total_content = ''.join(
        m.get('content', '') if isinstance(m.get('content'), str) else str(m.get('content', ''))
        for m in session_messages
    )
    token_estimate = estimate_tokens(total_content)
    threshold = max_tokens * 0.75

    # Check if summarization is needed
    if len(session_messages) <= message_threshold and token_estimate <= threshold:
        return None, session_messages

    # Split: messages to summarize vs. messages to keep
    to_summarize = session_messages[:-keep_recent]
    to_keep = session_messages[-keep_recent:]

    if not to_summarize:
        return None, session_messages

    # Build a summary prompt
    summary = _build_summary(to_summarize)
    return summary, to_keep


def _build_summary(messages: List[Dict[str, Any]]) -> str:
    """
    Build a compact summary of conversation messages.
    
    This is a simple extractive summary — for production, you could
    use an LLM call to generate an abstractive summary.
    """
    lines = []
    for msg in messages:
        role = msg.get('role', 'unknown')
        content = msg.get('content', '')
        
        if isinstance(content, str):
            # Truncate long messages for the summary
            if len(content) > 200:
                content = content[:200] + '...'
            lines.append(f"[{role}]: {content}")
        elif isinstance(content, list):
            # Multi-part messages (text + images)
            text_parts = [p.get('text', '') for p in content if isinstance(p, dict) and 'text' in p]
            text = ' '.join(text_parts)
            if len(text) > 200:
                text = text[:200] + '...'
            lines.append(f"[{role}]: {text}")

    summary_text = '\n'.join(lines)
    
    return f"""# Conversation Summary (Auto-Generated)

The following is a summary of the earlier part of this conversation.
The {len(messages)} messages below were compressed to save context window space.

---
{summary_text}
---

(End of summary. The most recent messages follow below.)"""


def generate_abstractive_summary(
    messages: List[Dict[str, Any]],
    gemini_client: Any,
    model: str = 'gemini-2.5-flash',
) -> str:
    """
    Generate a high-quality abstractive summary using an LLM.
    
    This is the premium path — uses a fast model to create a concise summary
    of the old conversation history. Use when you want higher quality than
    the extractive summary.
    
    Args:
        messages: Messages to summarize.
        gemini_client: GeminiClient instance.
        model: Model to use for summarization.
        
    Returns:
        Abstractive summary string.
    """
    # Build the conversation text for the summarizer
    lines = []
    for msg in messages:
        role = msg.get('role', 'unknown')
        content = msg.get('content', '')
        if isinstance(content, str):
            lines.append(f"{role}: {content}")
        elif isinstance(content, list):
            text_parts = [p.get('text', '') for p in content if isinstance(p, dict) and 'text' in p]
            lines.append(f"{role}: {' '.join(text_parts)}")

    conversation_text = '\n'.join(lines)

    summary_prompt = f"""Summarize the following conversation in a concise paragraph.
Focus on:
1. Key decisions made
2. Actions taken or requested  
3. Important context established
4. Any unresolved questions

Conversation:
{conversation_text}

Summary:"""

    try:
        response = gemini_client.generate_content(
            model_name=model,
            prompt=summary_prompt,
            generation_config={'max_output_tokens': 500, 'temperature': 0.3},
        )
        
        # Extract text from response
        if hasattr(response, 'text'):
            return f"# Conversation Summary\n\n{response.text}"
        
        # Fallback to extractive
        return _build_summary(messages)
    except Exception as e:
        print(f"SessionSummarizer: Abstractive summary failed: {e}, falling back to extractive.")
        return _build_summary(messages)

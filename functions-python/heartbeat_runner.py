"""
Heartbeat Runner — Agentic Proactive Tasks

Cloud Scheduler-triggered function that reads heartbeat config from Firestore
and executes periodic tasks. Transforms Brian from reactive chatbot to proactive assistant.

Deployed as a scheduled Cloud Function, triggered every 60 minutes by default.

Schema:
  /workspaces/{userId}/docs/heartbeat → {
    enabled: bool,
    interval_minutes: int,
    tasks: str (markdown list of periodic tasks),
    last_run: Timestamp
  }
"""

import json
from datetime import datetime, timezone
from firebase_admin import firestore
from gemini_client import GeminiClient


def run_heartbeat(user_id: str) -> dict:
    """
    Execute heartbeat tasks for a specific user.
    
    1. Reads heartbeat config from Firestore
    2. Checks if enabled and if enough time has passed
    3. Executes each task via generate_content
    4. Logs results to daily notes
    5. Updates last_run timestamp
    
    Args:
        user_id: The user's Firebase UID.
        
    Returns:
        Dict with execution results.
    """
    db = firestore.client()
    
    # 1. Read heartbeat config
    heartbeat_ref = db.collection('workspaces').document(user_id) \
        .collection('docs').document('heartbeat')
    snap = heartbeat_ref.get()
    
    if not snap.exists:
        return {'status': 'skipped', 'reason': 'No heartbeat config found.'}
    
    config = snap.to_dict()
    if not config:
        return {'status': 'skipped', 'reason': 'Empty heartbeat config.'}
    
    # Check if enabled
    if not config.get('enabled', False):
        return {'status': 'skipped', 'reason': 'Heartbeat disabled.'}
    
    # Check interval
    last_run = config.get('last_run')
    interval_minutes = config.get('interval_minutes', 60)
    
    if last_run:
        last_run_dt = last_run if isinstance(last_run, datetime) else last_run.to_datetime()
        elapsed = (datetime.now(timezone.utc) - last_run_dt).total_seconds() / 60
        if elapsed < interval_minutes:
            return {
                'status': 'skipped', 
                'reason': f'Not enough time elapsed ({elapsed:.0f}m < {interval_minutes}m).'
            }
    
    # 2. Parse tasks from markdown
    tasks_md = config.get('tasks', '')
    tasks = _parse_tasks(tasks_md)
    
    if not tasks:
        return {'status': 'skipped', 'reason': 'No tasks defined.'}
    
    # 3. Execute tasks
    client = GeminiClient()
    results = []
    
    for task in tasks:
        try:
            result = _execute_task(client, task, user_id)
            results.append({'task': task, 'status': 'success', 'result': result})
        except Exception as e:
            results.append({'task': task, 'status': 'error', 'error': str(e)})
    
    # 4. Log results to daily notes
    _log_to_daily_notes(db, user_id, results)
    
    # 5. Update last_run
    heartbeat_ref.update({
        'last_run': firestore.SERVER_TIMESTAMP,
    })
    
    return {
        'status': 'completed',
        'tasks_executed': len(results),
        'results': results,
    }


def _parse_tasks(tasks_md: str) -> list:
    """Parse markdown task list into individual task strings."""
    tasks = []
    for line in tasks_md.split('\n'):
        line = line.strip()
        if line.startswith('- ') or line.startswith('* '):
            task = line[2:].strip()
            if task:
                tasks.append(task)
    return tasks


def _execute_task(client: GeminiClient, task: str, user_id: str) -> str:
    """Execute a single heartbeat task via Gemini."""
    # Load workspace context for the task
    from workspace_context_builder import WorkspaceContextBuilder
    ctx_builder = WorkspaceContextBuilder()
    system_prompt = ctx_builder.build_system_prompt(user_id, include_memory=True)
    
    prompt = f"""You are executing a scheduled heartbeat task. 
    
Task: {task}

Provide a brief status update or result. Be concise — this will be logged to daily notes.
If the task requires external data you cannot access, note what would be needed."""

    response = client.generate_content(
        model_name='gemini-2.5-flash',
        prompt=prompt,
        system_instruction=system_prompt,
        generation_config={'max_output_tokens': 500, 'temperature': 0.3},
    )
    
    if hasattr(response, 'text'):
        return response.text
    return 'Task completed (no text output).'


def _log_to_daily_notes(db, user_id: str, results: list):
    """Append heartbeat results to today's daily note."""
    today = datetime.utcnow().strftime('%Y%m%d')
    note_ref = db.collection('workspaces').document(user_id) \
        .collection('daily_notes').document(today)
    
    timestamp = datetime.utcnow().strftime('%H:%M')
    
    log_entries = []
    for r in results:
        status = '✅' if r['status'] == 'success' else '❌'
        task = r['task']
        detail = r.get('result', r.get('error', 'N/A'))
        # Truncate long results
        if len(detail) > 100:
            detail = detail[:100] + '...'
        log_entries.append(f"- {timestamp} [Heartbeat] {status} {task}: {detail}")
    
    log_text = '\n'.join(log_entries)
    
    snap = note_ref.get()
    if snap.exists:
        data = snap.to_dict()
        current = data.get('content', '') if data else ''
        entries = list(data.get('entries', [])) if data else []
        entries.extend(log_entries)
        note_ref.update({
            'content': f"{current}\n{log_text}",
            'entries': entries,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })
    else:
        date_str = datetime.utcnow().strftime('%B %d, %Y')
        note_ref.set({
            'content': f"# {date_str}\n\n{log_text}",
            'entries': log_entries,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })

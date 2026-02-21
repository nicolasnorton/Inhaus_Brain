"""
WorkspaceContextBuilder — Dynamic System Prompt Assembler

Reads workspace documents from Firestore and assembles the full system prompt.
Called by generate_content before LLM invocation.

Workspace Schema:
  /workspaces/{userId}/docs/identity    → Brian's personality + capabilities
  /workspaces/{userId}/docs/soul        → Values, communication style
  /workspaces/{userId}/docs/user_profile → User preferences
  /workspaces/{userId}/docs/agent_rules → Behavioral rules
  /workspaces/{userId}/docs/memory      → Long-term persistent facts
  /workspaces/{userId}/daily_notes/{YYYYMMDD} → Daily activity log entries
"""

from datetime import datetime, timedelta
from firebase_admin import firestore


class WorkspaceContextBuilder:
    """Assembles system prompt from Firestore workspace documents."""

    def __init__(self):
        self._db = firestore.client()

    def _get_doc_content(self, user_id: str, doc_type: str) -> str:
        """Read a workspace document's content field."""
        ref = self._db.collection('workspaces').document(user_id) \
            .collection('docs').document(doc_type)
        snap = ref.get()
        if snap.exists:
            data = snap.to_dict()
            return data.get('content', '') if data else ''
        return ''

    def _get_recent_daily_notes(self, user_id: str, days: int = 3) -> str:
        """Load the last N days of daily notes."""
        notes = []
        today = datetime.utcnow()
        for i in range(days):
            date = today - timedelta(days=i)
            date_key = date.strftime('%Y%m%d')
            ref = self._db.collection('workspaces').document(user_id) \
                .collection('daily_notes').document(date_key)
            snap = ref.get()
            if snap.exists:
                data = snap.to_dict()
                content = data.get('content', '') if data else ''
                if content:
                    notes.append(content)

        if not notes:
            return ''

        return '# Recent Activity\n\n' + '\n\n'.join(notes)

    def _get_agent_summary(self, user_id: str) -> str:
        """Build agent capabilities summary from registry (metadata only)."""
        agents_ref = self._db.collection('workspaces').document(user_id) \
            .collection('agent_registry')
        agents = agents_ref.stream()

        lines = ['# Available Agents\n']
        agent_count = 0
        for agent in agents:
            data = agent.to_dict()
            if data:
                name = data.get('name', agent.id)
                desc = data.get('description', 'No description.')
                lines.append(f'- **{name}**: {desc}')
                agent_count += 1

        if agent_count == 0:
            return ''

        return '\n'.join(lines)

    def _get_skills_summary(self, user_id: str) -> str:
        """Build skills summary (metadata only — progressive disclosure)."""
        skills_ref = self._db.collection('workspaces').document(user_id) \
            .collection('skills')
        skills = skills_ref.stream()

        lines = ['# Available Skills\n']
        skill_count = 0
        for skill in skills:
            data = skill.to_dict()
            if data:
                name = data.get('name', skill.id)
                desc = data.get('description', 'No description.')
                lines.append(f'- **{name}**: {desc}')
                skill_count += 1

        if skill_count == 0:
            return ''

        return '\n'.join(lines)

    def build_system_prompt(self, user_id: str, include_memory: bool = True) -> str:
        """
        Assemble the full system prompt from workspace documents.

        Layers (Architectural order):
        1. Identity — who Brian is
        2. Soul — personality, values, communication style
        3. User Profile — user preferences
        4. Agent Rules — behavioral guidelines
        5. Agent Summary — capabilities registry (metadata only)
        6. Skills Summary — available skills (metadata only)
        7. Memory — long-term persistent facts
        8. Daily Notes — recent activity log (last 3 days)
        """
        parts = []

        # 1-4: Core workspace docs (always loaded)
        for doc_type in ['identity', 'soul', 'user_profile', 'agent_rules']:
            content = self._get_doc_content(user_id, doc_type)
            if content:
                parts.append(content)

        # 5. Agent capabilities summary (metadata only)
        agent_summary = self._get_agent_summary(user_id)
        if agent_summary:
            parts.append(agent_summary)

        # 6. Skills summary (metadata only)
        skills_summary = self._get_skills_summary(user_id)
        if skills_summary:
            parts.append(skills_summary)

        if include_memory:
            # 7. Memory (always loaded)
            memory = self._get_doc_content(user_id, 'memory')
            if memory:
                parts.append(memory)

            # 8. Daily Notes (last 3 days)
            notes = self._get_recent_daily_notes(user_id, days=3)
            if notes:
                parts.append(notes)

        return '\n\n---\n\n'.join(parts) + '\n\n---\n\n' + self._get_meta_skill_instruction() if parts else ''

    def _get_meta_skill_instruction(self) -> str:
        """Return the meta-skill instruction block for system prompt."""
        return """## Skill Creation

When a user teaches you a reusable process, checklist, SOP, or workflow:
1. Recognize it as a potential **skill** worth saving.
2. Ask the user: "Would you like me to save this as a skill for future use?"
3. If they confirm, use the `create_skill_from_conversation` tool with:
   - `skill_name`: a short, lowercase, underscore-separated identifier
   - `description`: a one-line summary
   - `content`: the full instructions in markdown format

Once saved, the skill will appear in your Available Skills list and you can
reference it in future conversations without the user having to re-explain."""

    def get_agent_prompt(self, user_id: str, agent_name: str) -> str:
        """
        Load the full prompt for a specific agent (lazy loading).
        Only called after the router selects an agent.
        """
        ref = self._db.collection('workspaces').document(user_id) \
            .collection('agent_registry').document(agent_name)
        snap = ref.get()
        if snap.exists:
            data = snap.to_dict()
            return data.get('prompt_content', '') if data else ''
        return ''

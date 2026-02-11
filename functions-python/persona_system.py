from typing import Dict, Any, List
import logging

class PersonaSystem:
    """
    Manages character personas and their states.
    """
    def __init__(self):
        self.personas: Dict[str, Any] = {}
        self.logger = logging.getLogger(__name__)

    def register_persona(self, persona_id: str, data: Dict[str, Any]):
        """Registers a new persona definition."""
        self.personas[persona_id] = {
            "id": persona_id,
            "name": data.get("name", "Unknown"),
            "role": data.get("role", "assistant"),
            "voice_settings": data.get("voice_settings", {}),
            "traits": data.get("traits", []),
            "history": []  # Conversation history for this persona
        }
        self.logger.info(f"Registered persona: {persona_id}")

    def get_persona(self, persona_id: str) -> Dict[str, Any]:
        """Retrieves a persona by ID."""
        return self.personas.get(persona_id)

    def update_history(self, persona_id: str, message: Dict[str, Any]):
        """Updates the conversation history for a persona."""
        if persona_id in self.personas:
            self.personas[persona_id]["history"].append(message)
            # Keep history manageable - maybe simple truncation for now
            if len(self.personas[persona_id]["history"]) > 20: 
                self.personas[persona_id]["history"].pop(0)

    def get_system_prompt(self, persona_id: str) -> str:
        """Generates a system prompt based on persona traits."""
        p = self.get_persona(persona_id)
        if not p:
            return ""
        
        traits = ", ".join(p["traits"])
        return f"You are {p['name']}. Role: {p['role']}. Traits: {traits}."

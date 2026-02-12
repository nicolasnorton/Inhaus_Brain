from typing import Dict, Any, List, Optional
import logging
import random
from node_parser import NodeParser
from persona_system import PersonaSystem
from gemini_client import GeminiClient

class TurnTakingSystem:
    """
    Decides which persona should speak next.
    """
    def __init__(self, client: Optional[GeminiClient]):
        self.client = client
        self.logger = logging.getLogger(__name__)

    def select_next_speaker(self, current_speaker_id: str, personas: Dict[str, Any], history: List[Dict[str, Any]]) -> str:
        """
        Determines the next speaker ID.
        Current strategy: Simple round-robin fallback or LLM-based if feasible.
        """
        persona_ids = list(personas.keys())
        if not persona_ids:
            return "unknown"
            
        # 1. If only one persona, it's them (or user)
        if len(persona_ids) == 1:
            return persona_ids[0]

        # 2. Basic heuristic: Round robin for now to save tokens/latency
        # In a real DialogLab port, this would be an LLM call:
        # "Given the transcript, who speaks next? [Alice, Bob]"
        try:
            current_idx = persona_ids.index(current_speaker_id) if current_speaker_id in persona_ids else -1
            next_idx = (current_idx + 1) % len(persona_ids)
            return persona_ids[next_idx]
        except ValueError:
            return persona_ids[0]

class DialogueManager:
    """
    Orchestrates the dialogue, managing state, turns, and LLM calls.
    """
    def __init__(self):
        self.parser = NodeParser()
        self.persona_system = PersonaSystem()
        self.logger = logging.getLogger(__name__)
        # Ensure we can use the existing client
        try:
            self.gemini_client = GeminiClient()
        except:
             # Fallback or mock for testing if env vars missing
            self.gemini_client = None
            
        self.turn_taker = TurnTakingSystem(self.gemini_client)

    def initialize_session(self, flow_definition: Dict[str, Any], personas_data: List[Dict[str, Any]]):
        """Initializes a new dialogue session."""
        self.nodes = self.parser.parse_flow(flow_definition)
        self.current_node_id = self.parser.get_start_node(flow_definition)
        
        for p_data in personas_data:
            pid = p_data.get("id")
            if pid:
                self.persona_system.register_persona(pid, p_data)
        
        return {
            "status": "initialized",
            "current_node": self.current_node_id,
            "personas_loaded": len(personas_data)
        }

    def process_turn(self, session_state: Dict[str, Any], user_input: str) -> Dict[str, Any]:
        """
        Processes a single turn of dialogue.
        
        Args:
            session_state: The current state of the client's session (stateless server).
            user_input: The user's message/action.
            
        Returns:
            Updated state and the response(s).
        """
        current_node_id = session_state.get("current_node_id")
        current_node = self.nodes.get(current_node_id)
        
        # 1. Update Persona History with User Input (if applicable)
        # For now, we treat user input as a global event
        

        # 2. Determine Next Speaker
        node_speaker = current_node.get("speaker_id")
        if node_speaker and node_speaker in self.persona_system.personas:
             next_speaker_id = node_speaker
        else:
            last_speaker = session_state.get("last_speaker_id")
            next_speaker_id = self.turn_taker.select_next_speaker(
                last_speaker, 
                self.persona_system.personas,
                [] # history stub
            )

        
        # 3. Generate Response
        system_prompt = self.persona_system.get_system_prompt(next_speaker_id)
        
        # Build prompt
        prompt = f"User said: {user_input}\nContext: You are at node {current_node_id}. Node info: {current_node}"
        
        response_text = "ERROR: Gemini Client not available"
        if self.gemini_client:
            try:
                # Using the generate_content method from existing client
                resp = self.gemini_client.generate_content(
                    model_name="gemini-1.5-flash", # Defaulting
                    prompt=prompt,
                    system_instruction=system_prompt
                )
                # Serialize to get clean text
                serialized = self.gemini_client._serialize_response(resp)
                if serialized.get("candidates") and serialized["candidates"][0].get("content") and serialized["candidates"][0]["content"].get("parts"):
                     response_text = serialized["candidates"][0]["content"]["parts"][0].get("text", "")
                else:
                    response_text = "..."
                    
            except Exception as e:
                self.logger.error(f"LLM Error: {e}")
                response_text = f"I'm having trouble thinking right now. ({e})"

        # 4. Update History
        self.persona_system.update_history(next_speaker_id, {"role": "model", "parts": [{"text": response_text}]})

        return {
            "response_text": response_text,
            "speaker_id": next_speaker_id,
            "next_node_id": current_node.get("next") if current_node else None, 
            "session_state": {
                "current_node_id": current_node.get("next") if current_node else current_node_id,
                "last_speaker_id": next_speaker_id
            }
        }

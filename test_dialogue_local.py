import sys
import os

# Add functions-python to path
sys.path.append(os.path.join(os.getcwd(), 'functions-python'))


from dialogue_manager import DialogueManager


def test_dialogue_logic():
    print("Testing Dialogue Manager...")
    manager = DialogueManager()
    
    # 1. Define Valid Flow
    flow = {
        "start_node_id": "node_1",
        "nodes": [
            {
                "id": "node_1",
                "type": "response",
                "text": "Hello, welcome to simulation.",
                "speaker_id": "persona_a",
                "next": "node_2"
            },
            {
                "id": "node_2",
                "type": "response",
                "text": "How can I help you?",
                "speaker_id": "persona_b",
                "next": "node_1" # Loop back
            }
        ]
    }
    
    personas = [
        {"id": "persona_a", "name": "Alice", "role": "Greeter"},
        {"id": "persona_b", "name": "Bob", "role": "Assistant"}
    ]
    
    # 2. Test Init
    print("\n--- Testing Init ---")
    init_res = manager.initialize_session(flow, personas)
    print(f"Init Result: {init_res}")
    assert init_res["status"] == "initialized"
    
    # 3. Test Turn
    print("\n--- Testing Turn ---")
    session_state = {"current_node_id": "node_1", "last_speaker_id": "persona_b"}
    
    # Mock Gemini Client if needed, but Manager handles missing client gracefully
    turn_res = manager.process_turn(session_state, "Hi there!")
    print(f"Turn Result: {turn_res}")
    
    assert turn_res["session_state"]["current_node_id"] == "node_2"
    # Turn taker simple logic: A -> B -> A
    # We passed last_speaker=persona_b, so simple logic (index+1) should be:
    # ids: [persona_a, persona_b]
    # last: b (index 1) -> next (index 0) = persona_a
    # Wait, my logic was generic round robin.
    
    print("\nTest Complete!")

if __name__ == "__main__":
    test_dialogue_logic()

from typing import Dict, Any, List, Optional
import logging

class NodeParser:
    """
    Parses dialogue nodes from a raw dictionary (e.g. from JSON/YAML).
    """
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def parse_flow(self, flow_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates and parses a full dialogue flow.
        Returns a dictionary of node_id -> node_data.
        """
        if "nodes" not in flow_data:
            raise ValueError("Flow data must contain 'nodes' key.")
        
        parsed_nodes = {}
        for node in flow_data["nodes"]:
            node_id = node.get("id")
            if not node_id:
                continue
            
            # Basic validation
            if "type" not in node:
                self.logger.warning(f"Node {node_id} missing 'type'. Defaulting to 'response'.")
                node["type"] = "response"
            
            parsed_nodes[node_id] = node
            
        return parsed_nodes

    def get_start_node(self, flow_data: Dict[str, Any]) -> Optional[str]:
        """Returns the ID of the start node, if defined."""
        return flow_data.get("start_node_id")

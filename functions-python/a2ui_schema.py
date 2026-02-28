from pydantic import BaseModel, Field
from typing import Any, Dict, List, Optional, Literal

class ComponentProperty(BaseModel):
    """A single property definition in an A2UI component."""
    type: str
    description: Optional[str] = None
    items: Optional[Dict[str, Any]] = None
    enum: Optional[List[str]] = None

class ComponentParameters(BaseModel):
    """The parameters schema for an A2UI component."""
    type: Literal["object"] = "object"
    properties: Dict[str, ComponentProperty]
    required: Optional[List[str]] = None

class A2UIComponentDef(BaseModel):
    """A definition of an A2UI component as provided to the LLM."""
    name: str = Field(pattern=r'^[a-zA-Z_][a-zA-Z0-9_]*$')
    description: str
    parameters: ComponentParameters

class CatalogDefinition(BaseModel):
    """The full catalog of available A2UI components."""
    components: List[A2UIComponentDef]

class BeginRendering(BaseModel):
    """The A2UI beginRendering message payload."""
    type: Literal["beginRendering"] = "beginRendering"
    surfaceId: str
    fallbackText: str

class SurfaceUpdate(BaseModel):
    """The A2UI surfaceUpdate message payload."""
    type: Literal["surfaceUpdate"] = "surfaceUpdate"
    surfaceId: str
    component: str
    data: Dict[str, Any]

class DeleteSurface(BaseModel):
    """The A2UI deleteSurface message payload."""
    type: Literal["deleteSurface"] = "deleteSurface"
    surfaceId: str

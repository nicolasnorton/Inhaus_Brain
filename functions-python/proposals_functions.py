"""
proposalsLM — Python Cloud Functions (Gemini SDK)

Drop-in replacement for the 3 Anthropic-powered endpoints from the
Asset-Manager Express backend.  Uses google-genai (≥1.0.0), the same
SDK already in functions-python/requirements.txt.

Endpoints:
  1. tune_proforma    — AI text → structured quote
  2. import_packages  — AI text → list of packages
  3. proposals_chat   — general-purpose chat assistant

Integration:
  Register these functions in your existing functions-python/main.py:

      from proposals_functions import tune_proforma, import_packages, proposals_chat
"""

from __future__ import annotations

import json
import os
import re
import traceback

from firebase_functions import https_fn, options
from google import genai
from google.genai import types

# ──────────────────────────────────────────────────────────────────────
# Client initialisation  (mirrors gemini_client.py dual-client pattern)
# ──────────────────────────────────────────────────────────────────────

_client: genai.Client | None = None


def _get_client() -> genai.Client:
    """
    Lazily initialise the Gemini client.
    - Local / emulator  → uses GOOGLE_API_KEY (AI Studio)
    - Cloud Functions    → uses ADC (Vertex AI)
    """
    global _client
    if _client is not None:
        return _client

    api_key = os.environ.get("GOOGLE_API_KEY")
    if api_key:
        _client = genai.Client(api_key=api_key)
    else:
        gcp_project = os.environ.get("GCLOUD_PROJECT") or os.environ.get("GCP_PROJECT")
        _client = genai.Client(
            vertexai=True,
            project=gcp_project,
            location=os.environ.get("CLOUD_FUNCTIONS_REGION", "us-central1"),
        )
    return _client


# Default model — matches Inhaus_Brain's routing preference
_DEFAULT_MODEL = os.environ.get("PROPOSALS_MODEL", "gemini-3-flash-preview")

# ──────────────────────────────────────────────────────────────────────
# Shared helpers
# ──────────────────────────────────────────────────────────────────────

def _extract_json(text: str):
    """Strip markdown fences and parse JSON from model output."""
    cleaned = re.sub(r"```(?:json)?\s*", "", text)
    cleaned = cleaned.replace("```", "").strip()
    return json.loads(cleaned)


def _cors_headers():
    """Standard CORS headers for Flutter web / dev builds."""
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }


def _error_response(msg: str, status: int = 500):
    return https_fn.Response(
        json.dumps({"error": msg}),
        status=status,
        headers={**_cors_headers(), "Content-Type": "application/json"},
    )


def _json_response(data, status: int = 200):
    return https_fn.Response(
        json.dumps(data, ensure_ascii=False),
        status=status,
        headers={**_cors_headers(), "Content-Type": "application/json"},
    )


# ──────────────────────────────────────────────────────────────────────
# 1. tune_proforma  —  POST { "text": "..." }
# ──────────────────────────────────────────────────────────────────────

TUNE_SYSTEM_PROMPT = """Eres un asistente de INHAUS Estudio Creativo (Cuenca, Ecuador) especializado en convertir textos de proformas/cotizaciones en datos estructurados.

Analiza el texto proporcionado de una proforma y extrae TODA la información para crear una cotización completa. Responde con un objeto JSON con esta estructura exacta:

{
  "client": "Nombre del cliente (si se encuentra en el texto, sino vacío)",
  "discount": 0,
  "applyIva": true,
  "items": [
    {
      "id": "identificador-en-kebab-case-unico",
      "name": "Nombre del Paquete/Servicio",
      "category": "Una de las categorías válidas",
      "price": 0,
      "billing": "Pago único" o "Pago mensual" o "Cada dos meses" o "Trimestral" o "Semestral" o "Anual" o "",
      "sections": [
        { "title": "TÍTULO DE SECCIÓN EN MAYÚSCULAS", "content": "Contenido descriptivo con entregables y detalles" }
      ]
    }
  ]
}

Categorías válidas: "Redes Sociales", "Producción Audiovisual", "Diseño Web", "Branding", "Pauta Publicitaria", "Diseño Gráfico", "Otro"

Reglas:
- Extrae el nombre del cliente si aparece en la proforma
- Extrae todos los servicios/paquetes como items separados
- Extrae el precio de cada servicio si está disponible, si no usa 0
- Si hay descuento mencionado, extráelo como porcentaje
- Si se menciona IVA, ajusta applyIva según corresponda (default true)
- Agrupa entregables relacionados en secciones lógicas dentro de cada item
- Usa ids únicos y descriptivos en kebab-case
- Si hay variantes del mismo servicio (ej: básico, premium), crea items separados
- El contenido de las secciones debe ser descriptivo y detallado
- Si el texto menciona facturación mensual, billing debe ser "Pago mensual"
- Responde SOLO con un objeto JSON válido, sin texto adicional ni markdown"""


@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["POST", "OPTIONS"]),
    memory=options.MemoryOption.MB_512,
    timeout_sec=120,
)
def tune_proforma(req: https_fn.Request) -> https_fn.Response:
    """Convert raw proforma text into a structured quote using Gemini."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        body = req.get_json(silent=True) or {}
        text = body.get("text", "")
        if not text or len(text) < 10:
            return _error_response("Texto inválido — se necesitan al menos 10 caracteres", 400)

        client = _get_client()
        response = client.models.generate_content(
            model=_DEFAULT_MODEL,
            contents=text,
            config=types.GenerateContentConfig(
                system_instruction=TUNE_SYSTEM_PROMPT,
                max_output_tokens=8192,
                temperature=0.2,
                response_mime_type="application/json",
            ),
        )

        result = _extract_json(response.text)

        # Validate minimal shape
        if "items" not in result:
            return _error_response("No se pudo interpretar la proforma", 422)

        # Ensure defaults
        result.setdefault("client", "")
        result.setdefault("discount", 0)
        result.setdefault("applyIva", True)

        return _json_response(result)

    except json.JSONDecodeError:
        return _error_response("No se pudo interpretar la proforma — respuesta no JSON", 422)
    except Exception as e:
        traceback.print_exc()
        return _error_response(f"Error al procesar la proforma: {str(e)}")


# ──────────────────────────────────────────────────────────────────────
# 2. import_packages  —  POST { "text": "..." }
# ──────────────────────────────────────────────────────────────────────

IMPORT_SYSTEM_PROMPT = """Eres un asistente de INHAUS Estudio Creativo (Cuenca, Ecuador) especializado en extraer paquetes/servicios de proformas y documentos.

Analiza el texto proporcionado y extrae TODOS los paquetes, productos o servicios que encuentres. Para cada uno genera un objeto JSON con esta estructura exacta:

{
  "slug": "identificador-en-kebab-case-unico",
  "name": "Nombre del Paquete/Servicio",
  "category": "Una de las categorías válidas",
  "price": 0,
  "billing": "Pago único / Pago mensual / Cada dos meses / Trimestral / Semestral / Anual (o vacío)",
  "sections": [
    { "title": "TÍTULO DE SECCIÓN EN MAYÚSCULAS", "content": "Contenido descriptivo con entregables y detalles" }
  ]
}

Categorías válidas: "Redes Sociales", "Producción Audiovisual", "Diseño Web", "Branding", "Pauta Publicitaria", "Diseño Gráfico", "Otro"

Reglas:
- Extrae el precio si está disponible, si no usa 0
- Agrupa entregables relacionados en secciones lógicas
- Usa slugs únicos y descriptivos en kebab-case
- Si hay variantes del mismo servicio (ej: básico, premium), crea paquetes separados
- El contenido de las secciones debe ser descriptivo y detallado
- Responde SOLO con un array JSON válido, sin texto adicional ni markdown
- Si no encuentras paquetes claros, agrupa la información en paquetes lógicos basándote en el contexto"""


@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["POST", "OPTIONS"]),
    memory=options.MemoryOption.MB_512,
    timeout_sec=120,
)
def import_packages(req: https_fn.Request) -> https_fn.Response:
    """Extract packages/services from raw text using Gemini."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        body = req.get_json(silent=True) or {}
        text = body.get("text", "")
        if not text or len(text) < 10:
            return _error_response("Texto inválido — se necesitan al menos 10 caracteres", 400)

        client = _get_client()
        response = client.models.generate_content(
            model=_DEFAULT_MODEL,
            contents=text,
            config=types.GenerateContentConfig(
                system_instruction=IMPORT_SYSTEM_PROMPT,
                max_output_tokens=8192,
                temperature=0.2,
                response_mime_type="application/json",
            ),
        )

        packages = _extract_json(response.text)

        if not isinstance(packages, list):
            return _error_response(
                "No se pudieron extraer paquetes del texto proporcionado", 422
            )

        return _json_response({"packages": packages})

    except json.JSONDecodeError:
        return _error_response(
            "No se pudieron extraer paquetes del texto proporcionado", 422
        )
    except Exception as e:
        traceback.print_exc()
        return _error_response(f"Error al importar: {str(e)}")


# ──────────────────────────────────────────────────────────────────────
# 3. proposals_chat  —  POST { "messages": [...], "system": "..." }
# ──────────────────────────────────────────────────────────────────────

PROPOSALS_CHAT_SYSTEM = """Eres el asistente de cotizaciones de INHAUS Estudio Creativo.
Ayudas al equipo a crear, ajustar y optimizar cotizaciones para clientes.
Responde siempre en español ecuatoriano profesional.
Puedes sugerir precios, describir paquetes y ayudar a estructurar propuestas.
Sé conciso y directo."""


@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["POST", "OPTIONS"]),
    memory=options.MemoryOption.MB_512,
    timeout_sec=60,
)
def proposals_chat(req: https_fn.Request) -> https_fn.Response:
    """General-purpose quotation assistant chat powered by Gemini."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        body = req.get_json(silent=True) or {}
        messages = body.get("messages", [])
        system = body.get("system", PROPOSALS_CHAT_SYSTEM)

        if not messages:
            return _error_response("Se requiere al menos un mensaje", 400)

        # Convert chat messages to Gemini Content format
        contents: list[types.Content] = []
        for msg in messages:
            role = msg.get("role", "user")
            # Gemini uses "user" and "model" (not "assistant")
            gemini_role = "model" if role == "assistant" else "user"
            contents.append(
                types.Content(
                    role=gemini_role,
                    parts=[types.Part.from_text(text=msg.get("content", ""))],
                )
            )

        client = _get_client()
        response = client.models.generate_content(
            model=_DEFAULT_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system,
                max_output_tokens=8192,
                temperature=0.7,
            ),
        )

        return _json_response({"content": response.text})

    except Exception as e:
        traceback.print_exc()
        return _error_response(f"Chat failed: {str(e)}")

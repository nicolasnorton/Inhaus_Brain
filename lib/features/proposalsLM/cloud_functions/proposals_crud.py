"""
proposalsLM — Firestore CRUD for Quotes, Packages, and Styles

These Cloud Functions replace the Express + PostgreSQL endpoints
with Firebase-native Firestore persistence.  No Replit or Neon needed.

Collections:
  - proposals_quotes
  - proposals_packages
  - proposals_styles

Register in your main.py alongside proposals_functions.py:

    from proposals_crud import (
        get_quotes, create_quote, delete_quote,
        get_packages, create_package, update_package, delete_package,
        get_deleted_packages, restore_package,
        get_styles, create_style, update_style, delete_style,
        upload_document,
    )
"""

from __future__ import annotations

import json
import os
import traceback
from datetime import datetime, timezone

from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn, options

# Ensure firebase_admin is initialised (idempotent if already done in main.py)
try:
    initialize_app()
except ValueError:
    pass  # already initialised

_db = firestore.client()

# Collection names
_QUOTES = "proposals_quotes"
_PACKAGES = "proposals_packages"
_STYLES = "proposals_styles"

# ──────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────

def _json_response(data, status: int = 200):
    return https_fn.Response(
        json.dumps(data, ensure_ascii=False, default=str),
        status=status,
        headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    )


def _error(msg: str, status: int = 500):
    return _json_response({"error": msg}, status=status)


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


# ──────────────────────────────────────────────────────────────────────
# Quotes
# ──────────────────────────────────────────────────────────────────────

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["GET", "POST", "DELETE", "OPTIONS"]),
)
def quotes_api(req: https_fn.Request) -> https_fn.Response:
    """Unified quotes endpoint — method-based routing."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        if req.method == "GET":
            docs = _db.collection(_QUOTES).order_by("createdAt", direction=firestore.Query.DESCENDING).stream()
            return _json_response([{**d.to_dict(), "id": d.id} for d in docs])

        if req.method == "POST":
            data = req.get_json(silent=True) or {}
            data["createdAt"] = _now_iso()
            ref = _db.collection(_QUOTES).add(data)
            return _json_response({**data, "id": ref[1].id}, status=201)

        if req.method == "DELETE":
            doc_id = req.args.get("id") or req.path.strip("/").split("/")[-1]
            _db.collection(_QUOTES).document(doc_id).delete()
            return _json_response({"ok": True}, status=200)

    except Exception as e:
        traceback.print_exc()
        return _error(str(e))


# ──────────────────────────────────────────────────────────────────────
# Packages
# ──────────────────────────────────────────────────────────────────────

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]),
)
def packages_api(req: https_fn.Request) -> https_fn.Response:
    """Unified packages endpoint."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        path_parts = [p for p in req.path.strip("/").split("/") if p]
        slug = path_parts[-1] if len(path_parts) > 0 and req.method in ("PUT", "DELETE") else None
        is_deleted = "deleted" in req.path
        is_restore = "restore" in req.path

        # GET /packages/deleted
        if req.method == "GET" and is_deleted:
            docs = _db.collection(_PACKAGES).where("deletedAt", "!=", None).stream()
            return _json_response([{**d.to_dict(), "id": d.id} for d in docs])

        # GET /packages
        if req.method == "GET":
            docs = _db.collection(_PACKAGES).where("deletedAt", "==", None).stream()
            return _json_response([{**d.to_dict(), "id": d.id} for d in docs])

        # POST /packages/:slug/restore
        if req.method == "POST" and is_restore:
            slug = path_parts[-2] if len(path_parts) >= 2 else None
            if not slug:
                return _error("slug requerido", 400)
            docs = list(_db.collection(_PACKAGES).where("slug", "==", slug).limit(1).stream())
            if not docs:
                return _error("Paquete no encontrado", 404)
            docs[0].reference.update({"deletedAt": None, "deletedBy": None})
            return _json_response({"ok": True})

        # POST /packages
        if req.method == "POST":
            data = req.get_json(silent=True) or {}
            data["createdAt"] = _now_iso()
            data.setdefault("deletedAt", None)
            data.setdefault("deletedBy", None)
            ref = _db.collection(_PACKAGES).add(data)
            return _json_response({**data, "id": ref[1].id}, status=201)

        # PUT /packages/:slug
        if req.method == "PUT" and slug:
            data = req.get_json(silent=True) or {}
            docs = list(_db.collection(_PACKAGES).where("slug", "==", slug).limit(1).stream())
            if not docs:
                return _error("Paquete no encontrado", 404)
            docs[0].reference.update(data)
            return _json_response({**docs[0].to_dict(), **data, "id": docs[0].id})

        # DELETE /packages/:slug  (soft delete)
        if req.method == "DELETE" and slug:
            data = req.get_json(silent=True) or {}
            master_key = data.get("masterKey", "")
            deleted_by = data.get("deletedBy", "")
            expected_key = os.environ.get("MASTER_DELETE_KEY", "")
            if master_key != expected_key:
                return _error("Clave maestra incorrecta", 403)
            docs = list(_db.collection(_PACKAGES).where("slug", "==", slug).limit(1).stream())
            if not docs:
                return _error("Paquete no encontrado", 404)
            docs[0].reference.update({
                "deletedAt": _now_iso(),
                "deletedBy": deleted_by,
            })
            return _json_response({"ok": True})

    except Exception as e:
        traceback.print_exc()
        return _error(str(e))


# ──────────────────────────────────────────────────────────────────────
# Styles
# ──────────────────────────────────────────────────────────────────────

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]),
)
def styles_api(req: https_fn.Request) -> https_fn.Response:
    """Unified styles endpoint."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        path_parts = [p for p in req.path.strip("/").split("/") if p]
        style_id = path_parts[-1] if len(path_parts) > 0 and req.method in ("PUT", "DELETE") else None

        if req.method == "GET":
            docs = _db.collection(_STYLES).stream()
            return _json_response([{**d.to_dict(), "id": d.id} for d in docs])

        if req.method == "POST":
            data = req.get_json(silent=True) or {}
            data["createdAt"] = _now_iso()
            data.setdefault("isDefault", False)
            data.setdefault("referenceImages", [])
            ref = _db.collection(_STYLES).add(data)
            return _json_response({**data, "id": ref[1].id}, status=201)

        if req.method == "PUT" and style_id:
            data = req.get_json(silent=True) or {}
            ref = _db.collection(_STYLES).document(style_id)
            doc = ref.get()
            if not doc.exists:
                return _error("Estilo no encontrado", 404)
            ref.update(data)
            return _json_response({**doc.to_dict(), **data, "id": style_id})

        if req.method == "DELETE" and style_id:
            ref = _db.collection(_STYLES).document(style_id)
            doc = ref.get()
            if not doc.exists:
                return _error("Estilo no encontrado", 404)
            if doc.to_dict().get("isDefault"):
                return _error("No se puede eliminar el estilo por defecto", 400)
            ref.delete()
            return _json_response({"ok": True})

    except Exception as e:
        traceback.print_exc()
        return _error(str(e))


# ──────────────────────────────────────────────────────────────────────
# Upload document (text extraction from PDF / DOCX / TXT)
# ──────────────────────────────────────────────────────────────────────

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["POST", "OPTIONS"]),
    memory=options.MemoryOption.MB_512,
)
def upload_document(req: https_fn.Request) -> https_fn.Response:
    """Extract text from uploaded PDF, DOCX or TXT files."""
    if req.method == "OPTIONS":
        return _json_response({})

    try:
        if not req.files:
            return _error("No se proporcionó archivo", 400)

        file = next(iter(req.files.values()))
        filename = file.filename or ""
        data = file.read()

        if filename.endswith(".txt"):
            text = data.decode("utf-8", errors="replace")

        elif filename.endswith(".docx"):
            try:
                import docx
                from io import BytesIO
                doc = docx.Document(BytesIO(data))
                text = "\n".join(p.text for p in doc.paragraphs)
            except ImportError:
                return _error("python-docx no instalado en el servidor", 500)

        elif filename.endswith(".pdf"):
            try:
                import pypdf
                from io import BytesIO
                reader = pypdf.PdfReader(BytesIO(data))
                text = "\n".join(page.extract_text() or "" for page in reader.pages)
            except ImportError:
                return _error("pypdf no instalado en el servidor", 500)

        else:
            return _error("Formato no soportado. Use .pdf, .docx o .txt", 400)

        if not text.strip():
            return _error("El archivo está vacío o no se pudo extraer texto", 400)

        return _json_response({"text": text})

    except Exception as e:
        traceback.print_exc()
        return _error(f"Error al procesar archivo: {str(e)}")

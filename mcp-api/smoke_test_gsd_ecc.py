#!/usr/bin/env python3
"""
BrainWeave GSD + ECC Smoke Test
Tests all 7 new MCP endpoints against a deployed/local instance.

Usage:
    # Against staging:
    python3 smoke_test_gsd_ecc.py --base-url https://brainweave-mcp-1096509611056.us-central1.run.app --token YOUR_FIREBASE_ID_TOKEN

    # Against local:
    python3 smoke_test_gsd_ecc.py --base-url http://localhost:8080 --token YOUR_FIREBASE_ID_TOKEN

Requirements:
    - The MCP API must be deployed with GSD_ECC_ENABLED=true
    - A valid Firebase ID token is required for auth
"""

import argparse
import json
import sys
import time
import requests

# ANSI colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"
BOLD = "\033[1m"


def test_endpoint(name, method, url, headers, json_body=None, expect_status=200):
    """Test a single endpoint and return pass/fail."""
    try:
        start = time.time()
        if method == "GET":
            resp = requests.get(url, headers=headers, timeout=30)
        else:
            resp = requests.post(url, headers=headers, json=json_body, timeout=60)
        elapsed = time.time() - start

        passed = resp.status_code == expect_status
        status_icon = f"{GREEN}✓{RESET}" if passed else f"{RED}✗{RESET}"

        print(f"  {status_icon} {name}: {resp.status_code} ({elapsed:.1f}s)")

        if not passed:
            print(f"    Expected {expect_status}, got {resp.status_code}")
            print(f"    Body: {resp.text[:200]}")

        return passed, resp
    except Exception as e:
        print(f"  {RED}✗{RESET} {name}: EXCEPTION — {e}")
        return False, None


def main():
    parser = argparse.ArgumentParser(description="BrainWeave GSD+ECC Smoke Test")
    parser.add_argument("--base-url", required=True, help="MCP API base URL")
    parser.add_argument("--token", required=True, help="Firebase ID token")
    parser.add_argument("--skip-disabled", action="store_true",
                        help="Skip testing that endpoints return 404 when disabled")
    args = parser.parse_args()

    base = args.base_url.rstrip("/")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {args.token}",
    }

    total = 0
    passed = 0

    print(f"\n{BOLD}═══ BrainWeave GSD+ECC Smoke Test ═══{RESET}\n")
    print(f"Target: {base}\n")

    # ── 0. Health Check ──────────────────────────────────────
    print(f"{BOLD}▸ Health Check{RESET}")
    ok, resp = test_endpoint("Health", "GET", f"{base}/health", {})
    total += 1; passed += int(ok)
    if ok and resp:
        data = resp.json()
        gsd_ecc = data.get("gsd_ecc_enabled", False)
        print(f"    Version: {data.get('version', '?')}")
        print(f"    GSD_ECC_ENABLED: {gsd_ecc}")
        if not gsd_ecc:
            print(f"\n{YELLOW}⚠  GSD_ECC_ENABLED is false — new endpoints will return 404{RESET}")
            print(f"    Set env var GSD_ECC_ENABLED=true and redeploy.\n")
            if not args.skip_disabled:
                print(f"{BOLD}Testing that new endpoints correctly return 404 when disabled...{RESET}\n")

    # ── 1. Plan Phase ────────────────────────────────────────
    print(f"\n{BOLD}▸ F1: Planning / Verification{RESET}")
    ok, resp = test_endpoint(
        "Plan Phase",
        "POST",
        f"{base}/brainweave_plan_phase",
        headers,
        json_body={
            "requirements": "Build a user login form with email and password validation",
            "context": "Existing Flutter app with Firebase Auth",
            "phase_number": 1,
        },
    )
    total += 1; passed += int(ok)

    # ── 2. Verify Requirements ───────────────────────────────
    ok, resp = test_endpoint(
        "Verify Requirements",
        "POST",
        f"{base}/brainweave_verify_requirements",
        headers,
        json_body={
            "plan_xml": "<plan phase='1'><task id='1'><name>Login Form</name></task></plan>",
            "requirements": "Must have email and password fields with validation",
        },
    )
    total += 1; passed += int(ok)

    # ── 3. Quality Gate ──────────────────────────────────────
    ok, resp = test_endpoint(
        "Quality Gate",
        "POST",
        f"{base}/brainweave_quality_gate",
        headers,
        json_body={
            "output": "Created a login form with email field, password field, and submit button.",
            "acceptance_criteria": [
                "Has email input with validation",
                "Has password input with min 8 chars",
                "Has submit button",
            ],
            "task_name": "login_form",
        },
    )
    total += 1; passed += int(ok)

    # ── 4. Load Minimal Context ──────────────────────────────
    print(f"\n{BOLD}▸ F2: Persistent Context + Instincts{RESET}")
    ok, _ = test_endpoint(
        "Load Minimal Context",
        "POST",
        f"{base}/brainweave_load_minimal_context",
        headers,
    )
    total += 1; passed += int(ok)

    # ── 5. Instinct Status ───────────────────────────────────
    ok, _ = test_endpoint(
        "Instinct Status",
        "POST",
        f"{base}/brainweave_instinct_status",
        headers,
    )
    total += 1; passed += int(ok)

    # ── 6. Evolve ────────────────────────────────────────────
    ok, _ = test_endpoint(
        "Evolve",
        "POST",
        f"{base}/brainweave_evolve",
        headers,
    )
    total += 1; passed += int(ok)

    # ── 7. Map Knowledge Base ────────────────────────────────
    print(f"\n{BOLD}▸ F6: Brownfield Mapping{RESET}")
    ok, _ = test_endpoint(
        "Map Knowledge Base",
        "POST",
        f"{base}/brainweave_map_knowledge_base",
        headers,
    )
    total += 1; passed += int(ok)

    # ── Summary ──────────────────────────────────────────────
    print(f"\n{BOLD}═══ Results ═══{RESET}")
    color = GREEN if passed == total else (YELLOW if passed > total // 2 else RED)
    print(f"{color}{passed}/{total} tests passed{RESET}\n")

    if passed < total:
        sys.exit(1)


if __name__ == "__main__":
    main()

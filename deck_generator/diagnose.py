"""Find out which part of the Gemini call is slow or failing.

Run:  python3 diagnose.py
"""

import os
import sys
import time

from google import genai
from google.genai import types

MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.8-flash")
TIMEOUT_MS = 25_000

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    sys.exit("GEMINI_API_KEY is not set.")

client = genai.Client(
    api_key=api_key,
    http_options=types.HttpOptions(timeout=TIMEOUT_MS),
)


def timed(label, fn):
    print(f"\n[{label}]")
    start = time.time()
    try:
        result = fn()
        print(f"  OK in {time.time() - start:.1f}s")
        return result
    except Exception as err:
        print(f"  FAILED after {time.time() - start:.1f}s")
        print(f"  {type(err).__name__}: {str(err)[:300]}")
        return None


# 1. Can we reach the API at all, and is the key valid?
models = timed("1. list models (auth + connectivity)", lambda: list(client.models.list()))
if models:
    usable = [m.name for m in models if "generateContent" in (m.supported_actions or [])]
    print(f"  {len(usable)} models support generateContent")
    for name in usable[:15]:
        marker = "  <-- current" if name.endswith(MODEL) else ""
        print(f"    {name}{marker}")

# 2. Simplest possible generation.
timed(
    f"2. plain generate_content on {MODEL}",
    lambda: client.models.generate_content(model=MODEL, contents="Say hi.").text,
)

# 3. JSON mode, which the real script uses.
timed(
    "3. same call in JSON mode",
    lambda: client.models.generate_content(
        model=MODEL,
        contents='Reply with JSON: {"ok": true}',
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    ).text,
)

# 4. JSON mode with thinking turned down.
timed(
    "4. JSON mode + thinking_level=low",
    lambda: client.models.generate_content(
        model=MODEL,
        contents='Reply with JSON: {"ok": true}',
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            thinking_config=types.ThinkingConfig(thinking_level="low"),
        ),
    ).text,
)

print("\nDone.")

"""Standalone deck generator for the Imposter game (Task 1 of the decomposition).

Takes a topic and a word count from the user, sends the topic through a
"manipulator and judge" model that decides whether the request is specific
enough, and then sends the refined topic to a generator model that produces
words with five hints each. The result is written to a CSV file.

Every API call is stateless: no conversation history is sent or kept.

Usage:
    python3 deck_generator.py
    python3 deck_generator.py --topic "NFL quarterbacks" --count 10
"""

import argparse
import csv
import json
import os
import sys
import time

from google import genai
from google.genai import errors, types

MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.8-flash")
HINTS_PER_WORD = 5
MIN_WORDS = 1
MAX_WORDS = 100
TIMEOUT_MS = 90_000  # give up rather than hang forever


# ---------------------------------------------------------------------------
# Talking to the model
# ---------------------------------------------------------------------------

def ask_model(client, prompt, schema):
    """Send one stateless request and return the reply as parsed JSON.

    The schema constrains decoding, which is both faster and more reliable
    than asking for free-form JSON. Thinking is low because both calls here
    are short and well specified. The server occasionally returns 503/504
    under load, so a slow call is retried rather than failing the run.
    """
    config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=schema,
        thinking_config=types.ThinkingConfig(thinking_level="low"),
    )
    for attempt in range(3):
        try:
            response = client.models.generate_content(
                model=MODEL, contents=prompt, config=config
            )
            return json.loads(response.text)
        except errors.ServerError as err:
            if attempt == 2:
                raise
            wait = 3 * (attempt + 1)
            print(f"  Model was busy ({err.code}); retrying in {wait}s...")
            time.sleep(wait)
        except Exception as err:
            # Some models reject thinking_level; retry once without it.
            if "thinking" not in str(err).lower() or config.thinking_config is None:
                raise
            config.thinking_config = None


def judge_and_refine(client, topic, count):
    """Stage 1: is this topic specific enough, and how should it be reworded?

    Returns a dict with keys: specific_enough (bool), reason (str),
    refined_query (str).
    """
    prompt = f"""You screen topic requests for a party game called Imposter.

A player asked for a deck of {count} words on this topic:
"{topic}"

Decide whether the topic is specific enough to build that deck. A topic is too
vague if it is so broad that the words could come from almost anywhere (for
example "stuff" or "things"). A topic is specific enough if a reasonable person
could list {count} distinct words that clearly belong to it.

If it is specific enough, rewrite it as a short, precise instruction for a deck
generator. Keep the player's intent; do not invent new constraints.

Give a one sentence reason the player will read. If it is too vague, leave
refined_query empty.
"""
    schema = {
        "type": "object",
        "properties": {
            "specific_enough": {"type": "boolean"},
            "reason": {"type": "string"},
            "refined_query": {"type": "string"},
        },
        "required": ["specific_enough", "reason", "refined_query"],
    }
    return ask_model(client, prompt, schema)


def generate_deck(client, refined_query, count):
    """Stage 2: produce `count` words, each with five hints.

    Returns a list of dicts with keys: word, hints (list of five strings).
    """
    prompt = f"""You build word decks for the party game Imposter, where one
player does not know the word and must bluff using only their hint.

Produce exactly {count} distinct words for: {refined_query}

Give each word exactly {HINTS_PER_WORD} hints. A hint must give the imposter
enough to bluff, without making the word obvious to the group. Never use the
word itself or an obvious synonym. Keep each hint under six words. Hints may
repeat across different words.
"""
    schema = {
        "type": "object",
        "properties": {
            "deck": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "word": {"type": "string"},
                        "hints": {"type": "array", "items": {"type": "string"}},
                    },
                    "required": ["word", "hints"],
                },
            }
        },
        "required": ["deck"],
    }
    data = ask_model(client, prompt, schema)
    return data.get("deck", [])


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def write_csv(rows, path):
    """Write the deck to a CSV: one word per row, followed by its five hints."""
    header = ["word"] + [f"hint{i}" for i in range(1, HINTS_PER_WORD + 1)]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for row in rows:
            hints = list(row.get("hints", []))[:HINTS_PER_WORD]
            hints += [""] * (HINTS_PER_WORD - len(hints))
            writer.writerow([row.get("word", "")] + hints)


def preview(rows, limit=3):
    """Print the first few rows so the result can be checked by reading it."""
    for row in rows[:limit]:
        print(f"  {row.get('word', '')}")
        for hint in row.get("hints", []):
            print(f"      - {hint}")
    if len(rows) > limit:
        print(f"  ... and {len(rows) - limit} more")


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

def ask_for_count():
    """Prompt until the player gives a word count inside the allowed range."""
    while True:
        raw = input(f"How many words? ({MIN_WORDS}-{MAX_WORDS}): ").strip()
        if raw.isdigit() and MIN_WORDS <= int(raw) <= MAX_WORDS:
            return int(raw)
        print(f"  Please enter a whole number from {MIN_WORDS} to {MAX_WORDS}.")


def main():
    parser = argparse.ArgumentParser(description="Generate an Imposter deck as a CSV.")
    parser.add_argument("--topic", help="deck topic (skips the prompt)")
    parser.add_argument("--count", type=int, help=f"number of words ({MIN_WORDS}-{MAX_WORDS})")
    parser.add_argument("--out", default="deck.csv", help="output CSV path")
    parser.add_argument("--list-models", action="store_true",
                        help="print the models your key can use, then exit")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        sys.exit("GEMINI_API_KEY is not set. Run: export GEMINI_API_KEY=your_key")
    client = genai.Client(
        api_key=api_key,
        http_options=types.HttpOptions(timeout=TIMEOUT_MS),
    )

    if args.list_models:
        for model in client.models.list():
            if "generateContent" in (model.supported_actions or []):
                print(model.name)
        return

    count = args.count if args.count else ask_for_count()
    if not MIN_WORDS <= count <= MAX_WORDS:
        sys.exit(f"--count must be from {MIN_WORDS} to {MAX_WORDS}.")

    # Step 1-2: keep asking until the judge accepts the topic.
    topic = args.topic
    while True:
        if not topic:
            topic = input("Deck topic: ").strip()
        if not topic:
            continue

        print("\nChecking the topic...")
        verdict = judge_and_refine(client, topic, count)

        if verdict.get("specific_enough"):
            refined = verdict.get("refined_query") or topic
            print(f"  Accepted: {verdict.get('reason', '')}")
            print(f"  Using: {refined}")
            break

        print(f"  Too vague: {verdict.get('reason', 'please add more detail')}")
        if args.topic:
            sys.exit("Rerun with a more specific --topic.")
        topic = None  # ask again

    # Step 3: generate the deck from the refined query.
    print(f"\nGenerating {count} words...")
    deck = generate_deck(client, refined, count)
    if not deck:
        sys.exit("The generator returned no words. Try rerunning.")

    write_csv(deck, args.out)
    print(f"\nWrote {len(deck)} words to {args.out}\n")
    preview(deck)


if __name__ == "__main__":
    main()

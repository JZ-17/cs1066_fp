# Deck Generator (Task 1 prototype)

Takes a topic and a word count, screens the topic through a judge model,
then generates a deck of words with five hints each and writes it to a CSV.

## Setup

```
cd deck_generator
python3 -m venv venv
source venv/bin/activate
pip install -q -U google-genai
export GEMINI_API_KEY=your_key_here
```

Get a free key at https://aistudio.google.com/api-keys

## Run

Interactive:

```
python3 deck_generator.py
```

Non-interactive:

```
python3 deck_generator.py --topic "NFL quarterbacks" --count 10 --out nfl.csv
```

## Output

`deck.csv`, one word per row with five hints:

| word | hint1 | hint2 | hint3 | hint4 | hint5 |
|------|-------|-------|-------|-------|-------|

## Notes

- Every API call is stateless; no conversation history is sent or stored.
- A topic judged too vague sends you back to the prompt instead of generating.

## If the model name errors

Google retires model names. To see what your key can use:

```
python3 deck_generator.py --list-models
```

Then pick one:

```
export GEMINI_MODEL=gemini-3.8-flash
```

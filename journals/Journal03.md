# Journal 03

## General Feedback from Section
*   Talked about testing in regards to token optimization and we decided it would be best to hold it off for a future step.
*   Updated project composition from UI first -> AppLovin integration -> account profiling with Google Logins for custom deck integration based on the user -> Personalizing with custom AI decks and optimizing for token usage.
*   For this week specifically, I will be focusing on creating the core game logic of Imposter and the base datasets that will come preinstalled into the game.

## Describe, for each piece of peer/mentor feedback that you wrote in your section notebook, how you addressed or plan to address it.

In my last section, with a pretty quick sync-up, my mentor and I discussed what we want to come out of this project, and in particular the order in which I should build it.

We decided that the core game logic and the base decks are a better place to start than the generator, which my decomposition in Journal02.md put first. The new order runs 2, 4, 5, 6 from that decomposition, with the generator and conversational refinement moved to the end. This was primarily because there were many questions and plans of how to approach the generator that needed to be addressed at this point. This lets us start with a more concrete and definitive approach.

We also talked about user personalization and where to store user settings. For this, I plan to use the Google Sign-In API, so that users can save their custom-made card decks through a combination of the Google Sign-In API and a Supabase database. I'm not the greatest in the world with SQL, so AI will definitely be in the mix here.

Currently, as a tentative plan for the card generator, I will test different skill.md and model combinations to find a token-efficient setup relative to the AppLovin cost offset, especially since I am paying for my own tokens.

The variables I plan to change are the model itself, how much of the specification lives in the skill.md versus the prompt, and how many words I request per call. What I need to compare is not cost per call but the token cost per usable deck, since a cheaper call that returns revealing hints and has to be regenerated is not actually cheaper. We will use an LLM judge to score whether the hints given for each word are too obvious. I'll provide a scored dataset for the LLM judge to use as reference for harshness in an attempt to ground the LLM judge on scoring.

## Questions to Ask
1.  Where should the API key live once the app ships? It cannot go in the iOS binary, since anyone can extract it from the app bundle, so the generator calls presumably need to route through a backend I control. Does Supabase cover that, or do I need something separate?
2.  While I have made an LLM plan that I am mostly comfortable with, are there any suggestions or improvements that you would make?

## Addendum
I'm sorry for the lack of major production this week on my project. I plan on working a lot more this week. I have been swamped in full-time job recruitment as a first priority.
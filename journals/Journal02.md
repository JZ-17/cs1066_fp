# Journal 02

Prototype demo: https://youtu.be/WOS8CW8NGbM

## Feedback from Journal 01

I really like that your project idea is also something I've thought of! I was on a long roadtrip recently as well, except my game was Heads Up. It was discussed that an AI-powered game can not only personalize questions to the user, but also bring in recent events/trends to keep the game fresh. I'm glad that you are taking on a similar problem for this final project.

The scope of your project is just right! I like that you've considered what part of your project is already served by existing market players, and what part (AI gen + manual deck creation) is not. I would really encourage you to explore the AppLovin integration- it would be really cool to see this actually on the App Store, and thinking about ad architecture early on could make this into a real, viable app. Since you've already coded before and AI makes UI design much more streamlined, I would encourage you to think deeply about the entire life cycle of app development, especially the broader/more high level considerations such as how to scale it (in case you choose to do so!).

## Problem Decomposition

Following the one-piece-at-a-time approach from class, I broke the project into tasks that are each small enough for me to check by hand.

**1. A standalone deck generator.**

To start, I want to build a script that takes in a topic from the user and the quantity of words they want within the deck. It returns a set of words with five hints each, which is a clear enough output that I can check it just by reading the result. The script should follow this sequence:

1. The user enters a query for a new genre of card deck and selects how many words they want within the deck, ranging from 1-100. This goes into the query manipulator and judge LLM.
2. The manipulator LLM evaluates whether the request is specific enough.
    2a. If the query is too vague, the agent sends the user back to step 1 for more detail.
    2b. Otherwise, the query is rewritten as needed before it reaches the generator.
3. The rewritten query goes to an LLM with a specialized skill for producing new decks in the format the game expects.

This is arguably the most critical task, because if AI cannot produce usable hints and words, the vast majority of the project has no point. The query manipulator LLM sits in front of the primary LLM so that vague requests get sharpened before they reach the step that actually matters.

I will also need evaluative metrics for both stages, since the manipulator and the generator can each fail in ways that the other one hides. I also plan to keep each request stateless, since conversation memory does not seem necessary here.

**2. Hardcoded scripts of Imposter deck collections.**

Before any app exists, I'd like to use AI to create a set of hardcoded, irremovable datasets of default topics that players can play upon installation. Within each respective genre of dataset (e.g., Christmas, Foods), each dataset row will contain a word and five potential hints for that word, where overlapping hints are permitted. I will review the datasets by hand. These datasets will give the deck generator reference examples of the output it should produce.

I can also use a separate set as a test dataset to verify that the generator behaves correctly.

**3. Conversational refinement.**

From here, I will extend the generator script so it takes an existing deck plus an instruction like "only quarterbacks" and returns a revised deck. The script should also let players add more cards to an existing deck, up to 100 total words. This one is iterative by design. My first prompt for deck creation will likely be too vague, and the refinement strategies from class, especially being specific about direction and exclusions, are what I will be tuning here.

**4. Game logic and deck storage.**

Beyond this, I need functions for role assignment, turn order, and the format a deck is saved in. This part mainly entails translating the rules of the game into the codebase and writing functions I can call to run a round correctly. Because I know the rules from playing, I can specify this task precisely instead of discovering it through iteration, and I can test all of this fairly quickly through personal use and unit/feature tests. The deck format is also what tasks 2, 3, and 5 all read from, so pinning it down early keeps the rest of the project from drifting.

**5. The iOS app.**

Next, I will build the part that sits furthest outside my experience. I will create the SwiftUI screens for the home menu, deck selection, role reveal, and voting, then wire in the scripts from the previous steps.

During this step, I expect to explore the most. I do not know SwiftUI well enough to write a precise prompt up front. For now, I plan to prompt for one screen at a time and read the generated code closely enough to recognize the actions I asked for before moving on, using AI to iteratively clarify on code.

**6. AppLovin and monetization; server-based data storage.**

Finally, I will monetize the app with AppLovin and attempt to store certain aspects of proprietary data with other resources like Supabase. This is the least specified task on the list, which is part of why it is last. I do not yet know what the AppLovin and Supabase SDKs require, so I expect to work through it with AI as an exploration rather than a specification, starting with a small test integration before touching the real app.

**Order Rationale.**

For this project, I am starting with the hardest and murkiest piece rather than the easiest one. The LLM work is what makes the project unique, and it is also where I expect to need the most time, so I want to learn early whether it actually works.

I also plan to work on tasks 1 and 4 in parallel. The game logic and deck storage need no AI at all, so I can write and test that piece while I am still tuning the generator, and neither one blocks the other. Task 2 comes early as well, since the hardcoded decks are what give the generator its reference examples. I could swap the order between tasks 1 and 2 and it would be logical either way. Everything after that is ordered by dependency. The iOS app wires together scripts that already work, and monetization only makes sense once there is an app to monetize.

Since by then I will understand the rest of the project well enough to wire it up, I plan to do the iOS portion last. As I am attempting UI design for the first time, I hope to read the generated code much more easily once I have already worked through everything else.

## Questions to Ask
1. What are the best ways to control token usage and cost once the app is deployed? Because the deck generator calls an LLM on demand, I am worried about both hitting rate limits and paying for calls made by players I do not know. Ideally I would at least break even when said feature is used, which is part of why I am considering AppLovin.

2. How should I be thinking about scaling if the app gets real usage? If several groups generate decks at the same time, I do not know what breaks first, and I have never scaled an end-to-end application before. Previously, I have only written the backend scripts and worried less about these aspects, since I had teammates who handled that side in a relay-style handoff. My Journal 01 feedback also encouraged me to think about the broader app life cycle early, so this feels like the right time to ask.

3. How should I decide what counts as a query being specific enough? In task 1, the manipulator LLM judges whether a player's request is too vague before passing it to the generator, but I have not defined what passes. Is "sports" too vague? Is "NFL"? That judgment sits upstream of everything else, so a bad call there produces decks that look fine but miss what the group actually wanted. Getting this prompt right seems especially important.

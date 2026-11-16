# Journal 04

## General Feedback from Section
*   Likes the ideas, but believes that the current algorithm for card generation is a bit slow. It takes up a lot of time. Perhaps something like removing the query manipulator call may be needed as each step currently takes up a lot of time.
*   Recommended limiting the user to only 3 calls per day to ensure that token overusage is not possible.
*   Likes the overall idea of the game and is generally curious to see how it develops.
*   Skimmed the base datasets generated and believes that they were well-crafted.

## Partner Feedback after Creation of the Game Logic in Swift (Post-Section)
*   Saw no major complaints, when testing about the game mechanics.
*   The game setting page had some redudancies such as multiple, imposter and player panels.

## Describe, for each piece of peer/mentor feedback that you wrote in your section notebook, how you addressed or plan to address it.

Overall, my peer review during section was more concise and more related to my generator, which is my biggest question mark throughout the development of this project. I believe that Janet's comment regarding only allowing users 3 calls per day was actually such an amazing idea. By limiting the number of LLM calls allowed per user, we ensure that no one can ever burn through a ludicrous amount of tokens. I will likely attempt to implement this in the final product.

While more testing is needed, with insight from Janet, I believe that removing the query manipulator portion of the LLM call may be beneficial. We can instead fold the query manipulator's prompt into the prompt of the actual deck generator. This will ensure that we don't need two separate LLM calls per generation and should ease the complexity of testing said generators.

Alternatively, instead of query manipulation, I believe that we could use evaluator LLMs to check that the hints generated for a new deck are not single-referent pointers or redundant. Using an iterative process, we ensure that the hints made will be sufficient to the level where a middle schooler cannot instantly guess the word off the hint. This was a strategy I tried when generating the base datasets that come with the game. I'll likely add something in regards to this when creating the deck generator.

Beyond that, I created the majority of the game UI in Swift over the weekend. With some testing with friends and while still in a prototype state, it seemed overall successful. Janet also pointed out some redundancies post-section that I have taken into account.

## Questions to Ask
Not for this assignment!! I believe that I've found myself on a roll. Next steps for the following week will be Supabase and Google API integration, along with smoother UI. Following that I will integrate AppLovin and then the deck generator.
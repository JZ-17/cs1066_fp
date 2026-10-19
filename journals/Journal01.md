# Journal 01

## The Problem

During an eight-hour car trip with my best friends Alan and Logan, we played Imposter by Sven Vucak to pass the time. We loved the bluffing, creative clues, and debates of the game, but eventually started encountering the same words and hints because we kept encountering repeats from the built-in word bank. While the game itself was still fun, the content of the game had become repetitive and stale.

That experience ultimately inspired me to create a new variation of the imposter game that combines ready-to-play categories with tools for creating new content. Players could use AI-integrated tools to generate custom categories, words, and hints based on their interests, or manually create and edit their own decks as well.

Instead of being limited to a fixed word bank, groups could personalize the game around their favorite topics and inside jokes, keeping future sessions fresh.

Since I use Apple devices, my goal is to develop this project into a fully functional iOS application. My focus is on helping groups create content around what they actually know, without turning a spontaneous game into a lengthy deck-writing task. I'm most excited about the possibility of returning to the same game with Alan and Logan, but playing rounds shaped by our shared interests rather than repeating words we already recognize.

## Prior Research

For my research, I looked within Apple's App Store and Google Play and identified several existing competitors. These include Sven Vucak's Imposter Game - Party Edition, Sokak Technologies' Imposter Who?, and Tomi Arakaki’s Imposter AI. 

Among these prominent competitors, I found that Vucak’s game already supports custom categories and hints, while Arakaki’s app offers paywalled AI-generated categories based on user-selected topics. Therefore, neither AI-generated content nor manually created decks alone represents a new solution. However, among the prominent apps I reviewed, I did not find one that offers both AI generation and manual deck creation for free. My project aims to make both capabilities accessible without a subscription. If time permits, as a stretch goal, I will explore integrating advertising through AppLovin to help offset AI API costs while keeping these features free for players.

My goal is to combine these capabilities in a free-to-play experience, with an emphasis on conversational refinement rather than one-time content generation. For example, a group could request an “NFL players” deck, then ask for “more recognizable players” or “only quarterbacks” without manually rewriting the cards. Players could also optionally provide feedback after a round to help adjust future content to their group’s interests and knowledge. 

The challenge is not simply generating more words, but creating accurate, varied cards with hints that help the imposter participate without making the answer obvious. 

## Why AI Is Necessary

Quite honestly, this project extends beyond my current technical experience, particularly in the fields of iOS development, front-end engineering and building a complete application from end to end independently. I'd have to connect a mobile interface, game logic, deck storage, and AI-powered content generation all into one reliable experience.

Given my starting point and the course timeline, completing that scope independently would likely be near impossible without AI assistance. I plan to use AI as a development partner to explain unfamiliar concepts, help decompose the project into manageable features, suggest implementation approaches, and assist with debugging and testing.

Within the application itself, AI will interpret open-ended requests and revise personalized decks without requiring me to manually anticipate every topic or preference.

## Expertise I Bring

- I bring some experience with AI integration and backend engineering from previous hackathon projects. Although I have not independently built an application of this scope, that foundation will help me break down the technical work, connect AI services, and implement storage for custom decks. It also gives me a starting point for understanding and debugging how the application’s components interact.

- I have played several competing versions of Imposter extensively, giving me firsthand familiarity with the rules, common interfaces, and how repeated words and hints affect the experience. This knowledge will help me prioritize features and evaluate whether generated cards are understandable and engaging. I can use those observations to guide the design, then test my assumptions with other players.

## Course Goals

My primary goal in taking this course is to develop stronger prompting fundamentals and more reliable habits when working with AI. Although I use AI frequently, my prompts can be loosely structured or leave important assumptions unstated, making the responses less useful and harder to evaluate. This project will give me practice breaking complex tasks into clear instructions, providing relevant context, defining constraints, and checking outputs rather than accepting them at face value. Using the prompt-writing techniques I have learned in the course, I hope to use AI optimally both to help develop the application and to design its conversational deck-generation features as I work my way through a new architectural domain.

Learning iOS development and front-end engineering would be additional benefits. I love thoughtful mobile experiences, but building one myself would push me beyond my current comfort zone. Designing a smooth flow for creating decks, revealing roles, and passing the phone would let me explore that interest while learning how to turn an idea into a functional application.

-- Scope every policy to signed in users.
--
-- Written without a TO clause, a policy defaults to TO public, which means
-- Postgres evaluates it for the anon role as well. That was never a hole,
-- since auth.uid() is null for an unauthenticated request and null never
-- equals an owner_id. But it made the intent unclear, and it made the planner
-- run a check that can only ever fail.
--
-- Anonymous players are "authenticated" here. Signing in anonymously still
-- issues a real session with the authenticated role, so they are covered.
-- Someone holding only the publishable key, with no session at all, is not.

alter policy "read own decks"   on public.decks to authenticated;
alter policy "create own decks" on public.decks to authenticated;
alter policy "update own decks" on public.decks to authenticated;
alter policy "delete own decks" on public.decks to authenticated;

alter policy "read own cards"   on public.cards to authenticated;
alter policy "create own cards" on public.cards to authenticated;
alter policy "update own cards" on public.cards to authenticated;
alter policy "delete own cards" on public.cards to authenticated;

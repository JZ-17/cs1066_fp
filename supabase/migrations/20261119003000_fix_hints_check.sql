-- Fix two holes in the hints check.
--
-- The original was:
--
--     array_length(hints, 1) = 5 and array_position(hints, null) is null
--
-- An empty array slipped straight through it. array_length on an empty array
-- returns null rather than 0, so the test evaluated to null, and a CHECK
-- constraint only rejects a row when it evaluates to false. Null passes.
--
-- It also never looked at the hints themselves, so five empty strings counted
-- as five hints. Neither case crashes the game. The imposter just silently
-- gets nothing to work with, which is harder to notice than a crash.

create or replace function public.valid_hints(h text[])
returns boolean
language sql
immutable
as $$
    -- coalesce is the fix: an empty array now reads as 0, which fails.
    select coalesce(array_length(h, 1), 0) = 5
       and array_position(h, null) is null
       and not exists (select 1 from unnest(h) x where btrim(x) = '');
$$;

alter table public.cards drop constraint cards_hints_check;

alter table public.cards add constraint cards_hints_check
    check (public.valid_hints(hints));

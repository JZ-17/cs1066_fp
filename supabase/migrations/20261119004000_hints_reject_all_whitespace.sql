-- btrim() only strips spaces.
--
-- The previous version used btrim(x) = '' to catch a blank hint. That catches
-- "" and "   ", but a tab survives trimming and reads as real text, so a hint
-- of "\t" was accepted. Newlines had the same problem.
--
-- '^\s*$' matches a string that is empty or nothing but whitespace of any
-- kind, which is the rule we actually wanted.

create or replace function public.valid_hints(h text[])
returns boolean
language sql
immutable
as $$
    select coalesce(array_length(h, 1), 0) = 5
       and array_position(h, null) is null
       and not exists (select 1 from unnest(h) x where x ~ '^\s*$');
$$;

-- Replacing the function body alone does not re-check rows already in the
-- table. Dropping and re-adding the constraint forces every existing row
-- through the new rule, so bad data cannot survive the fix.
alter table public.cards drop constraint cards_hints_check;

alter table public.cards add constraint cards_hints_check
    check (public.valid_hints(hints));

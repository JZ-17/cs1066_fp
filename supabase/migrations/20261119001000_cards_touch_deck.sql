-- Make decks.updated_at the single watermark for syncing.
--
-- The app syncs by asking "which of my decks changed since I last looked".
-- That only works if a change to a card counts as a change to its deck. The
-- trigger on decks fires on updates to the deck row itself, so editing a word
-- would otherwise leave updated_at alone and the phone would keep serving a
-- stale cached copy forever.

create or replace function public.touch_parent_deck()
returns trigger
language plpgsql
as $$
begin
    -- On delete the new row is null, so take the id from the old one.
    update public.decks
    set updated_at = now()
    where id = coalesce(new.deck_id, old.deck_id);

    return coalesce(new, old);
end;
$$;

create trigger cards_touch_parent_deck
    after insert or update or delete on public.cards
    for each row
    execute function public.touch_parent_deck();

-- The sync query filters on updated_at, so it needs an index. Ordering by
-- owner first means one player's rows sit together in the index and the scan
-- never walks past them.
create index decks_owner_updated_idx on public.decks (owner_id, updated_at desc);

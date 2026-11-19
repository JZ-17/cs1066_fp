-- Custom decks, owned by one player each.
--
-- Every row belongs to a user in auth.users. That user may be anonymous for
-- now. An anonymous user still gets a real id, so when Sign in with Apple is
-- added later the same id is kept and these rows carry over untouched.

-- A deck is the thing a player names and plays with.
create table public.decks (
    id uuid primary key default gen_random_uuid(),

    -- on delete cascade: if the account goes, so do its decks.
    owner_id uuid not null references auth.users (id) on delete cascade,

    name text not null check (char_length(trim(name)) between 1 and 60),

    -- Shown on the deck row in the picker, like the pizza slice on Foods.
    symbol text not null default '🃏' check (char_length(symbol) <= 8),

    -- What the player typed into the generator, kept so they can see where a
    -- deck came from and regenerate it later.
    topic text check (topic is null or char_length(topic) <= 200),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- A card is one secret word plus the five hints an imposter can draw from.
create table public.cards (
    id uuid primary key default gen_random_uuid(),
    deck_id uuid not null references public.decks (id) on delete cascade,

    word text not null check (char_length(trim(word)) between 1 and 60),

    -- Five hints, matching Card.hints in the app. The length check is what
    -- stops a half finished generation from being saved.
    hints text[] not null check (
        array_length(hints, 1) = 5
        and array_position(hints, null) is null
    ),

    -- Keeps the deck in the order it was generated.
    position integer not null default 0,

    created_at timestamptz not null default now(),

    -- No duplicate words inside one deck. A repeat is a wasted round.
    unique (deck_id, word)
);

-- Every query filters by owner or by deck, so both need an index.
create index decks_owner_id_idx on public.decks (owner_id);
create index cards_deck_id_idx on public.cards (deck_id, position);

-- Keep updated_at honest without the app having to remember to set it.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger decks_touch_updated_at
    before update on public.decks
    for each row
    execute function public.touch_updated_at();

-- Deck limit
--
-- 50 custom decks per account. Past that the player has to delete one before
-- making another.
--
-- This lives in the database rather than in the app on purpose. Every copy of
-- the app ships the same anon key, so anyone can talk to this table directly
-- with curl. A check in Swift would stop honest players and nobody else.
--
-- The three decks that ship inside the app are not rows here, so they never
-- count against the limit.
create or replace function public.enforce_deck_limit()
returns trigger
language plpgsql
as $$
declare
    deck_count integer;
begin
    select count(*) into deck_count
    from public.decks
    where owner_id = new.owner_id;

    if deck_count >= 50 then
        -- The app matches on this exact message to show a friendly screen,
        -- so do not reword it without changing the Swift side too.
        raise exception 'deck_limit_reached'
            using errcode = 'check_violation',
                  hint = 'Delete a deck before making a new one.';
    end if;

    return new;
end;
$$;

create trigger decks_enforce_limit
    before insert on public.decks
    for each row
    execute function public.enforce_deck_limit();

-- Row level security
--
-- Without this every signed in user could read every row, because they all
-- share the same anon API key. These policies are the only thing keeping one
-- player's decks away from another's.
--
-- Note the (select auth.uid()) wrapping. Called bare, auth.uid() can be run
-- once per row scanned. Wrapped in a subselect the planner runs it once for
-- the whole query and reuses the answer. Same result, and it stops the
-- policies from getting slower as the tables grow.

alter table public.decks enable row level security;
alter table public.cards enable row level security;

create policy "read own decks"
    on public.decks for select
    using ((select auth.uid()) = owner_id);

create policy "create own decks"
    on public.decks for insert
    with check ((select auth.uid()) = owner_id);

-- Both halves are needed on update. USING picks which rows you may touch,
-- WITH CHECK stops you rewriting owner_id to hand the deck to someone else.
create policy "update own decks"
    on public.decks for update
    using ((select auth.uid()) = owner_id)
    with check ((select auth.uid()) = owner_id);

create policy "delete own decks"
    on public.decks for delete
    using ((select auth.uid()) = owner_id);

-- Cards have no owner column of their own. They borrow their deck's owner.
create policy "read own cards"
    on public.cards for select
    using (
        exists (
            select 1 from public.decks d
            where d.id = cards.deck_id and d.owner_id = (select auth.uid())
        )
    );

create policy "create own cards"
    on public.cards for insert
    with check (
        exists (
            select 1 from public.decks d
            where d.id = cards.deck_id and d.owner_id = (select auth.uid())
        )
    );

create policy "update own cards"
    on public.cards for update
    using (
        exists (
            select 1 from public.decks d
            where d.id = cards.deck_id and d.owner_id = (select auth.uid())
        )
    )
    with check (
        exists (
            select 1 from public.decks d
            where d.id = cards.deck_id and d.owner_id = (select auth.uid())
        )
    );

create policy "delete own cards"
    on public.cards for delete
    using (
        exists (
            select 1 from public.decks d
            where d.id = cards.deck_id and d.owner_id = (select auth.uid())
        )
    );

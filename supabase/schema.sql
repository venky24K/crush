-- Supabase Database Schema for "Crush" Dating App
-- Completely idempotent: safe to run multiple times without errors!

-- 1. Profiles Table
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    full_name text not null,
    birth_date date not null,
    gender text not null check (gender in ('male', 'female', 'non-binary', 'other')),
    looking_for text[] default array['female']::text[],
    bio text default '',
    occupation text default '',
    school text default '',
    photos text[] not null default array[]::text[],
    interests text[] default array[]::text[],
    latitude double precision,
    longitude double precision,
    city text default '',
    distance_km double precision default 5.0,
    min_age_preference integer default 18,
    max_age_preference integer default 50,
    max_distance_km integer default 50,
    is_verified boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Row Level Security (RLS) for Profiles
alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by authenticated users" on public.profiles;
create policy "Profiles are viewable by authenticated users"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id);

-- 2. Swipes Table
create table if not exists public.swipes (
    id uuid primary key default gen_random_uuid(),
    swiper_id uuid not null references public.profiles(id) on delete cascade,
    swiped_id uuid not null references public.profiles(id) on delete cascade,
    action text not null check (action in ('like', 'pass', 'superlike')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint unique_swiper_swiped unique (swiper_id, swiped_id)
);

alter table public.swipes enable row level security;

drop policy if exists "Users can see their own swipes" on public.swipes;
create policy "Users can see their own swipes"
on public.swipes for select
to authenticated
using (auth.uid() = swiper_id);

drop policy if exists "Users can insert their own swipes" on public.swipes;
create policy "Users can insert their own swipes"
on public.swipes for insert
to authenticated
with check (auth.uid() = swiper_id);

-- 3. Matches Table
create table if not exists public.matches (
    id uuid primary key default gen_random_uuid(),
    user1_id uuid not null references public.profiles(id) on delete cascade,
    user2_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    last_message text default '',
    last_message_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint unique_match_pair unique (user1_id, user2_id)
);

alter table public.matches enable row level security;

drop policy if exists "Users can view matches they are a part of" on public.matches;
create policy "Users can view matches they are a part of"
on public.matches for select
to authenticated
using (auth.uid() = user1_id or auth.uid() = user2_id);

-- 4. Messages Table
create table if not exists public.messages (
    id uuid primary key default gen_random_uuid(),
    match_id uuid not null references public.matches(id) on delete cascade,
    sender_id uuid not null references public.profiles(id) on delete cascade,
    content text not null,
    is_read boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.messages enable row level security;

drop policy if exists "Users can view messages for their matches" on public.messages;
create policy "Users can view messages for their matches"
on public.messages for select
to authenticated
using (
    exists (
        select 1 from public.matches
        where public.matches.id = messages.match_id
        and (public.matches.user1_id = auth.uid() or public.matches.user2_id = auth.uid())
    )
);

drop policy if exists "Users can insert messages into their matches" on public.messages;
create policy "Users can insert messages into their matches"
on public.messages for insert
to authenticated
with check (
    auth.uid() = sender_id and
    exists (
        select 1 from public.matches
        where public.matches.id = match_id
        and (public.matches.user1_id = auth.uid() or public.matches.user2_id = auth.uid())
    )
);

-- 5. Trigger Function: Mutual Match Detector
-- Automatically creates a match when both users have swiped 'like' or 'superlike' on each other!
create or replace function public.handle_swipe_match()
returns trigger as $$
declare
    reciprocal_swipe record;
    u1 uuid;
    u2 uuid;
begin
    if new.action in ('like', 'superlike') then
        -- Check if the swiped user already liked the current swiper
        select * into reciprocal_swipe from public.swipes
        where swiper_id = new.swiped_id
        and swiped_id = new.swiper_id
        and action in ('like', 'superlike');

        if reciprocal_swipe.id is not null then
            -- Consistent ordering so user1_id < user2_id
            if new.swiper_id < new.swiped_id then
                u1 := new.swiper_id;
                u2 := new.swiped_id;
            else
                u1 := new.swiped_id;
                u2 := new.swiper_id;
            end if;

            insert into public.matches (user1_id, user2_id, created_at, last_message, last_message_at)
            values (u1, u2, now(), 'It''s a Match! Say hello 👋', now())
            on conflict (user1_id, user2_id) do nothing;
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_swipe_match_trigger on public.swipes;
create trigger on_swipe_match_trigger
after insert on public.swipes
for each row execute function public.handle_swipe_match();

-- 6. Trigger Function: Update last_message on new message
create or replace function public.handle_new_message()
returns trigger as $$
begin
    update public.matches
    set last_message = new.content,
        last_message_at = new.created_at
    where id = new.match_id;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_new_message_trigger on public.messages;
create trigger on_new_message_trigger
after insert on public.messages
for each row execute function public.handle_new_message();

-- 7. Enable Realtime for Messages & Matches safely
do $$
begin
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages') then
        alter publication supabase_realtime add table public.messages;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'matches') then
        alter publication supabase_realtime add table public.matches;
    end if;
end $$;

-- 8. Storage bucket for profile pictures
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
on storage.objects for select
to public
using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatars" on storage.objects;
create policy "Users can upload their own avatars"
on storage.objects for insert
to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users can update their own avatars" on storage.objects;
create policy "Users can update their own avatars"
on storage.objects for update
to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users can delete their own avatars" on storage.objects;
create policy "Users can delete their own avatars"
on storage.objects for delete
to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

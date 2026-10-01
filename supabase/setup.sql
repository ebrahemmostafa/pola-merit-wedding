-- Pola & Merit RSVPs. Run once in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Replace PUT_YOUR_SECRET_KEY_HERE (two places) with a long random secret.
-- The responses page is opened with that secret:  /responses.html#key=YOUR_SECRET
-- Never commit the real secret to the repository.
-- This script uses its own table and does not touch any other table in the project.

create table if not exists public.pola_merit_rsvps (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz not null default now(),
    full_name text not null check (char_length(full_name) between 1 and 300),
    phone text check (char_length(phone) <= 50),
    attendance text not null check (attendance in ('yes', 'no')),
    guest_count int not null default 1 check (guest_count between 0 and 20),
    adult_count int not null default 1 check (adult_count between 0 and 20),
    children_count int not null default 0 check (children_count between 0 and 20),
    dietary_requirements text check (char_length(dietary_requirements) <= 2000),
    attending_events text check (char_length(attending_events) <= 200),
    message text check (char_length(message) <= 3000)
);

alter table public.pola_merit_rsvps enable row level security;

-- Guests (visitors of the wedding site) may only ADD a response. Nobody can read the table directly.
drop policy if exists "Guests can submit an RSVP" on public.pola_merit_rsvps;
create policy "Guests can submit an RSVP"
    on public.pola_merit_rsvps for insert
    to anon, authenticated
    with check (true);

-- Reading and deleting go through these functions, which require the secret key.
create or replace function public.get_pola_merit_rsvps(p_key text)
returns setof public.pola_merit_rsvps
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_key is distinct from 'PUT_YOUR_SECRET_KEY_HERE' then
        raise exception 'invalid key' using errcode = '28000';
    end if;
    return query select * from public.pola_merit_rsvps order by created_at desc;
end;
$$;

create or replace function public.delete_pola_merit_rsvp(p_key text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_key is distinct from 'PUT_YOUR_SECRET_KEY_HERE' then
        raise exception 'invalid key' using errcode = '28000';
    end if;
    delete from public.pola_merit_rsvps where id = p_id;
end;
$$;

revoke all on function public.get_pola_merit_rsvps(text) from public;
revoke all on function public.delete_pola_merit_rsvp(text, uuid) from public;
grant execute on function public.get_pola_merit_rsvps(text) to anon, authenticated;
grant execute on function public.delete_pola_merit_rsvp(text, uuid) to anon, authenticated;

-- Clean-up from an earlier version of this script, which added these two functions to the shared
-- "rsvps" table. Removing them so this wedding's private link cannot read or delete another site's guests.
drop function if exists public.get_rsvps(text);
drop function if exists public.delete_rsvp(text, text);
drop function if exists public.delete_rsvp(text, uuid);

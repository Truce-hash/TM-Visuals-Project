-- Data-preserving additions for the installed tmv_* schema.
-- Run after supabase_schema.sql. This does not drop or recreate existing data.

do $$
begin
    if to_regclass('public.tmv_user') is null
       or to_regclass('public.tmv_admin') is null
       or to_regclass('public.tmv_client') is null
       or to_regclass('public.tmv_service') is null
       or to_regclass('public.tmv_date_availability') is null
       or to_regclass('public.tmv_booking') is null
       or to_regclass('public.tmv_booking_slot') is null
       or to_regclass('public.tmv_time_slot') is null
       or to_regclass('public.tmv_invoice') is null
       or to_regclass('public.tmv_client_content') is null
       or to_regclass('public.tmv_notification') is null then
        raise exception 'The base tmv_* schema is missing. Run supabase_schema.sql first.';
    end if;
end;
$$;

alter table public.tmv_admin
    add column if not exists business_name text not null default '';

alter table public.tmv_service
    add column if not exists admin_id uuid references public.tmv_admin(admin_id);

update public.tmv_service s
set admin_id = a.admin_id
from (
    select admin_id
    from public.tmv_admin
    order by created_at, admin_id
    limit 1
) a
where s.admin_id is null;

create or replace function public.tmv_update_my_profile(
    p_full_name text,
    p_phone text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    current_auth_id uuid := auth.uid();
    current_email text := lower(auth.jwt() ->> 'email');
    profile_user_id uuid;
begin
    if current_auth_id is null then
        raise exception 'Sign in is required to update your profile.';
    end if;
    if nullif(btrim(p_full_name), '') is null then
        raise exception 'Please enter your name.';
    end if;

    select user_id into profile_user_id
    from public.tmv_user
    where auth_user_id = current_auth_id
    for update;

    if profile_user_id is null then
        select user_id into profile_user_id
        from public.tmv_user
        where email = current_email
        for update;

        if profile_user_id is not null then
            update public.tmv_user
            set auth_user_id = current_auth_id,
                full_name = btrim(p_full_name),
                email = current_email,
                phone = coalesce(btrim(p_phone), '')
            where user_id = profile_user_id
              and auth_user_id is null;
            if not found then
                raise exception 'This email is already linked to another account.';
            end if;
        end if;
    end if;

    if profile_user_id is null then
        insert into public.tmv_user (auth_user_id, full_name, email, phone)
        values (
            current_auth_id,
            btrim(p_full_name),
            current_email,
            coalesce(btrim(p_phone), '')
        )
        returning user_id into profile_user_id;
    else
        update public.tmv_user
        set full_name = btrim(p_full_name),
            phone = coalesce(btrim(p_phone), '')
        where user_id = profile_user_id;
    end if;

    insert into public.tmv_client (user_id)
    values (profile_user_id)
    on conflict (user_id) do nothing;
end;
$$;

create or replace function public.tmv_set_admin_business_name(p_business_name text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null then
        raise exception 'Sign in is required to update business details.';
    end if;
    update public.tmv_admin
    set business_name = btrim(coalesce(p_business_name, ''))
    where user_id = auth.uid();
    if not found then
        raise exception 'Administrator profile not found.';
    end if;
end;
$$;

create or replace function public.tmv_admin_get_bookings()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.tmv_is_admin() then
        raise exception 'Administrator access is required.';
    end if;

    return query
    select jsonb_build_object(
        'booking_id', b.booking_id,
        'client_id', b.client_id,
        'event_type', b.event_type,
        'budget', b.budget,
        'requirements', b.requirements,
        'number_of_people', b.number_of_people,
        'location', b.location,
        'terms_accepted', b.terms_accepted,
        'booking_status', b.booking_status,
        'created_at', b.created_at,
        'updated_at', b.updated_at,
        'hold_expires_at', (
            select min(bs.expires_at)
            from public.tmv_booking_slot bs
            where bs.booking_id = b.booking_id
              and bs.selection_status = 'held'
        ),
        'client', jsonb_build_object(
            'user', jsonb_build_object(
                'full_name', u.full_name,
                'email', u.email,
                'phone', u.phone
            )
        ),
        'booking_service', jsonb_build_array(jsonb_build_object(
            'service', jsonb_build_object(
                'service_id', s.service_id,
                'service_name', s.service_name
            )
        )),
        'booking_slot', coalesce((
            select jsonb_agg(jsonb_build_object(
                'booking_slot_id', bs.booking_slot_id,
                'time_slot_id', bs.time_slot_id,
                'selection_status', bs.selection_status,
                'expires_at', bs.expires_at,
                'time_slot', jsonb_build_object(
                    'slot_date', ts.slot_date,
                    'start_time', ts.start_time,
                    'end_time', ts.end_time
                )
            ) order by ts.slot_date, ts.start_time)
            from public.tmv_booking_slot bs
            join public.tmv_time_slot ts on ts.time_slot_id = bs.time_slot_id
            where bs.booking_id = b.booking_id
        ), '[]'::jsonb)
    )
    from public.tmv_booking b
    join public.tmv_client c on c.client_id = b.client_id
    join public.tmv_user u on u.user_id = c.user_id
    join public.tmv_service s on s.service_id = b.service_id
    order by b.created_at desc;
end;
$$;

create or replace function public.tmv_get_my_calendar_bookings(p_booking_id uuid default null)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null then
        raise exception 'Sign in is required to view bookings.';
    end if;

    return query
    select jsonb_build_object(
        'booking_id', b.booking_id,
        'full_name', u.full_name,
        'email', u.email,
        'phone', u.phone,
        'services', s.service_name,
        'event_type', b.event_type,
        'booking_status', b.booking_status,
        'terms_accepted', b.terms_accepted,
        'budget', b.budget,
        'number_of_people', b.number_of_people,
        'location', b.location,
        'requirements', b.requirements,
        'created_at', b.created_at,
        'hold_expires_at', (
            select min(bs.expires_at)
            from public.tmv_booking_slot bs
            where bs.booking_id = b.booking_id
              and bs.selection_status = 'held'
        ),
        'delivery_link', (
            select cc.delivery_link
            from public.tmv_client_content cc
            where cc.booking_id = b.booking_id
            order by cc.uploaded_at desc
            limit 1
        ),
        'slots', coalesce((
            select jsonb_agg(jsonb_build_object(
                'slot_date', ts.slot_date,
                'start_time', ts.start_time,
                'end_time', ts.end_time
            ) order by ts.slot_date, ts.start_time)
            from public.tmv_booking_slot bs
            join public.tmv_time_slot ts on ts.time_slot_id = bs.time_slot_id
            where bs.booking_id = b.booking_id
              and bs.selection_status <> 'released'
        ), '[]'::jsonb)
    )
    from public.tmv_booking b
    join public.tmv_client c on c.client_id = b.client_id
    join public.tmv_user u on u.user_id = c.user_id
    join public.tmv_service s on s.service_id = b.service_id
    where u.auth_user_id = auth.uid()
      and (p_booking_id is null or b.booking_id = p_booking_id)
    order by b.created_at desc;
end;
$$;

create or replace function public.tmv_cancel_my_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    perform b.booking_id
    from public.tmv_booking b
    join public.tmv_client c on c.client_id = b.client_id
    join public.tmv_user u on u.user_id = c.user_id
    where b.booking_id = p_booking_id
      and u.auth_user_id = auth.uid()
      and b.booking_status in ('pending', 'confirmed')
    for update of b;

    if not found then
        raise exception 'Booking not found or can no longer be cancelled.';
    end if;

    update public.tmv_booking
    set booking_status = 'cancelled',
        updated_at = now()
    where booking_id = p_booking_id;

    update public.tmv_booking_slot
    set selection_status = 'released',
        expires_at = null
    where booking_id = p_booking_id;

    insert into public.tmv_notification (
        recipient_type, recipient_id, booking_id, title, body
    )
    select 'admin', a.user_id, p_booking_id, 'Booking cancelled',
           'A client cancelled a booking.'
    from public.tmv_admin a
    where a.booking_alerts;
end;
$$;

insert into public.tmv_service (service_name, description, is_active, admin_id)
select 'Food/Restaurant',
       'Food and restaurant photography and videography',
       true,
       (select admin_id from public.tmv_admin order by created_at, admin_id limit 1)
where not exists (
    select 1
    from public.tmv_service
    where lower(service_name) = lower('Food/Restaurant')
);

update public.tmv_service
set is_active = true,
    description = 'Food and restaurant photography and videography',
    admin_id = coalesce(
        admin_id,
        (select admin_id from public.tmv_admin order by created_at, admin_id limit 1)
    )
where lower(service_name) = lower('Food/Restaurant');

grant select on public.tmv_service to anon;
drop policy if exists tmv_public_read_active_services on public.tmv_service;
create policy tmv_public_read_active_services on public.tmv_service
    for select to anon using (is_active);

create or replace function public.tmv_admin_get_clients()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.tmv_is_admin() then
        raise exception 'Administrator access is required.';
    end if;

    return query
    select jsonb_build_object(
        'client_id', c.client_id,
        'user', jsonb_build_object(
            'full_name', u.full_name,
            'email', u.email,
            'phone', u.phone
        ),
        'bookings', coalesce((
            select jsonb_agg(jsonb_build_object(
                'booking_id', b.booking_id,
                'event_type', b.event_type,
                'event_date', b.created_at,
                'booking_status', b.booking_status
            ) order by b.created_at desc)
            from public.tmv_booking b
            where b.client_id = c.client_id
        ), '[]'::jsonb)
    )
    from public.tmv_client c
    join public.tmv_user u on u.user_id = c.user_id
    order by u.full_name, c.client_id;
end;
$$;

create or replace function public.tmv_get_my_invoices()
returns table (
    invoice_id uuid,
    reference text,
    file_path text,
    created_at timestamptz,
    client_email text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select i.invoice_id, i.reference, i.file_path, i.created_at, u.email
    from public.tmv_invoice i
    join public.tmv_booking b on b.booking_id = i.booking_id
    join public.tmv_client c on c.client_id = b.client_id
    join public.tmv_user u on u.user_id = c.user_id
    where u.auth_user_id = auth.uid()
    order by i.created_at desc;
$$;

drop policy if exists tmv_client_read_own_invoices on public.tmv_invoice;
create policy tmv_client_read_own_invoices on public.tmv_invoice
    for select to authenticated using (
        exists (
            select 1
            from public.tmv_booking b
            join public.tmv_client c on c.client_id = b.client_id
            join public.tmv_user u on u.user_id = c.user_id
            where b.booking_id = tmv_invoice.booking_id
              and u.auth_user_id = auth.uid()
        )
    );

create table if not exists public.tmv_portfolio_category (
    category_id uuid primary key default gen_random_uuid(),
    admin_id uuid not null references public.tmv_admin(admin_id) on delete cascade,
    category_name text not null unique
        check (length(trim(category_name)) between 1 and 50),
    created_at timestamptz not null default now()
);

create table if not exists public.tmv_portfolio_item (
    media_id uuid primary key default gen_random_uuid(),
    admin_id uuid not null references public.tmv_admin(admin_id) on delete cascade,
    category_id uuid not null references public.tmv_portfolio_category(category_id),
    title text not null check (length(trim(title)) between 1 and 100),
    media_location text not null check (media_location ~ '^https?://'),
    media_type text not null check (media_type in ('image', 'video')),
    created_at timestamptz not null default now()
);

alter table public.tmv_portfolio_category enable row level security;
alter table public.tmv_portfolio_item enable row level security;
drop policy if exists tmv_admin_manage_portfolio_categories
    on public.tmv_portfolio_category;
create policy tmv_admin_manage_portfolio_categories
    on public.tmv_portfolio_category for all to authenticated
    using (public.tmv_is_admin())
    with check (public.tmv_is_admin());
drop policy if exists tmv_admin_manage_portfolio_items
    on public.tmv_portfolio_item;
create policy tmv_admin_manage_portfolio_items
    on public.tmv_portfolio_item for all to authenticated
    using (public.tmv_is_admin())
    with check (public.tmv_is_admin());
grant select, insert, update, delete on
    public.tmv_portfolio_category, public.tmv_portfolio_item to authenticated;
grant select on
    public.tmv_portfolio_category, public.tmv_portfolio_item to anon;
grant select on
    public.tmv_portfolio_category, public.tmv_portfolio_item to anon;
drop policy if exists tmv_public_read_portfolio_categories
    on public.tmv_portfolio_category;
create policy tmv_public_read_portfolio_categories
    on public.tmv_portfolio_category for select to anon, authenticated
    using (true);
drop policy if exists tmv_public_read_portfolio_items
    on public.tmv_portfolio_item;
create policy tmv_public_read_portfolio_items
    on public.tmv_portfolio_item for select to anon, authenticated
    using (true);

insert into storage.buckets (id, name, public)
values ('portfolio', 'portfolio', true)
on conflict (id) do update set public = true;
drop policy if exists tmv_portfolio_storage_read on storage.objects;
create policy tmv_portfolio_storage_read on storage.objects
    for select to anon, authenticated using (bucket_id = 'portfolio');
drop policy if exists tmv_portfolio_storage_insert on storage.objects;
create policy tmv_portfolio_storage_insert on storage.objects
    for insert to authenticated with check (
        bucket_id = 'portfolio' and public.tmv_is_admin()
    );
drop policy if exists tmv_portfolio_storage_delete on storage.objects;
create policy tmv_portfolio_storage_delete on storage.objects
    for delete to authenticated using (
        bucket_id = 'portfolio' and public.tmv_is_admin()
    );

drop policy if exists tmv_admin_invoice_storage_read on storage.objects;
create policy tmv_admin_invoice_storage_read on storage.objects
    for select to authenticated using (
        bucket_id = 'invoices' and (
            public.tmv_is_admin()
            or exists (
                select 1
                from public.tmv_invoice i
                join public.tmv_booking b on b.booking_id = i.booking_id
                join public.tmv_client c on c.client_id = b.client_id
                join public.tmv_user u on u.user_id = c.user_id
                where i.file_path = storage.objects.name
                  and u.auth_user_id = auth.uid()
            )
        )
    );

create table if not exists public.tmv_date_time_block (
    block_id uuid primary key default gen_random_uuid(),
    slot_date date not null,
    start_time time not null,
    end_time time not null,
    created_at timestamptz not null default now(),
    check (start_time >= time '06:00'),
    check (end_time <= time '22:00'),
    check (end_time > start_time)
);

alter table public.tmv_date_time_block enable row level security;
drop policy if exists tmv_admin_manage_date_time_blocks
    on public.tmv_date_time_block;
create policy tmv_admin_manage_date_time_blocks
    on public.tmv_date_time_block for all to authenticated
    using (public.tmv_is_admin())
    with check (public.tmv_is_admin());
grant select, insert, update, delete on public.tmv_date_time_block
    to authenticated;

create or replace function public.tmv_reject_blocked_booking_slot()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if exists (
        select 1
        from public.tmv_time_slot ts
        join public.tmv_date_time_block block
          on block.slot_date = ts.slot_date
         and block.start_time < ts.end_time
         and block.end_time > ts.start_time
        where ts.time_slot_id = new.time_slot_id
    ) then
        raise exception 'That time is blocked for new bookings.';
    end if;
    return new;
end;
$$;

drop trigger if exists tmv_reject_blocked_booking_slot
    on public.tmv_booking_slot;
create trigger tmv_reject_blocked_booking_slot
    before insert or update of time_slot_id on public.tmv_booking_slot
    for each row execute function public.tmv_reject_blocked_booking_slot();

create or replace function public.tmv_admin_save_date_availability(
    p_date date,
    p_available boolean,
    p_blocks jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.tmv_is_admin() then
        raise exception 'Administrator access is required.';
    end if;
    if p_date is null or p_available is null
       or jsonb_typeof(p_blocks) is distinct from 'array' then
        raise exception 'Invalid availability details.';
    end if;
    if exists (
        select 1
        from jsonb_to_recordset(p_blocks) as block(start_time time, end_time time)
        where start_time is null or end_time is null
           or start_time < time '06:00' or end_time > time '22:00'
           or end_time <= start_time
    ) or exists (
        select 1
        from jsonb_to_recordset(p_blocks) as first_block(start_time time, end_time time)
        join jsonb_to_recordset(p_blocks) as second_block(start_time time, end_time time)
          on first_block.start_time < second_block.end_time
         and second_block.start_time < first_block.end_time
         and (first_block.start_time, first_block.end_time)
             < (second_block.start_time, second_block.end_time)
    ) then
        raise exception 'Blocked periods must be valid, non-overlapping times between 06:00 and 22:00.';
    end if;

    perform public.tmv_set_date_availability(p_date, p_available);

    delete from public.tmv_date_time_block
    where slot_date = p_date;

    insert into public.tmv_date_time_block (slot_date, start_time, end_time)
    select p_date, block.start_time, block.end_time
    from jsonb_to_recordset(p_blocks) as block(start_time time, end_time time);
end;
$$;

revoke all on function public.tmv_update_my_profile(text, text) from public;
revoke all on function public.tmv_set_admin_business_name(text) from public;
revoke all on function public.tmv_admin_get_bookings() from public;
revoke all on function public.tmv_get_my_calendar_bookings(uuid) from public;
revoke all on function public.tmv_cancel_my_booking(uuid) from public;
revoke all on function public.tmv_admin_save_date_availability(date, boolean, jsonb) from public;
revoke all on function public.tmv_reject_blocked_booking_slot() from public;
revoke all on function public.tmv_admin_get_clients() from public;
revoke all on function public.tmv_get_my_invoices() from public;
revoke all on function public.tmv_mark_notification_read(uuid) from public;

grant execute on function public.tmv_update_my_profile(text, text) to authenticated;
grant execute on function public.tmv_set_admin_business_name(text) to authenticated;
grant execute on function public.tmv_admin_get_bookings() to authenticated;
grant execute on function public.tmv_get_my_calendar_bookings(uuid) to authenticated;
grant execute on function public.tmv_cancel_my_booking(uuid) to authenticated;
grant execute on function public.tmv_admin_save_date_availability(date, boolean, jsonb) to authenticated;
grant execute on function public.tmv_admin_get_clients() to authenticated;
grant execute on function public.tmv_get_my_invoices() to authenticated;
grant execute on function public.tmv_mark_notification_read(uuid) to authenticated;
grant execute on function public.tmv_admin_set_booking_status(uuid, text, text)
    to authenticated;
grant select on public.tmv_notification to authenticated;

notify pgrst, 'reload schema';

-- If the tmv_admin table has no row yet, promote the intended Auth user by
-- replacing ADMIN_EMAIL with that user's exact email and running this statement:
-- insert into public.tmv_admin (user_id)
-- select id from auth.users where lower(email) = lower('ADMIN_EMAIL')
-- on conflict (user_id) do nothing;

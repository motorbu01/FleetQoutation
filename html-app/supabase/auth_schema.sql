-- =============================================================================
-- Auth Schema — User Profiles + System Settings
-- ต้องรันใน Supabase SQL Editor
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. user_profiles
-- ---------------------------------------------------------------------------
-- เชื่อมกับ auth.users ของ Supabase Auth
-- role: 'admin' | 'lv2' | 'lv1'

create table if not exists public.user_profiles (
    id                  uuid            primary key references auth.users(id) on delete cascade,
    display_name        text            not null,
    role                text            not null default 'lv1'
                                            check (role in ('admin', 'lv2', 'lv1')),
    is_active           boolean         not null default true,
    created_at          timestamptz     not null default now(),
    updated_at          timestamptz     not null default now()
);

comment on table  user_profiles              is 'ข้อมูล user เชื่อมกับ Supabase Auth';
comment on column user_profiles.role        is 'admin | lv2 | lv1';
comment on column user_profiles.is_active   is 'false = ระงับการใช้งาน';

-- auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger trg_user_profiles_updated_at
    before update on public.user_profiles
    for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 2. system_settings
-- ---------------------------------------------------------------------------
-- admin ปรับผ่าน UI ได้ทีหลัง
-- key examples:
--   session_timeout_hours        — หมดอายุ session กี่ชั่วโมง (default 8)
--   max_group_discount_lv1       — ส่วนลดงานกลุ่มสูงสุด lv1 (default 0)
--   max_group_discount_lv2       — ส่วนลดงานกลุ่มสูงสุด lv2 (default 10)
--   max_claim_discount_lv1       — ส่วนลดประวัติดีสูงสุด lv1 (default 20)
--   max_claim_discount_lv2       — ส่วนลดประวัติดีสูงสุด lv2 (default 20)

create table if not exists public.system_settings (
    key         text        primary key,
    value       text        not null,
    description text,
    updated_at  timestamptz not null default now(),
    updated_by  uuid        references auth.users(id)
);

comment on table system_settings is 'Settings ที่ admin ปรับได้ผ่าน UI';

create trigger trg_system_settings_updated_at
    before update on public.system_settings
    for each row execute function public.set_updated_at();

-- ค่า default
insert into public.system_settings (key, value, description) values
    ('session_timeout_hours',   '8',    'Session หมดอายุกี่ชั่วโมง (0 = ไม่หมดอายุ)'),
    ('max_group_discount_lv1',  '0',    'ส่วนลดงานกลุ่มสูงสุด (%) สำหรับ LV1'),
    ('max_group_discount_lv2',  '10',   'ส่วนลดงานกลุ่มสูงสุด (%) สำหรับ LV2'),
    ('max_claim_discount_lv1',  '20',   'ส่วนลดประวัติดีสูงสุด (%) สำหรับ LV1'),
    ('max_claim_discount_lv2',  '20',   'ส่วนลดประวัติดีสูงสุด (%) สำหรับ LV2')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 3. RLS Policies
-- ---------------------------------------------------------------------------

alter table public.user_profiles    enable row level security;
alter table public.system_settings  enable row level security;

-- user_profiles: อ่านได้เฉพาะ authenticated
-- admin เห็นทุก row, user เห็นแค่ตัวเอง
create policy "users_read_own_profile"
    on public.user_profiles for select
    to authenticated
    using (
        id = auth.uid()
        or exists (
            select 1 from public.user_profiles
            where id = auth.uid() and role = 'admin' and is_active = true
        )
    );

-- admin เท่านั้นที่ insert/update/delete user_profiles
create policy "admin_manage_profiles"
    on public.user_profiles for all
    to authenticated
    using (
        exists (
            select 1 from public.user_profiles
            where id = auth.uid() and role = 'admin' and is_active = true
        )
    )
    with check (
        exists (
            select 1 from public.user_profiles
            where id = auth.uid() and role = 'admin' and is_active = true
        )
    );

-- system_settings: authenticated อ่านได้ทุกคน
create policy "authenticated_read_settings"
    on public.system_settings for select
    to authenticated
    using (true);

-- admin เท่านั้น update settings
create policy "admin_update_settings"
    on public.system_settings for update
    to authenticated
    using (
        exists (
            select 1 from public.user_profiles
            where id = auth.uid() and role = 'admin' and is_active = true
        )
    )
    with check (
        exists (
            select 1 from public.user_profiles
            where id = auth.uid() and role = 'admin' and is_active = true
        )
    );

-- ---------------------------------------------------------------------------
-- 4. Helper Function — ดึง profile + settings ในครั้งเดียว
-- ---------------------------------------------------------------------------
create or replace function public.get_my_profile()
returns json language plpgsql security definer as $$
declare
    v_profile   json;
    v_settings  json;
begin
    select row_to_json(p) into v_profile
    from public.user_profiles p
    where p.id = auth.uid();

    select json_object_agg(key, value) into v_settings
    from public.system_settings;

    return json_build_object(
        'profile',  v_profile,
        'settings', v_settings
    );
end;
$$;

-- grant execute ให้ authenticated เรียกได้
grant execute on function public.get_my_profile() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. quotation_queue — เพิ่ม created_by (ถ้ายังไม่มี)
-- ---------------------------------------------------------------------------
alter table public.quotation_queue
    add column if not exists created_by uuid references auth.users(id);

comment on column quotation_queue.created_by is 'user ที่ออกใบเสนอราคา';

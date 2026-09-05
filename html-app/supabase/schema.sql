-- =============================================================================
-- Motor Insurance Quotation — Supabase / PostgreSQL Schema
-- =============================================================================
-- Tables:
--   1. car_master          — ข้อมูลรถยนต์ทั้งหมด
--   2. base_premium        — ตารางเบี้ยพื้นฐาน (basePremiumTable)
--   3. rate_tables         — rate tables ทั้งหมด เก็บเป็น JSONB (เล็ก/ไม่เปลี่ยนบ่อย)
--   4. coverage_rules      — เงื่อนไขความคุ้มครองตาม vehicleCode/type/repair/weight
--   5. prb_mapping         — พ.ร.บ. mapping (vehicleCode → prb codes)
--   6. prb_prices          — ราคา พ.ร.บ. net price ต่อ prb code
-- =============================================================================

-- ---------------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 1. car_master
-- ---------------------------------------------------------------------------
-- โครงสร้างแถว: [brand, model, spec, vehicleCode, year,
--                minSumInsured, sumInsured, maxSumInsured, cc, groupCode]
-- vehicleCode: 110=รถเก๋ง, 120=รถกระบะ4ประตู, 210=รถตู้, 220=รถโดยสาร,
--              320=รถบรรทุก, 327/340/347=รถบรรทุกพิเศษ, 420=หัวลาก,
--              520/540=รถพ่วง
-- groupCode: 1–5 (กลุ่มรถยนต์ตามความเสี่ยง)

create table if not exists car_master (
    id              bigserial       primary key,
    brand           text            not null,
    model           text            not null,
    spec            text            not null default '',
    vehicle_code    smallint        not null,   -- 110, 120, 210, ...
    car_year        smallint        not null,
    min_sum_insured integer         not null,
    sum_insured     integer         not null,
    max_sum_insured integer         not null,
    cc              smallint        not null default 0,
    group_code      smallint        not null default 2, -- 1–5
    created_at      timestamptz     not null default now()
);

comment on table  car_master                is 'ข้อมูลรถยนต์ ยี่ห้อ/รุ่น/สเปก/ทุนประกัน';
comment on column car_master.vehicle_code   is '110=เก๋ง,120=กระบะ4ประตู,210=ตู้,220=โดยสาร,320=บรรทุก,327/340/347=บรรทุกพิเศษ,420=หัวลาก,520/540=พ่วง';
comment on column car_master.group_code     is 'กลุ่มรถยนต์ตามความเสี่ยง 1–5';
comment on column car_master.sum_insured    is 'ทุนประกันแนะนำ (บาท)';
comment on column car_master.min_sum_insured is 'ทุนประกันต่ำสุดที่รับได้ (บาท)';
comment on column car_master.max_sum_insured is 'ทุนประกันสูงสุดที่รับได้ (บาท)';

-- indexes สำหรับ search/filter หน้า UI
create index if not exists idx_car_master_brand         on car_master (brand);
create index if not exists idx_car_master_brand_model   on car_master (brand, model);
create index if not exists idx_car_master_vehicle_code  on car_master (vehicle_code);
create index if not exists idx_car_master_year          on car_master (car_year);
create index if not exists idx_car_master_lookup        on car_master (brand, model, spec, vehicle_code, car_year);

-- ---------------------------------------------------------------------------
-- 2. base_premium
-- ---------------------------------------------------------------------------
-- ตารางเบี้ยพื้นฐานแยกตาม vehicleCode / class / repair / groups / seat / weight

create table if not exists base_premium (
    id              serial          primary key,
    vehicle_code    varchar(3)      not null,   -- '110','120', ...
    class           varchar(2)      not null,   -- '1','3'
    repair          varchar(20),                -- 'ซ่อมห้าง','ซ่อมอู่', null=ไม่ระบุ
    groups          text[],                     -- ['2','3','4'] หรือ null
    seat_max        smallint,                   -- max seat สำหรับ code 220
    weight_max      integer,                    -- max weight (kg), 999999999=ไม่จำกัด
    base            integer         not null,   -- เบี้ยพื้นฐาน (บาท)
    attach          integer         not null default 0,  -- ค่าเบี้ยแนบท้าย (บาท)
    ry31            integer         not null default 0   -- ค่า ry31 (บาท)
);

comment on table  base_premium             is 'ตารางเบี้ยประกันภัยพื้นฐานตาม คปภ.';
comment on column base_premium.vehicle_code is 'รหัสประเภทรถ';
comment on column base_premium.class       is 'ประเภทประกัน: 1=ชั้น1, 3=ชั้น3';
comment on column base_premium.groups      is 'กลุ่มรถที่ใช้เบี้ยนี้ เช่น ["2","3","4"]';
comment on column base_premium.weight_max  is 'น้ำหนักสูงสุด (kg), 999999999=ไม่จำกัด';

create index if not exists idx_base_premium_lookup on base_premium (vehicle_code, class);

-- ---------------------------------------------------------------------------
-- 3. rate_tables
-- ---------------------------------------------------------------------------
-- เก็บ rate tables ทั้งหมดเป็น JSONB เนื่องจากโครงสร้างต่างกัน
-- และมีขนาดเล็ก (query แบบ read-all ทั้ง table ในคราวเดียว)

create table if not exists rate_tables (
    id          serial      primary key,
    name        text        not null unique,  -- ชื่อ table เช่น 'usageRateTable'
    data        jsonb       not null,
    updated_at  timestamptz not null default now()
);

comment on table rate_tables      is 'Rate tables ทั้งหมดสำหรับคำนวณเบี้ยประกัน';
comment on column rate_tables.name is 'usageRateTable | capacityRateTable | vehicleAgeRateTable | vehicleGroupRateTable | extraAccessoryRateTable | sumInsuredRateTable | behaviorLevelRateTable | tpbiPersonRateTable | tpbiAccRateTable | tppdAccRateTable';

-- ---------------------------------------------------------------------------
-- 4. coverage_rules
-- ---------------------------------------------------------------------------

create table if not exists coverage_rules (
    id                serial      primary key,
    vehicle_code      varchar(3)  not null,
    type              varchar(2)  not null,    -- '1','2','2+','3','3+'
    repair            varchar(10) not null,    -- 'garage','agent','any'
    weight_condition  varchar(10) not null,    -- '<=3000','>3000','any'
    tpbi_person       integer     not null,    -- TP BI ต่อคน (บาท)
    tpbi_acc          integer     not null,    -- TP BI ต่อครั้ง (บาท)
    tppd_acc          integer     not null,    -- TP PD ต่อครั้ง (บาท)
    pa_driver         integer,                 -- PA คนขับ (บาท), null=ไม่คุ้มครอง
    pa_passenger      integer,                 -- PA ผู้โดยสาร (บาท)
    medical           integer,                 -- ค่ารักษาพยาบาล (บาท)
    bailbond          integer,                 -- ประกันตัว (บาท)
    unique (vehicle_code, type, repair, weight_condition)
);

comment on table  coverage_rules              is 'วงเงินความคุ้มครองตามประเภทรถและประเภทประกัน';
comment on column coverage_rules.repair       is 'garage=ซ่อมห้าง, agent=ซ่อมอู่, any=ไม่ระบุ';
comment on column coverage_rules.weight_condition is '<=3000 | >3000 | any';
comment on column coverage_rules.pa_driver    is 'null = ไม่คุ้มครอง (รถบรรทุก 520/540)';

create index if not exists idx_coverage_rules_lookup
    on coverage_rules (vehicle_code, type, repair, weight_condition);

-- ---------------------------------------------------------------------------
-- 5. prb_mapping
-- ---------------------------------------------------------------------------

create table if not exists prb_mapping (
    id              serial      primary key,
    vehicle_code    varchar(3)  not null unique,  -- '110','120', ...
    prb_codes       text[]      not null           -- ['1.10'] หรือ ['1.20A','1.20B',...]
);

comment on table prb_mapping is 'Mapping รหัสรถ → รหัส พ.ร.บ. ที่ใช้ได้';

create index if not exists idx_prb_mapping_code on prb_mapping (vehicle_code);

-- ---------------------------------------------------------------------------
-- 6. prb_prices
-- ---------------------------------------------------------------------------

create table if not exists prb_prices (
    id          serial          primary key,
    prb_code    varchar(10)     not null unique,  -- '1.10','1.20A', ...
    net_price   numeric(10,2)   not null           -- ราคา net (บาท)
);

comment on table prb_prices is 'ราคา พ.ร.บ. net price ต่อรหัส';

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
-- ทุก table เป็น read-only สำหรับ public (anonymous)
-- การ insert/update/delete ต้องเป็น service_role เท่านั้น

alter table car_master      enable row level security;
alter table base_premium    enable row level security;
alter table rate_tables     enable row level security;
alter table coverage_rules  enable row level security;
alter table prb_mapping     enable row level security;
alter table prb_prices      enable row level security;

-- Public read policy (anon + authenticated)
create policy "public_read_car_master"
    on car_master for select
    to anon, authenticated
    using (true);

create policy "public_read_base_premium"
    on base_premium for select
    to anon, authenticated
    using (true);

create policy "public_read_rate_tables"
    on rate_tables for select
    to anon, authenticated
    using (true);

create policy "public_read_coverage_rules"
    on coverage_rules for select
    to anon, authenticated
    using (true);

create policy "public_read_prb_mapping"
    on prb_mapping for select
    to anon, authenticated
    using (true);

create policy "public_read_prb_prices"
    on prb_prices for select
    to anon, authenticated
    using (true);

-- =============================================================================
-- VIEWS (optional helpers)
-- =============================================================================

-- view: รวม prb_mapping + prb_prices เพื่อ query ในขั้นตอนเดียว
create or replace view prb_full as
select
    m.vehicle_code,
    p.prb_code,
    p.net_price
from prb_mapping m
cross join lateral unnest(m.prb_codes) as prb_code_val(prb_code)
join prb_prices p on p.prb_code = prb_code_val.prb_code;

comment on view prb_full is 'รวม prb_mapping + prb_prices: vehicleCode → prb_code + net_price';

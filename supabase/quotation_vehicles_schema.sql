-- =============================================================================
-- quotation_vehicles table — เก็บข้อมูลรถแต่ละคันในใบเสนอราคา
-- รัน SQL นี้ใน Supabase SQL Editor
-- =============================================================================
-- หมายเหตุ: table นี้ denormalize ข้อมูลจาก quote_data JSONB ให้เป็น flat rows
-- เพื่อให้ query/filter/export ได้ง่าย โดยไม่ต้องแกะ JSON
-- =============================================================================

-- ถ้ามี VIEW ชื่อเดียวกันอยู่ก่อน (เช่น จาก schema เก่า) ให้ drop ก่อน
DROP VIEW IF EXISTS public.quotation_vehicles;

CREATE TABLE IF NOT EXISTS public.quotation_vehicles (
    id                      bigserial       PRIMARY KEY,

    -- FK → quotation_queue
    quote_no                text            NOT NULL,   -- เช่น FQ2608250001 หรือ FQ2608250001_V1
    vehicle_seq             smallint        NOT NULL DEFAULT 1, -- ลำดับรถในใบเสนอราคา (1, 2, 3 ...)

    -- ข้อมูลทั่วไปของใบเสนอราคา (denorm จาก quotation_queue)
    quote_date              date            NOT NULL,
    client_name             text,
    issuer_name             text,
    issuer_branch           text,
    created_by              uuid            REFERENCES auth.users(id) ON DELETE SET NULL,

    -- ข้อมูลรถยนต์
    plate                   text,                       -- ทะเบียนรถ
    brand                   text,
    model                   text,
    spec                    text,
    vehicle_code            varchar(3),                 -- 110, 120, 210, ...
    car_year                smallint,
    cc                      integer         NOT NULL DEFAULT 0,
    weight_kg               integer         NOT NULL DEFAULT 0,
    seat                    smallint,
    car_group               smallint,                   -- กลุ่มรถ 2-5

    -- รูปแบบประกัน
    type                    varchar(2)      NOT NULL,   -- '1', '3'
    repair                  varchar(20),                -- ซ่อมอู่ / ซ่อมห้าง
    sum_insured             integer         NOT NULL DEFAULT 0,
    accessory               varchar(3)      NOT NULL DEFAULT 'NO',
    accessory_amount        integer         NOT NULL DEFAULT 0,

    -- เบี้ยภาคสมัครใจ
    vol_net                 numeric(12,2)   NOT NULL DEFAULT 0,
    vol_stamp               numeric(10,2)   NOT NULL DEFAULT 0,
    vol_vat                 numeric(10,2)   NOT NULL DEFAULT 0,
    vol_total               numeric(12,2)   NOT NULL DEFAULT 0,

    -- พ.ร.บ.
    prb                     varchar(10)     NOT NULL DEFAULT 'ไม่รวม',  -- ไม่รวม / รวม
    prb_code                varchar(10),
    prb_net                 numeric(10,2)   NOT NULL DEFAULT 0,
    prb_stamp               numeric(8,2)    NOT NULL DEFAULT 0,
    prb_vat                 numeric(8,2)    NOT NULL DEFAULT 0,
    prb_total               numeric(10,2)   NOT NULL DEFAULT 0,

    -- ส่วนลด
    group_discount          varchar(10)     NOT NULL DEFAULT '0%',
    claim_discount          varchar(10)     NOT NULL DEFAULT '0%',
    driver_behavior_filter  varchar(20)     NOT NULL DEFAULT 'ไม่ระบุ',
    driver_behavior_discount varchar(20)   NOT NULL DEFAULT '-',

    -- รวมทั้งหมด (สมัครใจ + พ.ร.บ.)
    grand_total             numeric(12,2)   NOT NULL DEFAULT 0,

    created_at              timestamptz     NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Comments
-- ---------------------------------------------------------------------------
COMMENT ON TABLE  quotation_vehicles IS 'ข้อมูลรถแต่ละคันในใบเสนอราคา (flat rows สำหรับ query ง่าย)';
COMMENT ON COLUMN quotation_vehicles.quote_no       IS 'FK → quotation_queue.quote_no (รวม revision เช่น _V1)';
COMMENT ON COLUMN quotation_vehicles.vehicle_seq    IS 'ลำดับรถในใบเสนอราคา เริ่มจาก 1';
COMMENT ON COLUMN quotation_vehicles.vehicle_code   IS '110=เก๋ง,120=กระบะ4ประตู,210=ตู้,220=โดยสาร,320=บรรทุก,...';
COMMENT ON COLUMN quotation_vehicles.type           IS '1=ชั้น1, 3=ชั้น3';
COMMENT ON COLUMN quotation_vehicles.repair         IS 'ซ่อมอู่ / ซ่อมห้าง';
COMMENT ON COLUMN quotation_vehicles.accessory      IS 'YES / NO';
COMMENT ON COLUMN quotation_vehicles.prb            IS 'ไม่รวม / รวม';
COMMENT ON COLUMN quotation_vehicles.created_by     IS 'uuid ของ user ที่ออกใบเสนอราคา';

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
-- query ตาม quote_no (ดูรถทุกคันในใบเสนอราคาเดียว)
CREATE INDEX IF NOT EXISTS idx_qv_quote_no
    ON public.quotation_vehicles (quote_no);

-- query ตาม user (ดูรถทั้งหมดที่ user คนนี้ออก)
CREATE INDEX IF NOT EXISTS idx_qv_created_by
    ON public.quotation_vehicles (created_by);

-- query ตาม date range
CREATE INDEX IF NOT EXISTS idx_qv_quote_date
    ON public.quotation_vehicles (quote_date DESC);

-- query ตามทะเบียน (ค้นประวัติรถ)
CREATE INDEX IF NOT EXISTS idx_qv_plate
    ON public.quotation_vehicles (plate);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.quotation_vehicles ENABLE ROW LEVEL SECURITY;

-- ใช้ DO $$ เพื่อกัน error ถ้า policy มีอยู่แล้ว (idempotent)
DO $$
BEGIN

    -- admin เห็นทุก row
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'quotation_vehicles'
          AND policyname = 'admin_all_quotation_vehicles'
    ) THEN
        EXECUTE '
            CREATE POLICY "admin_all_quotation_vehicles"
                ON public.quotation_vehicles
                FOR ALL TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM public.user_profiles
                        WHERE id = auth.uid() AND role = ''admin'' AND is_active = true
                    )
                )
                WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM public.user_profiles
                        WHERE id = auth.uid() AND role = ''admin'' AND is_active = true
                    )
                )
        ';
    END IF;

    -- user ทั่วไป: อ่านได้เฉพาะ row ของตัวเอง
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'quotation_vehicles'
          AND policyname = 'user_read_own_quotation_vehicles'
    ) THEN
        EXECUTE '
            CREATE POLICY "user_read_own_quotation_vehicles"
                ON public.quotation_vehicles
                FOR SELECT TO authenticated
                USING (created_by = auth.uid())
        ';
    END IF;

    -- user ทั่วไป: INSERT ได้เฉพาะ row ของตัวเอง
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'quotation_vehicles'
          AND policyname = 'user_insert_own_quotation_vehicles'
    ) THEN
        EXECUTE '
            CREATE POLICY "user_insert_own_quotation_vehicles"
                ON public.quotation_vehicles
                FOR INSERT TO authenticated
                WITH CHECK (created_by = auth.uid())
        ';
    END IF;

END $$;

-- ---------------------------------------------------------------------------
-- Grant
-- ---------------------------------------------------------------------------
GRANT SELECT, INSERT ON public.quotation_vehicles TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.quotation_vehicles_id_seq TO authenticated;

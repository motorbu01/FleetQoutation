-- =============================================================================
-- Migration: Refactor quote_followup เป็น 1 row ต่อ 1 ใบเสนอราคา
--   - สร้าง row ตอนรันคิว (outcome = 'pending')
--   - อัปเดตตอนยืนยัน (accepted / rejected)
--   - auto-expire เมื่อ pending นานเกิน followup_expire_days
-- รันใน Supabase SQL Editor
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. แก้ CHECK constraint ของ outcome ให้รองรับ pending / expired
-- -----------------------------------------------------------------------------
ALTER TABLE public.quote_followup
    DROP CONSTRAINT IF EXISTS quote_followup_outcome_check;

ALTER TABLE public.quote_followup
    ADD CONSTRAINT quote_followup_outcome_check
    CHECK (outcome IN ('pending', 'accepted', 'rejected', 'expired'));

-- เปลี่ยน default เป็น pending
ALTER TABLE public.quote_followup
    ALTER COLUMN outcome SET DEFAULT 'pending';

-- -----------------------------------------------------------------------------
-- 2. เพิ่ม column ใหม่
-- -----------------------------------------------------------------------------
ALTER TABLE public.quote_followup ADD COLUMN IF NOT EXISTS agent_name    TEXT;
ALTER TABLE public.quote_followup ADD COLUMN IF NOT EXISTS username      TEXT;   -- ผู้ออกงาน (display_name snapshot)
ALTER TABLE public.quote_followup ADD COLUMN IF NOT EXISTS issuer_branch TEXT;   -- ฝ่าย/สาขา snapshot
ALTER TABLE public.quote_followup ADD COLUMN IF NOT EXISTS confirmed_at  TIMESTAMPTZ;  -- เวลายืนยัน accepted/rejected
ALTER TABLE public.quote_followup ADD COLUMN IF NOT EXISTS expired_at    TIMESTAMPTZ;  -- เวลาที่ระบบ mark expired

COMMENT ON COLUMN public.quote_followup.outcome      IS 'pending | accepted | rejected | expired';
COMMENT ON COLUMN public.quote_followup.created_at   IS 'วันขึ้น pending (เริ่มนับ expire)';
COMMENT ON COLUMN public.quote_followup.confirmed_at IS 'เวลายืนยัน accepted/rejected';
COMMENT ON COLUMN public.quote_followup.expired_at   IS 'เวลาที่ระบบ mark expired';

-- -----------------------------------------------------------------------------
-- 3. unique constraint บน quote_no (1 row ต่อ 1 ใบ — ผูก base quote_no)
--    ต้อง clean duplicate เก่าก่อน (ถ้ามี) — เก็บ row ล่าสุด
-- -----------------------------------------------------------------------------
-- ลบ duplicate เก่า เก็บเฉพาะ row id มากสุด (ล่าสุด) ต่อ quote_no
DELETE FROM public.quote_followup a
    USING public.quote_followup b
    WHERE a.quote_no = b.quote_no
      AND a.id < b.id;

ALTER TABLE public.quote_followup
    DROP CONSTRAINT IF EXISTS quote_followup_quote_no_key;

ALTER TABLE public.quote_followup
    ADD CONSTRAINT quote_followup_quote_no_key UNIQUE (quote_no);

-- -----------------------------------------------------------------------------
-- 4. settings: followup_expire_days (default 30)
-- -----------------------------------------------------------------------------
INSERT INTO public.system_settings (key, value, description) VALUES
    ('followup_expire_days', '30', 'จำนวนวันที่ pending ค้างได้ก่อน auto-expire (0 = ไม่หมดอายุ)')
ON CONFLICT (key) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 5. FK followup_requests.followup_id → quote_followup(id)
--    เดิม ON DELETE CASCADE — ตอนนี้ไม่ลบ quote_followup แล้ว (ใช้ UPDATE reset)
--    เปลี่ยนเป็น ON DELETE SET NULL เผื่อกรณี edge case
-- -----------------------------------------------------------------------------
ALTER TABLE public.followup_requests
    DROP CONSTRAINT IF EXISTS followup_requests_followup_id_fkey;

ALTER TABLE public.followup_requests
    ALTER COLUMN followup_id DROP NOT NULL;

ALTER TABLE public.followup_requests
    ADD CONSTRAINT followup_requests_followup_id_fkey
    FOREIGN KEY (followup_id) REFERENCES public.quote_followup(id) ON DELETE SET NULL;

-- ตรวจสอบ (optional)
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'quote_followup' ORDER BY ordinal_position;

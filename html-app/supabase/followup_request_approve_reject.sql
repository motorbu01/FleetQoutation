-- =============================================================================
-- Migration: Approve/Reject followup requests
-- รันใน Supabase SQL Editor
-- =============================================================================

-- 1. เพิ่ม column request_note (เหตุผลที่ user ขอแก้)
ALTER TABLE public.followup_requests
    ADD COLUMN IF NOT EXISTS request_note TEXT;

-- 2. แก้ CHECK constraint ให้รองรับ 'rejected'
--    ต้อง DROP เดิมก่อนแล้ว ADD ใหม่
ALTER TABLE public.followup_requests
    DROP CONSTRAINT IF EXISTS followup_requests_status_check;

ALTER TABLE public.followup_requests
    ADD CONSTRAINT followup_requests_status_check
    CHECK (status IN ('pending', 'resolved', 'rejected'));

-- 3. admin_note มีอยู่แล้วใน schema — ไม่ต้องสร้างใหม่
--    resolved_by, resolved_at มีอยู่แล้วเช่นกัน

-- ตรวจสอบ columns ที่มี (optional — comment ไว้ให้ตรวจ)
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'followup_requests' ORDER BY ordinal_position;

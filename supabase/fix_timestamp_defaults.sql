-- =============================================================================
-- Fix: เปลี่ยน default ของ column ที่เพี้ยน (AT TIME ZONE Bangkok) กลับเป็น now() (UTC)
-- หลักการ: DB เก็บ UTC เสมอ, แปลงเป็นเวลาไทยตอนแสดงผลใน JS
-- รันใน Supabase SQL Editor
-- =============================================================================

ALTER TABLE public.login_log
    ALTER COLUMN logged_in_at SET DEFAULT now();

ALTER TABLE public.quotation_queue
    ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.user_profiles
    ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.user_profiles
    ALTER COLUMN updated_at SET DEFAULT now();

-- ตรวจซ้ำหลังรัน (ควรได้ now() ทั้งหมด ไม่มี AT TIME ZONE)
-- SELECT table_name, column_name, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND data_type LIKE 'timestamp%'
-- ORDER BY table_name, ordinal_position;

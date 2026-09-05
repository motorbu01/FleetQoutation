-- =====================================================================
-- Migrate: เพิ่ม issuer_name, issuer_branch ใน user_profiles
-- รัน SQL นี้ใน Supabase SQL Editor ก่อน import_users.ps1
-- =====================================================================

ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS issuer_name   text,
    ADD COLUMN IF NOT EXISTS issuer_branch text;

COMMENT ON COLUMN public.user_profiles.issuer_name   IS 'ชื่อผู้ออกงาน (auto-fill ในฟอร์ม)';
COMMENT ON COLUMN public.user_profiles.issuer_branch IS 'ฝ่าย/สาขา (auto-fill ในฟอร์ม)';

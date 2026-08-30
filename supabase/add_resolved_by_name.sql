-- =============================================================================
-- Migration: เพิ่ม column resolved_by_name (ชื่อ admin ที่ approve/reject)
-- รันใน Supabase SQL Editor
-- =============================================================================

ALTER TABLE public.followup_requests
    ADD COLUMN IF NOT EXISTS resolved_by_name TEXT;

COMMENT ON COLUMN public.followup_requests.resolved_by_name IS 'ชื่อ admin ที่ approve/reject (snapshot display_name)';

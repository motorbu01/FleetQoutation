-- =============================================================================
-- Migration: เพิ่ม column latest_quote_no ใน quote_followup
--   - quote_no       = base quote_no (strip _V) → ใช้ dedup / คงสถานะ (คงเดิม)
--   - latest_quote_no = เลข revision ล่าสุด เช่น FQ3108260009_V1 (สำหรับแสดงผล)
--
-- Backfill: เติมค่าเริ่มต้นให้ row เดิมจาก quotation_queue (revision สูงสุด)
-- =============================================================================

-- 1. เพิ่ม column
ALTER TABLE public.quote_followup
    ADD COLUMN IF NOT EXISTS latest_quote_no TEXT;

COMMENT ON COLUMN public.quote_followup.latest_quote_no
    IS 'เลขใบเสนอราคา revision ล่าสุด (เช่น FQ..._V1) — quote_no ยังเก็บ base ไว้ dedup';

-- 2. Backfill จาก quotation_queue: หา revision ล่าสุดของแต่ละ base quote_no
--    เรียง _V จากมากไปน้อย (V ที่ไม่มีเลข = revision 0)
WITH latest AS (
    SELECT DISTINCT ON (regexp_replace(quote_no, '_V\d+$', '')) 
           regexp_replace(quote_no, '_V\d+$', '') AS base_no,
           quote_no                                AS latest_no
    FROM public.quotation_queue
    ORDER BY regexp_replace(quote_no, '_V\d+$', ''),
             COALESCE(NULLIF(regexp_replace(quote_no, '^.*_V(\d+)$', '\1'), quote_no), '0')::int DESC
)
UPDATE public.quote_followup f
SET    latest_quote_no = l.latest_no
FROM   latest l
WHERE  f.quote_no = l.base_no
  AND  (f.latest_quote_no IS NULL OR f.latest_quote_no <> l.latest_no);

-- 3. row ที่ยังว่าง (ไม่มีใน quotation_queue) ให้ fallback = quote_no เดิม
UPDATE public.quote_followup
SET    latest_quote_no = quote_no
WHERE  latest_quote_no IS NULL;

-- ตรวจสอบ (optional)
-- SELECT quote_no, latest_quote_no, outcome FROM public.quote_followup ORDER BY id;

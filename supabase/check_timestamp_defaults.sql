-- =============================================================================
-- ตรวจสอบ default ของทุก column ที่เป็น timestamp/timestamptz
-- รันใน Supabase SQL Editor แล้วดูผลว่า column ไหน default เพี้ยน (มี AT TIME ZONE)
-- =============================================================================

SELECT
    table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (data_type LIKE 'timestamp%' OR column_default ILIKE '%time zone%' OR column_default ILIKE '%bangkok%')
ORDER BY table_name, ordinal_position;

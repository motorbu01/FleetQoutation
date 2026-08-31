-- =============================================================================
-- Migration: เพิ่ม max_driver_behavior_lv ใน system_settings
-- จำกัดระดับส่วนลดพฤติกรรมผู้ขับขี่ (LV) ที่เลือกได้ในการ์ด
-- รันใน Supabase SQL Editor
-- =============================================================================

-- ค่า: '1'..'5' (1 = เปิดแค่ LV1 (0%), 5 = เปิดครบ LV5 (40%))
-- default '1' — ปัจจุบันใช้จริงแค่ LV1 (ระบบเผื่อ LV2-5 ไว้อนาคต)
-- ON CONFLICT DO NOTHING — รันซ้ำได้ปลอดภัย
insert into public.system_settings (key, value, description) values
    ('max_driver_behavior_lv', '1', 'ระดับส่วนลดพฤติกรรมผู้ขับขี่สูงสุดที่เลือกได้ (LV 1-5) — จำกัดตัวเลือกในการ์ด/import')
on conflict (key) do nothing;

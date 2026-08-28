-- =============================================================================
-- Migration: เพิ่ม driver_name_feature_enabled ใน system_settings
-- รันใน Supabase SQL Editor
-- =============================================================================

-- เพิ่ม key ใหม่ (ON CONFLICT DO NOTHING — รันซ้ำได้ปลอดภัย)
insert into public.system_settings (key, value, description) values
    ('driver_name_feature_enabled', 'false', 'เปิด/ปิดฟีเจอร์ระบุชื่อผู้ขับขี่ (true/false) — ปิดไว้จนกว่า OIC จะบังคับใช้')
on conflict (key) do nothing;

-- =============================================================================
-- Migration: เพิ่ม max_vehicles_per_quote ใน system_settings
-- จำกัดจำนวนรถสูงสุดต่อ 1 ใบเสนอราคา (บังคับตอนเพิ่มรถ + ตอนออกใบ)
-- รันใน Supabase SQL Editor
-- =============================================================================

-- ค่า: จำนวนคันสูงสุดต่อใบ (เช่น '20'), '0' = ไม่จำกัด
-- default '20' — เพดานที่สมเหตุผลสำหรับงานกลุ่มทั่วไป
-- ON CONFLICT DO NOTHING — รันซ้ำได้ปลอดภัย
insert into public.system_settings (key, value, description) values
    ('max_vehicles_per_quote', '20', 'จำนวนรถสูงสุดต่อ 1 ใบเสนอราคา (0 = ไม่จำกัด)')
on conflict (key) do nothing;

-- ตรวจผลลัพธ์
select key, value, description
from public.system_settings
where key = 'max_vehicles_per_quote';

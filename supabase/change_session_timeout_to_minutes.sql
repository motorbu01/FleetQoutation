-- =============================================================================
-- Migration: เปลี่ยน session timeout จากหน่วย "ชั่วโมง" เป็น "นาที"
--   เดิม: key = session_timeout_hours  (เช่น "8" = 8 ชั่วโมง)
--   ใหม่: key = session_timeout_minutes (เช่น "60" = 60 นาที)
-- รันใน Supabase SQL Editor (รันซ้ำได้ปลอดภัย)
-- =============================================================================

-- 1) เพิ่ม key ใหม่ session_timeout_minutes
--    ถ้ามี key เดิม (session_timeout_hours) อยู่ → แปลงค่า (ชั่วโมง × 60 = นาที)
--    ถ้าไม่มี → ใช้ค่า default 60 นาที
insert into public.system_settings (key, value, description)
values (
    'session_timeout_minutes',
    coalesce(
        (
            select (nullif(value, '')::int * 60)::text
            from public.system_settings
            where key = 'session_timeout_hours'
        ),
        '60'
    ),
    'ระยะเวลา session ก่อนหมดอายุ (นาที) — 0 = ไม่หมดอายุ'
)
on conflict (key) do update
    set value = excluded.value,
        description = excluded.description;

-- 2) ลบ key เดิม session_timeout_hours (ไม่ใช้แล้ว)
delete from public.system_settings
where key = 'session_timeout_hours';

-- 3) ตรวจผลลัพธ์
select key, value, description
from public.system_settings
where key = 'session_timeout_minutes';

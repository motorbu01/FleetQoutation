-- =============================================================================
-- Migration: เพิ่ม accepted_quote_no ใน quote_followup
-- เก็บ "version ที่ลูกค้าเลือกจริง" ตอน accept (เช่น FQ0209260001 หรือ ..._V2)
-- ใช้เมื่อ user revise หลายรอบแต่ลูกค้าเลือก version ที่ไม่ใช่ตัวล่าสุด
-- รันใน Supabase SQL Editor
-- =============================================================================

-- null = ยังไม่ระบุ (ใบเก่า / ยังไม่ accept) → ระบบ fallback ใช้ latest_quote_no เหมือนเดิม
alter table public.quote_followup
    add column if not exists accepted_quote_no text;

comment on column public.quote_followup.accepted_quote_no is
    'version ที่ลูกค้าเลือกจริงตอน accept (null = ใช้ latest_quote_no)';

-- ตรวจผลลัพธ์
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'quote_followup'
  and column_name = 'accepted_quote_no';

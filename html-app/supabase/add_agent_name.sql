-- =============================================================================
-- Migration: เพิ่ม column agent_name (ชื่อตัวแทน/นายหน้า)
-- รันใน Supabase SQL Editor
-- =============================================================================

-- 1. quotation_queue (ระดับใบเสนอราคา)
ALTER TABLE public.quotation_queue
    ADD COLUMN IF NOT EXISTS agent_name TEXT;

COMMENT ON COLUMN public.quotation_queue.agent_name IS 'ชื่อตัวแทน/นายหน้า (ไม่มี = "ไม่มี")';

-- 2. quotation_vehicles (ระดับคันรถ - ซ้ำทุกคันในใบเดียวกัน)
ALTER TABLE public.quotation_vehicles
    ADD COLUMN IF NOT EXISTS agent_name TEXT;

COMMENT ON COLUMN public.quotation_vehicles.agent_name IS 'ชื่อตัวแทน/นายหน้า (ไม่มี = "ไม่มี")';

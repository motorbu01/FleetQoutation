-- =============================================================================
-- Migration: เพิ่ม column breakdown เบี้ยรายคัน ใน quotation_vehicles
--   ใช้สำหรับ generate "ไฟล์รายละเอียดคำนวณ" จาก DB (ไม่ต้องอ่านจากฟอร์ม)
--   - calc_base   = เบี้ยฐาน (breakdown.base)
--   - calc_gross  = gross premium (breakdown.grossPremium)
--   - calc_attach = เบี้ยอุปกรณ์/attach (breakdown.attach)
--   - calc_ry31   = ry31 (breakdown.ry31)
--
-- ค่าอื่น (ความคุ้มครอง, packageId, maxAge) reconstruct จาก code/type/repair
-- ได้เลย ไม่ต้องเก็บ
-- =============================================================================

ALTER TABLE public.quotation_vehicles ADD COLUMN IF NOT EXISTS calc_base   numeric(12,2) DEFAULT 0;
ALTER TABLE public.quotation_vehicles ADD COLUMN IF NOT EXISTS calc_gross  numeric(12,2) DEFAULT 0;
ALTER TABLE public.quotation_vehicles ADD COLUMN IF NOT EXISTS calc_attach numeric(12,2) DEFAULT 0;
ALTER TABLE public.quotation_vehicles ADD COLUMN IF NOT EXISTS calc_ry31   numeric(12,2) DEFAULT 0;

COMMENT ON COLUMN public.quotation_vehicles.calc_base   IS 'เบี้ยฐาน (breakdown.base) สำหรับไฟล์รายละเอียดคำนวณ';
COMMENT ON COLUMN public.quotation_vehicles.calc_gross  IS 'gross premium (breakdown.grossPremium)';
COMMENT ON COLUMN public.quotation_vehicles.calc_attach IS 'เบี้ยอุปกรณ์/attach (breakdown.attach)';
COMMENT ON COLUMN public.quotation_vehicles.calc_ry31   IS 'ry31 (breakdown.ry31)';

-- ตรวจสอบ (optional)
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'quotation_vehicles' AND column_name LIKE 'calc_%';

-- =============================================================================
-- Migration: rename repair keys in quotation_vehicles
-- garage → service_center  (ซ่อมห้าง/ซ่อมศูนย์)
-- agent  → garage          (ซ่อมอู่)
-- =============================================================================
-- ต้องรันใน 2 ขั้นตอน เพื่อไม่ให้ค่าชนกัน:
--   Step 1: garage → service_center  (ค่าเดิม garage = ซ่อมห้าง)
--   Step 2: agent  → garage          (ค่าเดิม agent  = ซ่อมอู่)
-- =============================================================================

-- Step 1: ซ่อมห้าง → service_center
UPDATE quotation_vehicles
SET repair = 'service_center'
WHERE repair = 'ซ่อมห้าง';

-- Step 2: ซ่อมอู่ → garage
UPDATE quotation_vehicles
SET repair = 'garage'
WHERE repair = 'ซ่อมอู่';

-- Verify
SELECT repair, COUNT(*) AS cnt
FROM quotation_vehicles
GROUP BY repair
ORDER BY repair;

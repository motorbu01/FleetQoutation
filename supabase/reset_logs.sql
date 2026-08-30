-- =============================================================================
-- Reset Logs — ลบข้อมูล transaction/log ทั้งหมดให้เหมือนเริ่มใหม่
-- รันใน Supabase SQL Editor
--
-- เก็บไว้ (ไม่ลบ): user_profiles, system_settings, followup_reasons, car_master ฯลฯ
-- ลบ + reset id: login_log, notifications, followup_requests, quote_followup,
--                quotation_vehicles, quotation_queue
--
-- TRUNCATE + RESTART IDENTITY: ลบเร็ว + reset auto-increment id กลับเป็น 1
-- ⚠️  ลบข้อมูลถาวร — ไม่สามารถกู้คืนได้
-- =============================================================================

TRUNCATE TABLE
  followup_requests,
  login_log,
  notifications,
  quotation_queue,
  quotation_vehicles,
  quote_followup
RESTART IDENTITY;

-- หมายเหตุ: ถ้าเจอ error เรื่อง FK จาก table อื่น ให้เติม CASCADE ต่อท้าย:
-- TRUNCATE TABLE ... RESTART IDENTITY CASCADE;

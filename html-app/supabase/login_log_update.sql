-- =============================================================================
-- login_log — เพิ่ม column action + ip_address + session_id
-- รัน SQL นี้ใน Supabase SQL Editor เพื่ออัปเดต login_log table ที่มีอยู่
-- =============================================================================
-- action: 'login' | 'logout' | 'session_expired'
-- ip_address: จาก client (best-effort ผ่าน browser)
-- session_id: ใช้จับคู่ login↔logout (random UUID สร้างตอน login)
-- =============================================================================

-- เพิ่ม column ใหม่ (ถ้ายังไม่มี)
ALTER TABLE public.login_log
    ADD COLUMN IF NOT EXISTS action         text        NOT NULL DEFAULT 'login'
                                                            CHECK (action IN ('login', 'logout', 'session_expired')),
    ADD COLUMN IF NOT EXISTS session_id     uuid,       -- ใช้จับคู่ login↔logout
    ADD COLUMN IF NOT EXISTS logged_out_at  timestamptz; -- เวลา logout (set ตอนบันทึก action='logout')

-- Comment
COMMENT ON COLUMN public.login_log.action           IS 'login | logout | session_expired';
COMMENT ON COLUMN public.login_log.session_id        IS 'UUID สุ่มตอน login — ใช้จับคู่ logout record';
COMMENT ON COLUMN public.login_log.logged_out_at     IS 'เวลา logout (เฉพาะ action=logout/session_expired)';

-- Index เพิ่มเติม
CREATE INDEX IF NOT EXISTS login_log_session_id_idx ON public.login_log (session_id)
    WHERE session_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS login_log_action_idx ON public.login_log (action);

-- เพิ่ม policy: user อ่าน log ของตัวเอง (เดิมมีแค่ admin)
-- ตรวจว่า policy ชื่อ user_read_own_login_log มีอยู่แล้วไหม
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename  = 'login_log'
          AND policyname = 'user_read_own_login_log'
    ) THEN
        EXECUTE '
            CREATE POLICY "user_read_own_login_log" ON public.login_log
                FOR SELECT
                USING (user_id = auth.uid())
        ';
    END IF;
END $$;

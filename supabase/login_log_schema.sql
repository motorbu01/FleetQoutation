-- =====================================================================
-- login_log table — บันทึกการ login ของ user แต่ละคน
-- รัน SQL นี้ใน Supabase SQL Editor
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.login_log (
    id            bigserial PRIMARY KEY,
    user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email         text        NOT NULL,
    display_name  text,
    role          text,
    logged_in_at  timestamptz NOT NULL DEFAULT now(),
    user_agent    text
);

-- Index สำหรับ query ตาม date range
CREATE INDEX IF NOT EXISTS login_log_logged_in_at_idx ON public.login_log (logged_in_at DESC);
CREATE INDEX IF NOT EXISTS login_log_user_id_idx      ON public.login_log (user_id);

-- RLS: เปิดใช้งาน
ALTER TABLE public.login_log ENABLE ROW LEVEL SECURITY;

-- admin เห็นทุก row / user ทั่วไปเห็นแค่ของตัวเอง
CREATE POLICY "admin_read_all_login_log" ON public.login_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "user_insert_own_login_log" ON public.login_log
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Grant
GRANT SELECT, INSERT ON public.login_log TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.login_log_id_seq TO authenticated;

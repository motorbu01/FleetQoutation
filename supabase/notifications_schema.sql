-- ===================================================================
-- Notification System + Follow-up Reset Request
-- Tables:
--   notifications       — กล่องแจ้งเตือนของแต่ละ user (general purpose)
--   followup_requests   — คำขอ reset follow-up จาก user → admin
-- ===================================================================

-- ---------------------------------------------------------------
-- 1. notifications
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title       TEXT        NOT NULL,
    body        TEXT,
    type        TEXT        NOT NULL DEFAULT 'system',
    -- type values: 'followup_reset' | 'followup_request' | 'system'
    ref_id      TEXT,       -- เลขใบเสนอราคา หรือ id อื่นที่เกี่ยวข้อง
    is_read     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id    ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read    ON public.notifications(user_id, is_read);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- User เห็นเฉพาะของตัวเอง
CREATE POLICY "notif_select_own" ON public.notifications
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- User mark as read ได้เฉพาะของตัวเอง
CREATE POLICY "notif_update_own" ON public.notifications
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- admin INSERT ได้ทุก row (ส่ง noti ให้ user)
CREATE POLICY "notif_insert_admin" ON public.notifications
    FOR INSERT TO authenticated
    WITH CHECK (
        -- ส่งให้ตัวเอง หรือเป็น admin
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- admin ลบได้ทุก row
CREATE POLICY "notif_delete_admin" ON public.notifications
    FOR DELETE TO authenticated
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ---------------------------------------------------------------
-- 2. followup_requests
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.followup_requests (
    id              BIGSERIAL PRIMARY KEY,
    followup_id     BIGINT      NOT NULL REFERENCES public.quote_followup(id) ON DELETE CASCADE,
    quote_no        TEXT        NOT NULL,
    requested_by    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    requester_name  TEXT,       -- snapshot display_name ตอนส่งคำขอ
    status          TEXT        NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending', 'resolved')),
    admin_note      TEXT,       -- note จาก admin (optional)
    resolved_by     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_followup_req_status       ON public.followup_requests(status);
CREATE INDEX IF NOT EXISTS idx_followup_req_requested_by ON public.followup_requests(requested_by);

ALTER TABLE public.followup_requests ENABLE ROW LEVEL SECURITY;

-- User เห็นเฉพาะคำขอของตัวเอง
CREATE POLICY "fu_req_select_own" ON public.followup_requests
    FOR SELECT TO authenticated
    USING (
        requested_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- User INSERT ได้เฉพาะในนามตัวเอง
CREATE POLICY "fu_req_insert_own" ON public.followup_requests
    FOR INSERT TO authenticated
    WITH CHECK (requested_by = auth.uid());

-- admin UPDATE ได้ทุก row (resolve)
CREATE POLICY "fu_req_update_admin" ON public.followup_requests
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- admin ลบได้ทุก row
CREATE POLICY "fu_req_delete_admin" ON public.followup_requests
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ---------------------------------------------------------------
-- Helper: นับ unread notifications ของ user ปัจจุบัน
-- (ใช้ใน JS แทน SELECT COUNT ตรงๆ เพื่อความสะดวก)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_unread_notification_count()
RETURNS INT LANGUAGE sql SECURITY DEFINER AS $$
    SELECT COUNT(*)::INT FROM public.notifications
    WHERE user_id = auth.uid() AND is_read = FALSE;
$$;

-- Helper: นับ pending followup_requests (สำหรับ admin badge)
CREATE OR REPLACE FUNCTION public.get_pending_followup_request_count()
RETURNS INT LANGUAGE sql SECURITY DEFINER AS $$
    SELECT COUNT(*)::INT FROM public.followup_requests
    WHERE status = 'pending';
$$;

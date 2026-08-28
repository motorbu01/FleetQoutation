-- =============================================================================
-- Migration: Trigger notify admins when user submits followup reset request
-- รันใน Supabase SQL Editor
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Trigger function — INSERT notifications ให้ admin ทุกคนที่ is_active = true
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_admins_on_reset_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- INSERT notification row ให้ admin ทุกคน
    INSERT INTO public.notifications (user_id, title, body, type, ref_id, is_read)
    SELECT
        up.id,
        'คำขอแก้ไข: ใบ ' || NEW.quote_no,
        COALESCE(NEW.requester_name, 'User') || ' ขอแก้ไขผลใบเสนอราคา ' || NEW.quote_no,
        'followup_request',
        NEW.quote_no,
        FALSE
    FROM public.user_profiles up
    WHERE up.role = 'admin'
      AND up.is_active = TRUE;

    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Bind trigger กับ followup_requests ON INSERT
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_notify_admins_on_reset_request ON public.followup_requests;

CREATE TRIGGER trg_notify_admins_on_reset_request
    AFTER INSERT ON public.followup_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_admins_on_reset_request();

-- -----------------------------------------------------------------------------
-- 3. RLS policy — อนุญาตให้ postgres trigger (SECURITY DEFINER) INSERT ได้
--    notifications_schema.sql มี notif_insert_admin อยู่แล้ว
--    เพิ่ม policy สำหรับ service role / trigger เผื่อ schema เก่าไม่มี
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'notifications'
          AND policyname = 'notif_insert_service'
    ) THEN
        CREATE POLICY "notif_insert_service" ON public.notifications
            FOR INSERT
            WITH CHECK (true);
    END IF;
END;
$$;

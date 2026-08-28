-- ===================================================================
-- Quote Follow-up System
-- ตาราง: followup_reasons  — เหตุผลที่ลูกค้าไม่ทำประกัน (admin จัดการได้)
--        quote_followup    — บันทึกผลการตอบกลับจากลูกค้า
-- ===================================================================

-- ---------------------------------------------------------------
-- 1. followup_reasons
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.followup_reasons (
    id          SERIAL PRIMARY KEY,
    reason_text TEXT        NOT NULL,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    sort_order  INT         NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed เหตุผลเริ่มต้น
INSERT INTO public.followup_reasons (reason_text, sort_order) VALUES
    ('ราคาสูงเกินไป',           10),
    ('ลูกค้าเลือกบริษัทอื่น',    20),
    ('ลูกค้ายังไม่ตัดสินใจ',     30),
    ('ไม่ต้องการทำประกันแล้ว',   40),
    ('อื่นๆ',                   999)
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE public.followup_reasons ENABLE ROW LEVEL SECURITY;

-- ทุก authenticated user อ่านได้
CREATE POLICY "followup_reasons_select" ON public.followup_reasons
    FOR SELECT TO authenticated USING (TRUE);

-- เฉพาะ admin เพิ่ม/แก้/ลบ
CREATE POLICY "followup_reasons_admin_all" ON public.followup_reasons
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ---------------------------------------------------------------
-- 2. quote_followup
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quote_followup (
    id              BIGSERIAL PRIMARY KEY,
    quote_no        TEXT        NOT NULL,        -- เลขใบเสนอราคา เช่น FQ2808260001
    client_name     TEXT,                        -- ชื่อลูกค้า (snapshot)
    outcome         TEXT        NOT NULL CHECK (outcome IN ('accepted', 'rejected')),
    reason_id       INT         REFERENCES public.followup_reasons(id) ON DELETE SET NULL,
    reason_other    TEXT,                        -- กรณีเลือก "อื่นๆ"
    note            TEXT,                        -- หมายเหตุเพิ่มเติม (optional)
    created_by      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quote_followup_created_by ON public.quote_followup(created_by);
CREATE INDEX IF NOT EXISTS idx_quote_followup_quote_no   ON public.quote_followup(quote_no);

-- Trigger: auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_quote_followup_updated_at ON public.quote_followup;
CREATE TRIGGER trg_quote_followup_updated_at
    BEFORE UPDATE ON public.quote_followup
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE public.quote_followup ENABLE ROW LEVEL SECURITY;

-- User เห็นเฉพาะของตัวเอง, admin เห็นทั้งหมด
CREATE POLICY "followup_select_own" ON public.quote_followup
    FOR SELECT TO authenticated
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "followup_insert_own" ON public.quote_followup
    FOR INSERT TO authenticated
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "followup_update_own" ON public.quote_followup
    FOR UPDATE TO authenticated
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "followup_delete_own" ON public.quote_followup
    FOR DELETE TO authenticated
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

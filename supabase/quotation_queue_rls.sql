-- =============================================================================
-- RLS Policies สำหรับ quotation_queue
-- รันใน Supabase SQL Editor
-- =============================================================================

-- ตรวจสอบก่อนว่า RLS เปิดอยู่ไหม (ถ้ายังไม่เปิดให้ uncomment บรรทัดนี้)
-- ALTER TABLE public.quotation_queue ENABLE ROW LEVEL SECURITY;

-- Policy 1: authenticated ทุกคนอ่านได้ (INSERT ผ่านมาแล้ว ต้องให้ SELECT ด้วย)
DROP POLICY IF EXISTS "authenticated_read_quotation_queue" ON public.quotation_queue;
CREATE POLICY "authenticated_read_quotation_queue"
    ON public.quotation_queue FOR SELECT
    TO authenticated
    USING (true);

-- Policy 2: authenticated ทุกคน INSERT ได้ (ออกใบเสนอราคา)
DROP POLICY IF EXISTS "authenticated_insert_quotation_queue" ON public.quotation_queue;
CREATE POLICY "authenticated_insert_quotation_queue"
    ON public.quotation_queue FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy 3: admin อัปเดต/ลบได้
DROP POLICY IF EXISTS "admin_manage_quotation_queue" ON public.quotation_queue;
CREATE POLICY "admin_manage_quotation_queue"
    ON public.quotation_queue FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin' AND is_active = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin' AND is_active = true
        )
    );

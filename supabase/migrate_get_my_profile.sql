-- =====================================================================
-- Re-create get_my_profile() เพื่อให้รู้จัก issuer_name, issuer_branch
-- รัน SQL นี้ใน Supabase SQL Editor
-- =====================================================================

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_profile  json;
    v_settings json;
BEGIN
    SELECT json_build_object(
        'id',            p.id,
        'display_name',  p.display_name,
        'role',          p.role,
        'is_active',     p.is_active,
        'issuer_name',   p.issuer_name,
        'issuer_branch', p.issuer_branch
    ) INTO v_profile
    FROM public.user_profiles p
    WHERE p.id = auth.uid();

    SELECT json_object_agg(key, value) INTO v_settings
    FROM public.system_settings;

    RETURN json_build_object(
        'profile',  v_profile,
        'settings', v_settings
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;

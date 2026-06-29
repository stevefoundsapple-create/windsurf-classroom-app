CREATE OR REPLACE FUNCTION delete_user_account_secure(
    p_user_id TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := p_user_id::UUID;

    -- Delete notification preferences
    DELETE FROM notification_preferences WHERE user_id = v_user_id;

    -- Delete device tokens
    DELETE FROM device_tokens WHERE user_id = v_user_id;

    -- Unlink parent from students
    UPDATE students SET parent_id = NULL WHERE parent_id = v_user_id;

    -- Delete profile
    DELETE FROM profiles WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION delete_user_account_secure(TEXT) TO authenticated;

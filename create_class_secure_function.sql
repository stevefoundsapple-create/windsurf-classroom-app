-- Drop the old function first (if it exists with UUID params)
DROP FUNCTION IF EXISTS create_class_secure(UUID, TEXT, UUID);

-- Create the updated function with TEXT parameters including class_code
CREATE OR REPLACE FUNCTION create_class_secure(
    p_id TEXT,
    p_name TEXT,
    p_teacher_id TEXT,
    p_class_code TEXT
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
    v_teacher_id UUID;
BEGIN
    v_id := p_id::UUID;
    v_teacher_id := p_teacher_id::UUID;
    
    INSERT INTO classes (id, teacher_id, name, class_code)
    VALUES (v_id, v_teacher_id, p_name, p_class_code);
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION create_class_secure(TEXT, TEXT, TEXT, TEXT) TO authenticated;

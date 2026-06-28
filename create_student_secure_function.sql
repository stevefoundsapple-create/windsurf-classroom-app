-- Create a secure function to insert students bypassing RLS
CREATE OR REPLACE FUNCTION create_student_secure(
    p_id TEXT,
    p_user_id TEXT,
    p_name TEXT,
    p_class_id TEXT,
    p_parent_id TEXT,
    p_point_total INTEGER
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
    v_user_id UUID;
    v_class_id UUID;
    v_parent_id UUID;
BEGIN
    v_id := p_id::UUID;
    v_user_id := p_user_id::UUID;
    v_class_id := p_class_id::UUID;
    
    IF p_parent_id IS NOT NULL AND p_parent_id != '' THEN
        v_parent_id := p_parent_id::UUID;
    ELSE
        v_parent_id := NULL;
    END IF;
    
    INSERT INTO students (id, user_id, name, class_id, parent_id, point_total)
    VALUES (v_id, v_user_id, p_name, v_class_id, v_parent_id, p_point_total);
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION create_student_secure(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER) TO authenticated;

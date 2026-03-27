DECLARE
  v_res VARCHAR2(4000);
BEGIN
  UTIL.copy_table(
    p_source_scheme => 'SYSTEM', 
    p_list_table    => 'HELP', 
    p_copy_data     => TRUE, 
    po_result       => v_res
  );
  DBMS_OUTPUT.PUT_LINE(v_res);
END;
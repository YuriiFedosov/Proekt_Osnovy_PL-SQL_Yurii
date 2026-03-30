BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_API_NBU_SYNC',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN util.api_nbu_sync; END;', 
    start_date      => SYSDATE,         
    repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Ежедневная синхронизация валют НБУ'
  );
END;
/
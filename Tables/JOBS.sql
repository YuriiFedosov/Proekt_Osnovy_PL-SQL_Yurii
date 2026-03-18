CREATE TABLE JOBS (
    job_id      VARCHAR2(10),
    job_title   VARCHAR2(35) NOT NULL,
    min_salary  NUMBER(6,0),
    max_salary  NUMBER(6,0),
    -- Первинний ключ
    CONSTRAINT job_id_pk PRIMARY KEY (job_id)
);
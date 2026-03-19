CREATE TABLE EMPLOYEES_HISTORY (
    employee_id      NUMBER,
    first_name       VARCHAR2(50),
    last_name        VARCHAR2(50),
    job_id           VARCHAR2(20),
    department_id    NUMBER,
    fire_date        DATE DEFAULT SYSDATE
);
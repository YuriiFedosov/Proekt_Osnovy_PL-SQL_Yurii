CREATE OR REPLACE PACKAGE util AS

    gc_min_salary CONSTANT NUMBER := 2000;
    
    TYPE rec_value_list IS RECORD (value_list VARCHAR2(100));
    TYPE tab_value_list IS TABLE OF rec_value_list;
    
    TYPE t_region_cnt_rec IS RECORD (
                                region_name regions.region_name%TYPE,
                                emp_count   NUMBER);

  TYPE t_region_cnt_tab IS TABLE OF t_region_cnt_rec;
------------------
    FUNCTION add_years(p_date IN DATE,
                        p_year IN NUMBER) RETURN DATE;
                        
------------------- 
    FUNCTION table_from_list(p_list_val IN VARCHAR2,
                         p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED;
            
-------------------

 FUNCTION get_region_cnt_emp (
                            p_department_id IN employees.department_id%TYPE DEFAULT NULL)
                            RETURN t_region_cnt_tab PIPELINED;
  
-------------------
    FUNCTION get_dep_name(p_employee_id IN NUMBER) RETURN VARCHAR2;

----------------------
    FUNCTION get_sum_price_sales(p_table IN VARCHAR2) RETURN NUMBER;
---------------------
    PROCEDURE add_new_jobs( p_job_id    IN VARCHAR2,
                           p_job_title  IN VARCHAR2,
                           p_min_salary IN VARCHAR2,
                           p_max_salary IN NUMBER DEFAULT NULL,
                           po_err       OUT VARCHAR2);
---------------------                           
    PROCEDURE del_jobs (
                          p_job_id  IN VARCHAR2,
                          po_result OUT VARCHAR2);
                          
---------------------------------                          
    PROCEDURE check_work_time;

------------------------
    PROCEDURE update_balance(p_employee_id IN NUMBER,
                         p_balance     IN NUMBER);
-------------------------        

	-- PS-10         
    PROCEDURE add_employee(
                        p_first_name     IN employees.first_name%TYPE,
                        p_last_name      IN employees.last_name%TYPE,
                        p_email          IN employees.email%TYPE,
                        p_phone_number   IN employees.phone_number%TYPE,
                        p_hire_date      IN employees.hire_date%TYPE DEFAULT TRUNC(SYSDATE, 'dd'),
                        p_job_id         IN employees.job_id%TYPE,
                        p_salary         IN employees.salary%TYPE,
                        p_commission_pct IN employees.commission_pct%TYPE DEFAULT NULL,
                        p_manager_id     IN employees.manager_id%TYPE DEFAULT 100,
                        p_department_id  IN employees.department_id%TYPE);        
-------------------------

    -- PS-11  
    PROCEDURE fire_an_employee(p_employee_id IN employees.employee_id%TYPE);

-------------------------
     -- PS-12
    PROCEDURE change_attribute_employee(p_employee_id    IN employees.employee_id%TYPE,
                                      p_first_name     IN employees.first_name%TYPE DEFAULT NULL,
                                      p_last_name      IN employees.last_name%TYPE DEFAULT NULL,
                                      p_email          IN employees.email%TYPE DEFAULT NULL,
                                      p_phone_number   IN employees.phone_number%TYPE DEFAULT NULL,
                                      p_job_id         IN employees.job_id%TYPE DEFAULT NULL,
                                      p_salary         IN employees.salary%TYPE   DEFAULT NULL,
                                      p_commission_pct IN employees.commission_pct%TYPE   DEFAULT NULL,
                                      p_manager_id     IN employees.manager_id%TYPE   DEFAULT NULL,
                                      p_department_id  IN employees.department_id%TYPE   DEFAULT NULL
                                  );

 END util;  




CREATE OR REPLACE PACKAGE BODY util AS

 c_percent_of_min_salary CONSTANT NUMBER := 1.5;
--------------------------------------------------------------
  FUNCTION add_years(p_date IN DATE,
                     p_year IN NUMBER) RETURN DATE IS
    v_date DATE;
    v_year NUMBER := p_year*12;
  BEGIN
    SELECT add_months(p_date, v_year)
    INTO v_date
    FROM dual;
    RETURN v_date;
  END add_years;
  
--------------------------------------------------------------
FUNCTION table_from_list(p_list_val IN VARCHAR2,
                         p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED IS

 out_rec tab_value_list := tab_value_list();
 l_cur SYS_REFCURSOR;
 
BEGIN

    OPEN l_cur FOR
    
        SELECT TRIM(REGEXP_SUBSTR(p_list_val, '[^'||p_separator||']+', 1, LEVEL)) AS cur_value
        FROM dual
        CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;
        
        BEGIN
        
            LOOP
                EXIT WHEN l_cur%NOTFOUND;
                FETCH l_cur BULK COLLECT
                    INTO out_rec;
                FOR i IN 1 .. out_rec.count LOOP
                    PIPE ROW(out_rec(i));
                END LOOP;
            END LOOP;
            
        CLOSE  l_cur;
        
        EXCEPTION WHEN OTHERS THEN
            IF (l_cur%ISOPEN) THEN 
                CLOSE  l_cur;
                RAISE;
            ELSE 
                RAISE;
            END IF;
        END;
    
END table_from_list;

--------------------------------------------------------------

    FUNCTION get_dep_name(p_employee_id IN NUMBER) RETURN VARCHAR2 IS
        v_department_name departments.department_name%TYPE;
    BEGIN
        
        SELECT dp.DEPARTMENT_NAME
        INTO v_department_name
        FROM employees em
        JOIN departments dp ON dp.department_id = em.department_id
        WHERE em.employee_id = p_employee_id;
        
        
        RETURN v_department_name;
    END get_dep_name;
    
-----------------------------------------------------------------------
    FUNCTION get_sum_price_sales(p_table IN VARCHAR2) RETURN NUMBER IS
        v_price_sum NUMBER;
        v_message   logs.message%TYPE;
    BEGIN
        IF p_table NOT IN ('products', 'products_old') THEN
            v_message := p_table|| ' - неприпустиме значення! Очікується products або products_old';
            to_log(p_appl_proc => 'util.get_sum_price_sales', p_message => v_message);
            raise_application_error(-20001, v_message);
         END IF;
         
        
        EXECUTE IMMEDIATE '
            SELECT SUM(price_sales) AS price_sum
            FROM hr.'||p_table
            INTO v_price_sum;
        
        RETURN v_price_sum;
    
    END get_sum_price_sales;

  --------------------------------------------------------------------
    PROCEDURE check_work_time IS
    BEGIN
        IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN') IN ('SAT', 'SUN') THEN
            raise_application_error (-20205, 'Ви можете вносити зміни лише у робочі дні');
        END IF;

    END check_work_time;
  ----------------------------------------------------------------------
    PROCEDURE  add_new_jobs(p_job_id IN VARCHAR2,
                            p_job_title IN VARCHAR2,
                            p_min_salary IN VARCHAR2,
                            p_max_salary IN NUMBER DEFAULT NULL,
                            po_err OUT VARCHAR2) IS
     v_max_salary jobs.max_salarY%TYPE;
     salary_err EXCEPTION;
    BEGIN
        check_work_time;
        IF p_max_salary IS NULL THEN
            v_max_salary := p_min_salary * c_percent_of_min_salary;
        ELSE
            v_max_salary := p_max_salary;
        END IF;
    BEGIN
        IF (p_min_salary < 2000 OR p_max_salary < 2000) THEN
            RAISE salary_err;
        END IF;
        INSERT INTO jobs(job_id, job_title, min_salary, max_salary)
        VALUES (p_job_id, p_job_title, p_min_salary, v_max_salary);
        po_err := 'Посада '||p_job_id||' успішно додана';
    EXCEPTION
        WHEN salary_err THEN
        raise_application_error(-20001, 'Передана зарплата менша за 2000');
        WHEN dup_val_on_index THEN
            raise_application_error(-20002, 'Посада '||p_job_id||' вже існує');
        WHEN OTHERS THEN
            raise_application_error(-20003, 'Виникла помилка при додаванні нової посади. '|| SQLERRM);
    END;
    --COMMIT;
    END add_new_jobs;
     
----------------------------------------------------------------------------

    FUNCTION get_region_cnt_emp (p_department_id IN employees.department_id%TYPE DEFAULT NULL)
                                                            RETURN t_region_cnt_tab PIPELINED IS
        v_rec t_region_cnt_rec;
      BEGIN
    
        FOR r IN (
          SELECT r.region_name,
                 COUNT(e.employee_id) AS emp_count
          FROM employees e
          LEFT JOIN departments d ON d.department_id = e.department_id
          LEFT JOIN locations l   ON l.location_id   = d.location_id
          LEFT JOIN countries c   ON c.country_id    = l.country_id
          LEFT JOIN regions r     ON r.region_id     = c.region_id
          WHERE (e.department_id = p_department_id
                 OR p_department_id IS NULL)
          GROUP BY r.region_name
        ) LOOP
    
          v_rec.region_name := r.region_name;
          v_rec.emp_count   := r.emp_count;
    
          PIPE ROW (v_rec);
    
        END LOOP;
    
        RETURN;
    
    END get_region_cnt_emp;

----------------------------------------------------------------------------    
    PROCEDURE del_jobs (p_job_id  IN VARCHAR2,
                        po_result OUT VARCHAR2) IS
    v_delete_no_data_found EXCEPTION;
    BEGIN
        check_work_time;
        
        DELETE FROM jobs 
        WHERE job_id = p_job_id;
    
        IF SQL%ROWCOUNT = 0 THEN
            RAISE v_delete_no_data_found;
        END IF;
    
        po_result := 'Посада ' || p_job_id || ' успiшно видалена';
    
    EXCEPTION
        WHEN v_delete_no_data_found THEN
            raise_application_error(-20004, 'Посада ' || p_job_id || ' не існує');
    END del_jobs;

------------------------------------------------------------------------------


    PROCEDURE update_balance(p_employee_id IN NUMBER,
                                                    p_balance     IN NUMBER) IS
    v_balance_new balance.balance%TYPE;
    v_balance_old balance.balance%TYPE;
    v_message     logs.message%TYPE;
    BEGIN
    
        SELECT balance
        INTO v_balance_old
        FROM balance b
        WHERE b.employee_id = p_employee_id
        FOR UPDATE; 
        
        IF v_balance_old >= p_balance THEN
            UPDATE balance b
            SET b.balance = v_balance_old - p_balance
            WHERE employee_id = p_employee_id
            RETURNING b.balance INTO v_balance_new;
        ELSE
            v_message := 'Employee_id = '||p_employee_id||'. Недостатньо коштв на рахунку. Поточний баланс '||v_balance_old||', спроба зняття '||p_balance||'';
            raise_application_error(-20001, v_message);
        END IF;
        
        v_message := 'Employee_id = '||p_employee_id||'. Кошти успшно знят з рахунку. Було '||v_balance_old||', стало '||v_balance_new||'';
        dbms_output.put_line(v_message);
        to_log(p_appl_proc => 'util.update_balance', p_message => v_message);
        
        IF 1=0 THEN 
            v_message := 'Непередбачена помилка';
            raise_application_error(-20001, v_message);
        END IF;
        COMMIT; 
    EXCEPTION
      WHEN OTHERS THEN
        to_log(p_appl_proc => 'util.update_balance', p_message => NVL(v_message, 'Employee_id = '||p_employee_id||'. ' ||SQLERRM));
        ROLLBACK;
        raise_application_error(-20001, NVL(v_message, 'Не вдома помилка'));
    END update_balance;
    
    
 ------------------------------------
	---- PS - 10
    PROCEDURE add_employee(p_first_name     IN employees.first_name%TYPE,
                        p_last_name      IN employees.last_name%TYPE,
                        p_email          IN employees.email%TYPE,
                        p_phone_number   IN employees.phone_number%TYPE,
                        p_hire_date      IN employees.hire_date%TYPE DEFAULT TRUNC(SYSDATE, 'dd'),
                        p_job_id         IN employees.job_id%TYPE,
                        p_salary         IN employees.salary%TYPE,
                        p_commission_pct IN employees.commission_pct%TYPE DEFAULT NULL,
                        p_manager_id     IN employees.manager_id%TYPE DEFAULT 100,
                        p_department_id  IN employees.department_id%TYPE
                          ) IS
        v_min_sal NUMBER;
        v_max_sal NUMBER;
        v_check   NUMBER;
        v_message VARCHAR2(1000);
    BEGIN
      
        log_utils.log_start('add_employee');

        SELECT COUNT(*) INTO v_check FROM jobs WHERE job_id = p_job_id;
        IF v_check = 0 THEN
            raise_application_error(-20001, 'Введено неіснуючий код посади');
        END IF;

        SELECT COUNT(*) INTO v_check FROM departments WHERE department_id = p_department_id;
        IF v_check = 0 THEN
            raise_application_error(-20001, 'Введено неіснуючий ідентифікатор відділу');
        END IF;

        SELECT min_salary, max_salary INTO v_min_sal, v_max_sal FROM jobs WHERE job_id = p_job_id;
        IF p_salary NOT BETWEEN v_min_sal AND v_max_sal THEN
            raise_application_error(-20001, 'Введено неприпустиму заробітну плату для даного коду посади');
        END IF;
        
        IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') IN ('SAT', 'SUN') OR
           TO_CHAR(SYSDATE, 'HH24:MI') > '18:00' OR 
           TO_CHAR(SYSDATE, 'HH24:MI') < '08:00' THEN
            raise_application_error(-20001, 'Ви можете додавати нового співробітника лише в робочий час');
        END IF;

        -- Додавання нового співробітника
        BEGIN
            INSERT INTO employees (
                employee_id, first_name, last_name, email, phone_number, 
                hire_date, job_id, salary, commission_pct, manager_id, department_id
            )
            VALUES (
                (SELECT MAX(employee_id) + 1 FROM employees), 
                p_first_name, p_last_name, p_email, p_phone_number, 
                p_hire_date, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id
            );
            
            v_message := 'Співробітник ' || p_first_name || ', ' || p_last_name || 
                     ', ' || p_job_id || ', ' || p_department_id || ' успішно додано до системи';

            DBMS_OUTPUT.PUT_LINE(v_message);
        EXCEPTION
            WHEN OTHERS THEN
                 -- log_error
                log_utils.log_error('add_employee', SQLERRM);
                RAISE;
        END;

        log_utils.log_finish('add_employee', v_message);
    END add_employee;
    
    
-------------------------
    
    PS - 11
    
    PROCEDURE fire_an_employee(p_employee_id IN employees.employee_id%TYPE) IS
        v_first_name    VARCHAR2(50);
        v_last_name     VARCHAR2(50);
        v_job_id        VARCHAR2(20);
        v_department_id NUMBER;
    BEGIN
        log_utils.log_start('fire_an_employee', 'Видалення співробітника ID: ' || p_employee_id);

        IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN') IN ('SAT', 'SUN') OR
           TO_CHAR(SYSDATE, 'HH24:MI') > '18:00' OR 
           TO_CHAR(SYSDATE, 'HH24:MI') < '08:00' THEN
            raise_application_error(-20001, 'Ви можете видаляти співробітника лише в робочий час');
        END IF;

        BEGIN
            SELECT first_name, last_name, job_id, department_id
            INTO   v_first_name, v_last_name, v_job_id, v_department_id
            FROM   employees
            WHERE  employee_id = p_employee_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20001, 'Переданий співробітник не існує');
        END;

        BEGIN
            -- Записуємо в таблицю історії
            INSERT INTO employees_history (employee_id, first_name, last_name, job_id, department_id)
            VALUES (p_employee_id, v_first_name, v_last_name, v_job_id, v_department_id);

            -- видаляємо з основної таблиці
            DELETE FROM employees WHERE employee_id = p_employee_id;
            
            DBMS_OUTPUT.PUT_LINE('Співробітник ' || v_first_name || ', ' || v_last_name || 
                                 ', ' || v_job_id || ', ' || v_department_id || ' успішно видалений');
                                 
        EXCEPTION
            WHEN OTHERS THEN
                -- логуємо помилку
                log_utils.log_error('fire_an_employee', SQLERRM);
                RAISE;
        END;

        log_utils.log_finish('fire_an_employee');
    END fire_an_employee;
    
---------------------------
        --- PS-12
        PROCEDURE change_attribute_employee(p_employee_id    IN employees.employee_id%TYPE,
                                      p_first_name     IN employees.first_name%TYPE DEFAULT NULL,
                                      p_last_name      IN employees.last_name%TYPE DEFAULT NULL,
                                      p_email          IN employees.email%TYPE DEFAULT NULL,
                                      p_phone_number   IN employees.phone_number%TYPE DEFAULT NULL,
                                      p_job_id         IN employees.job_id%TYPE DEFAULT NULL,
                                      p_salary         IN employees.salary%TYPE   DEFAULT NULL,
                                      p_commission_pct IN employees.commission_pct%TYPE   DEFAULT NULL,
                                      p_manager_id     IN employees.manager_id%TYPE   DEFAULT NULL,
                                      p_department_id  IN employees.department_id%TYPE   DEFAULT NULL) IS
                                          
        v_sql     VARCHAR2(2000);
        v_set_sql VARCHAR2(1000);
    BEGIN
      
        log_utils.log_start('change_attribute_employee');

        IF p_first_name     IS NULL AND p_last_name     IS NULL AND 
           p_email          IS NULL AND p_phone_number  IS NULL AND 
           p_job_id         IS NULL AND p_salary        IS NULL AND 
           p_commission_pct IS NULL AND p_manager_id    IS NULL AND 
           p_department_id  IS NULL 
        THEN
            -- Якщо все NULL, виводимо інфо і фінішуємо
            DBMS_OUTPUT.PUT_LINE('Нічого оновлювати для співробітника ' || p_employee_id);
            log_utils.log_finish('change_attribute_employee');
            RETURN;
        END IF;

       
          -- Для рядків додаємо одинарні лапки ''
          IF p_first_name     IS NOT NULL THEN v_set_sql := v_set_sql || 'first_name = '''||p_first_name||''', ';     END IF;
          IF p_last_name      IS NOT NULL THEN v_set_sql := v_set_sql || 'last_name = '''||p_last_name||''', ';       END IF;
          IF p_email          IS NOT NULL THEN v_set_sql := v_set_sql || 'email = '''||p_email||''', ';             END IF;
          IF p_phone_number   IS NOT NULL THEN v_set_sql := v_set_sql || 'phone_number = '''||p_phone_number||''', '; END IF;
          IF p_job_id         IS NOT NULL THEN v_set_sql := v_set_sql || 'job_id = '''||p_job_id||''', ';           END IF;
              
          IF p_salary         IS NOT NULL THEN v_set_sql := v_set_sql || 'salary = '||p_salary||', ';           END IF;
          IF p_commission_pct IS NOT NULL THEN v_set_sql := v_set_sql || 'commission_pct = '||p_commission_pct||', '; END IF;
          IF p_manager_id     IS NOT NULL THEN v_set_sql := v_set_sql || 'manager_id = '||p_manager_id||', ';     END IF;
          IF p_department_id  IS NOT NULL THEN v_set_sql := v_set_sql || 'department_id = '||p_department_id||', '; END IF;

          v_set_sql := RTRIM(v_set_sql, ', ');

          BEGIN
            
              v_sql := 'UPDATE employees SET ' || v_set_sql || ' WHERE employee_id = :id';
              
              EXECUTE IMMEDIATE v_sql USING p_employee_id;

              DBMS_OUTPUT.PUT_LINE('У співробітника ' || p_employee_id || ' успішно оновлені атрибути');
          EXCEPTION
              WHEN OTHERS THEN
                  -- логуємо помилку
                  log_utils.log_error('change_attribute_employee', SQLERRM);
                  RAISE;
          END;

        log_utils.log_finish('change_attribute_employee');

    END change_attribute_employee;
    
    
END util;
            

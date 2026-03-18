CREATE TABLE COUNTRIES (
    country_id    CHAR(2) NOT NULL,
    country_name  VARCHAR2(40),
    region_id     NUMBER
);

-- Коментарі до таблиці та колонок
COMMENT ON TABLE COUNTRIES IS 'Country table. Contains 25 rows. References with locations table.';
COMMENT ON COLUMN COUNTRIES.country_id IS 'Primary key of countries table.';
COMMENT ON COLUMN COUNTRIES.country_name IS 'Country name';
COMMENT ON COLUMN COUNTRIES.region_id IS 'Region ID for the country. Foreign key to region_id column in the departments table.';
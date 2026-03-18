CREATE TABLE LOCATIONS (
    location_id     NUMBER(4,0),
    street_address  VARCHAR2(40),
    postal_code     VARCHAR2(12),
    city            VARCHAR2(30) NOT NULL,
    state_province  VARCHAR2(25),
    country_id      CHAR(2)
);

-- Коментарі до таблиці
COMMENT ON TABLE LOCATIONS IS 'Locations table that contains specific address of a specific office, warehouse, and/or production site of a company. Does not store addresses / locations of customers. Contains 23 rows; references with the departments and countries tables.';

-- Коментарі до колонок
COMMENT ON COLUMN LOCATIONS.location_id IS 'Primary key of locations table';
COMMENT ON COLUMN LOCATIONS.street_address IS 'Street address of an office, warehouse, or production site of a company. Contains building number and street name';
COMMENT ON COLUMN LOCATIONS.postal_code IS 'Postal code of the location of an office, warehouse, or production site of a company.';
COMMENT ON COLUMN LOCATIONS.city IS 'A not null column that shows city where an office, warehouse, or production site of a company is located.';
COMMENT ON COLUMN LOCATIONS.state_province IS 'State or Province where an office, warehouse, or production site of a company is located.';
COMMENT ON COLUMN LOCATIONS.country_id IS 'Country where an office, warehouse, or production site of a company is located. Foreign key to country_id column of the countries table.';
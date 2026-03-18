CREATE TABLE PRODUCTS (
    productid    NUMBER,
    productname  VARCHAR2(255),
    price        NUMBER,
    quantity     NUMBER,
    -- Первинний ключ
    CONSTRAINT productid_pk PRIMARY KEY (productid)
);
CREATE OR REPLACE PACKAGE PKG_users AS
    -- Variable curr_user (active or “current user”)
    curr_user VARCHAR2(15) DEFAULT USER
    PROCEDURE PR_assign_user(passport VARCHAR2(15));
    PROCEDURE PR_add_product(comp_name VARCHAR2(40), prod_name VARCHAR2(50), duration NUMBER(5), recipients NUMBER(2));
    PROCEDURE PR_new_appointment (
        specialty VARCHAR2(50),
        policy VARCHAR2(50),
        appoint_date DATE,
        doctor_cif VARCHAR2(12),
        hospital VARCHAR2(50)
    );
END PKG_users;
/
CREATE OR REPLACE PACKAGE BODY PKG_users AS
    PROCEDURE PR_assign_user(passport VARCHAR2(15)) IS
    -- Procedure that allows assigning a value to the "current user" variable (it must be
    -- verified that the user, identified by his passport, is registered in the client table;
    -- the success of the operation must be reported on the display). 
        username VARCHAR2(10);
        BEGIN
            IF passport IN SELECT passport FROM Clients
            THEN 
                curr_user := passport;
                SELECT name INTO username
                FROM People
                WHERE People.passport=passport;
                DBMS_OUTPUT.PUT_LINE('Added user ' || username);
            ELSE DBMS_OUTPUT.PUT_LINE('User not found!');
            END IF;
        END;
    PROCEDURE PR_add_product(comp_name VARCHAR2(40), prod_name VARCHAR2(50), duration NUMBER(5), recipients NUMBER(2)) IS
    -- Procedure to insert a new product for the current customer (active user). The procedure
    -- will allow specifying both the company and the product name, and will assign the most
    -- recent version of it. If the product is withdrawn, it should not insert it, and in any case it
    -- will report the result of the operation on the shell.
        cif VARCHAR2(10);
        max_version NUMBER(4,2);
        BEGIN
            IF comp_name IN SELECT cif FROM Companies
            THEN
                SELECT cif INTO cif
                FROM Companies
                WHERE name=comp_name;
                IF (cif, prod_name) IN Products
                THEN
                    IF (SELECT retired FROM Products WHERE cif=cif and prod_name=name) IS NULL
                    THEN
                        SELECT max(version) INTO max_version WHERE cif=cif and prod_name=name;
                        INSERT INTO Policies VALUES
                            (cif, prod_name, max_version, curr_user, SYSDATE, duration, recipients);
                    END IF; 
                    -- TODO: what if the user already has the product?
                    -- TODO: outputs
                END IF;
            ELSE DBMS_OUTPUT.PUT_LINE('Company not found!');
            END IF;
        END;
    PROCEDURE PR_new_appointment (
        specialty VARCHAR2(50),
        policy VARCHAR2(50),
        appoint_date DATE,
        doctor_cif VARCHAR2(12),
        hospital VARCHAR2(50)
    ) IS
    -- Procedure to insert a new appointment for the current user, with the indicated specialty
    -- covered by the given policy, on the date provided, and with the specified doctor and
    -- hospital. Before insertion, the validity of the appointment will be checked (the policy is
    -- valid on that date and covers that specialty, the hospital and the doctor are accessible
    -- with that company, and there is no other appointment with that doctor overlapping with
    -- the new one within ±15 minutes). 
        BEGIN
          
        END;
END PKG_users;
/


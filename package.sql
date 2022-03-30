CREATE OR REPLACE PACKAGE PKG_users AS
    -- Variable curr_user (active or “current user”)
    curr_user VARCHAR2(10) DEFAULT USER
    PROCEDURE PR_assign_user(user VARCHAR2(10));
    PROCEDURE PR_add_product(comp_name VARCHAR2(40), prod_name VARCHAR2(50));
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
    -- Procedure that allows assigning a value to the "current user" variable (it must be
    -- verified that the user, identified by his passport, is registered in the client table;
    -- the success of the operation must be reported on the display). 
    PROCEDURE PR_assign_user(user VARCHAR2(10)) IS
        BEGIN

        END;
    -- Procedure to insert a new product for the current customer (active user). The procedure
    -- will allow specifying both the company and the product name, and will assign the most
    -- recent version of it. If the product is withdrawn, it should not insert it, and in any case it
    -- will report the result of the operation on the shell.
    PROCEDURE PR_add_product(comp_name VARCHAR2(40), prod_name VARCHAR2(50)) IS
        BEGIN

        END;
    -- Procedure to insert a new appointment for the current user, with the indicated specialty
    -- covered by the given policy, on the date provided, and with the specified doctor and
    -- hospital. Before insertion, the validity of the appointment will be checked (the policy is
    -- valid on that date and covers that specialty, the hospital and the doctor are accessible
    -- with that company, and there is no other appointment with that doctor overlapping with
    -- the new one within ±15 minutes). 
    PROCEDURE PR_new_appointment (
        specialty VARCHAR2(50),
        policy VARCHAR2(50),
        appoint_date DATE,
        doctor_cif VARCHAR2(12),
        hospital VARCHAR2(50)
    ) IS
        BEGIN
          
        END;

END PKG_users;
/


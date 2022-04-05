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




--------------------------------------------------------------------------




SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE  package1  is
   curr_user varchar2(15):= null;
   PROCEDURE procedure1 (userid VARCHAR2);
   FUNCTION getcurrentuser RETURN VARCHAR2 ;
   PROCEDURE procedure2 (productname VARCHAR2, companyname VARCHAR2);
   PROCEDURE procedure3 (schedule DATE, doctor VARCHAR2, hospital VARCHAR2);
   END package1;
/

CREATE OR REPLACE PACKAGE BODY package1 is
   -- Procedure1 body
   PROCEDURE procedure1 (userid VARCHAR2) AS
   exist number(2);
   BEGIN
     select count (*) into exist from clients where passport = procedure1.userid;
     if exist = 1 then
     package1.curr_user := procedure1.userid;
     dbms_output.put_line ('User found');
     else
     dbms_output.put_line ('Invalid User');
     end if;
   END;
   
   --Function getcurrentuser
    FUNCTION getcurrentuser RETURN VARCHAR2 IS
    BEGIN
    RETURN package1.curr_user;
    END getcurrentuser;
    
    --Procedure2 body
    PROCEDURE procedure2 (productname varchar2 , companyname varchar2 ) AS
    exist number(2);
    productversion number(4,2);
    today date;
    BEGIN
    select sysdate into today from dual;
    select max(version) into productversion from products where name = procedure2.productname and cif = procedure2.companyname;
    select count (*) into exist from products where name = procedure2.productname and cif = procedure2.companyname;
    if exist != 0 and package1.curr_user is not null then
    dbms_output.put_line (procedure2.productname);
    dbms_output.put_line (procedure2.companyname);
    dbms_output.put_line (productversion);
    insert into policies (company, product, version, client, start_date, duration, recipients) values(procedure2.companyname, procedure2.productname, productversion, package1.curr_user, today, 30, 1);  
    dbms_output.put_line ('Product correctly assigned');
    else
    dbms_output.put_line ('Invalid data');
    end if;
    END;
    
    --Procedure3 body
    PROCEDURE procedure3 (specialty VARCHAR2, schedule DATE, doctor VARCHAR2, hospital VARCHAR2) AS
    checkspecialty number (1);
    checkdate number(1);
    checkdochosp number(1);
    BEGIN
    select count(*) into checkspecialty from coverages where name = procedure2.productname AND cif = procedure2.companyname AND specialty = procedure3.specialty;
    select start_date into chekdate from policies where product = procedure2.productname AND company = procedure2.companyname;
    select count(*) into checkdochops from adscriptions where hospital = procedure3.hospital and specialty = procedure3.specialty and doctor = proocedure3.doctor
    if 
    If chekspecialty !=0 AND schedule > start_date then
    select * from policies;
    END;
    
    
   END package1;
   /


-- Escript to execute the package
 BEGIN
    package1.procedure1('99266418-M');
    package1.procedure2('Seguro Mecanica de claveles', '70355928D');
   END;
   /
   

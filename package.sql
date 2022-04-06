SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE PKG_users IS
   curr_user varchar2(15):= null;
   PROCEDURE procedure1 (userid VARCHAR2);
   FUNCTION getcurrentuser RETURN VARCHAR2 ;
   PROCEDURE procedure2 (productname VARCHAR2, companyname VARCHAR2);
   PROCEDURE procedure3 (schedule DATE, doctor VARCHAR2, hospital VARCHAR2);
   END package1;
/

CREATE OR REPLACE PACKAGE BODY PKG_users IS
   -- Procedure that allows assigning a value to the "current user" variable (it must be
   -- verified that the user, identified by his passport, is registered in the client table;
   -- the success of the operation must be reported on the display). 
   PROCEDURE assign_user (userid VARCHAR2) AS
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
    FUNCTION getCurrentUser RETURN VARCHAR2 IS
    BEGIN
    RETURN package1.curr_user;
    END getCurrentUser;
    
    --Procedure2 body
    PROCEDURE add_product (productname varchar2 , companyname varchar2 ) AS
    -- Procedure to insert a new product for the current customer (active user). The procedure
    -- will allow specifying both the company and the product name, and will assign the most
    -- recent version of it. If the product is withdrawn, it should not insert it, and in any case it
    -- will report the result of the operation on the shell.
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
    PROCEDURE new_appointment(specialty VARCHAR2, schedule DATE, doctor VARCHAR2, hospital VARCHAR2) AS
        -- Procedure to insert a new appointment for the current user, with the indicated specialty
        -- covered by the given policy, on the date provided, and with the specified doctor and
        -- hospital. Before insertion, the validity of the appointment will be checked (the policy is
        -- valid on that date and covers that specialty, the hospital and the doctor are accessible
        -- with that company, and there is no other appointment with that doctor overlapping with
        -- the new one within ±15 minutes). 
        checkspecialty number (1);
        checkdate number(1);
        checkdochosp number(1);
        BEGIN
            select count(*) into checkspecialty from coverages
            where 
                name = procedure2.productname 
                AND cif = procedure2.companyname 
                AND specialty = procedure3.specialty;
            select start_date into chekdate from policies
            where
                product = procedure2.productname 
                AND company = procedure2.companyname
            ;
            select count(*) into checkdochops from adscriptions
            where hospital = procedure3.hospital and specialty = procedure3.specialty and doctor = procedure3.doctor;
            if chekspecialty !=0 AND schedule > start_date
            then
                select * from policies;
            end if;
        END;
    
    
   END PKG_users;
   /


-- script to execute the package
 BEGIN
    PKG_users.assign_user('99266418-M');
    PKG_users.add_product('Seguro Mecanica de claveles', '70355928D');
   END;
   /
   

SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE package1 is
   curr_user varchar2(15):= null;
   PROCEDURE procedure1 (userid VARCHAR2);
   FUNCTION getcurrentuser RETURN VARCHAR2 ;
   PROCEDURE procedure2 (productname VARCHAR2, companyname VARCHAR2);
   PROCEDURE procedure3 (company VARCHAR2, product VARCHAR2, version NUMBER, start_date DATE, specialty VARCHAR2, schedule DATE, doctor VARCHAR2, hospital VARCHAR2);
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
        dbms_output.put_line (package1.getcurrentuser);
        else
        dbms_output.put_line ('Invalid User');
        end if;
   END;

    FUNCTION getcurrentuser RETURN VARCHAR2 IS
        BEGIN
        RETURN package1.curr_user;
        END getcurrentuser;
    
    PROCEDURE procedure2 (productname varchar2, companyname varchar2 ) AS
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
    
    PROCEDURE procedure3 (company VARCHAR2, product VARCHAR2, version NUMBER, start_date DATE, specialty VARCHAR2, schedule DATE, doctor VARCHAR2,  hospital VARCHAR2) AS
        checkspecialty number (1);
        checkdate number(3);
        checkdochosp number(3);
        checkcompany number(3);
        appointmentversion number(4,2);
        appointmentstart DATE;
        today DATE;
        BEGIN
            select count (*) into checkspecialty from coverages where cif = procedure3.company AND name = procedure3.product AND version = procedure3.version AND specialty = procedure3.specialty;
            select sysdate into today  from dual;
            select count(*) into checkdochosp from adscriptions where hospital = procedure3.hospital and specialty = procedure3.specialty and doctor = procedure3.doctor;
            select count (*) into checkcompany from contracts where hospital = procedure3.hospital and company = procedure3.company;
            dbms_output.put_line (checkdochosp);
            If checkspecialty > 0 and checkdochosp > 0 and checkcompany > 0 AND schedule > procedure3.start_date then
            --insert into  appointments values(procedure3.company, procedure3.product, procedure3.version, package1.curr_user, procedure3.start_date, procedure3.doctor, procedure3.specialty, procedure3.hospital, procedure3.schedule, today, today );
            dbms_output.put_line ('New appointment correctly inserted');
            ELSE
            dbms_output.put_line ('Invalid data, appointment cant be inserted');
            END IF;
        END;
    END package1;
    /



-- script to execute the package
 BEGIN
    PKG_users.assign_user('99266418-M');
    PKG_users.add_product('Seguro Mecanica de claveles', '70355928D');
   END;
   /
   

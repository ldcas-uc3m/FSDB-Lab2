CREATE OR REPLACE TRIGGER trigger1
BEFORE INSERT ON products FOR EACH ROW
DECLARE vers float;
BEGIN
    vers := -1;
    SELECT max(version) INTO vers FROM products WHERE name = :new.name and retired = null;
    IF vers < :new.version and vers != -1 THEN 
    UPDATE products
    set retired = (select sysdate from dual)
    WHERE name = :new.name AND cif = :new.cif;
    ELSE IF vers > :new.version THEN
    raise_application_error(-20001, 'Invalid product version');
    
    END IF;
    
    END IF;
END;
/


ALTER TABLE appointments
    ADD (creation_date DATE DEFAULT NULL,
         update_date   DATE DEFAULT NULL);
         
CREATE OR REPLACE TRIGGER trigger2 
BEFORE INSERT ON appointments FOR EACH ROW
DECLARE today DATE ;
BEGIN
    SELECT SYSDATE INTO today FROM DUAL;
    IF :old.client = :new.client AND :old.specialty = :new.specialty THEN
    UPDATE appointments set company = :new.company, product = :new.product, version = :new.version, 
    client = :new.client, start_date = :new.start_date, doctor = :new.doctor, specialty = :new.specialty, hospital = :new.hospital,  
    schedule = :new.schedule, creation_date = null, update_date = today;
    raise_application_error(-20000, 'There was already an appointment for that client and service, that appointment has been updated');
    
    ELSE
    :new.creation_date := today;
    :new.update_date := today;
    END IF;
END;
/

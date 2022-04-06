CREATE OR REPLACE TRIGGER trigger1
    -- Anytime a new version of a product is added, that version becomes the current one (without an specific expiration date)
    -- and all other previous versions will be obsolete (with a withdrawal date prior to or equal to the present time).
    -- The new version must be the highest value of version (if the value provided is not the highest, the insert is rejected).
    -- In addition, a client must be prevented from contracting an obsolete version.
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

-- need to alter the table for trigger 2
ALTER TABLE Appointments
    ADD (creation_date DATE DEFAULT NULL,
         update_date   DATE DEFAULT NULL);
         
CREATE OR REPLACE TRIGGER trigger2
    -- Every time a client inserts a new appointment for any specialty, it will be inserted in the database only if there
    -- was no other previous appointment of that client for the same specialty. In case that appointment already exists,
    -- a new row won’t be inserted, but the existing row will be modified (the date, the hospital, the doctor, ... will be
    -- changed by the values that new row had). For tracking appointment modifications, it is necessary to store (along with
    -- the appointments) the dates of creation (date on which it is inserted as a new appointment) and last modification
    -- (date on which the existing row is updated). These two new columns must be added to the Appointments table.
    BEFORE INSERT ON Appointments FOR EACH ROW
    DECLARE today DATE;
    BEGIN
        SELECT SYSDATE INTO today FROM DUAL;
        IF :old.client = :new.client AND :old.specialty = :new.specialty THEN
        UPDATE appointments set company = :new.company, product = :new.product, version = :new.version, 
        client = :new.client, start_date = :new.start_date, doctor = :new.doctor, specialty = :new.specialty, hospital = :new.hospital,  
        schedule = :new.schedule, creation_date = null, update_date = today;
        RAISE_APPLICATION_ERROR(-20000, 'There was already an appointment for that client and service, that appointment has been updated');
        
        ELSE
        :new.creation_date := today;
        :new.update_date := today;
        END IF;
    END;
/

-- --
-- VIEW 1
-- --

--CREATE OR REPLACE VIEW OVERLAPS  AS 
  -- SELECT* FROM ( select * from products where (products.launch < sysdate and products.retired is null and user = package1.getCurrentUser()))
   --JOIN COVERAGES 
   --using(CIF, name, version)
 --with read only;

CREATE OR REPLACE VIEW OVERLAPS AS (
   -- informs about overlapping coverages (as of today) related to the current user’s policies (that is, whenever s/he has 
   -- the same coverage in two products contracted by her/him and active today). This view should be “read only”.
   SELECT* FROM ( select * from products where (products.launch < sysdate and products.retired is null))
   JOIN COVERAGES 
   using(CIF, name, version)
) with read only;

-- VIEW 1 test
insert into specialties values ('OVERLAPSTEST ' ,'we are testing OVERLAPS');

insert into companies values('44','OVERLAPSTESTCopany', 'address', '111','town', '123','q3@uc3m.es', 'www.uc3m.es');
insert into products values ('44', 'OVERLAPSTEST', 1, SYSDATE-1,null );

insert into companies values('222','testCompany2', 'address2', '111','q3town', '123','q3@uc3m.es', 'www.uc3m.es');
insert into products values ('222', 'test2', 1, SYSDATE-1,SYSDATE );

insert into coverages values('1111', 'q3test',1,'q3test', 10);
insert into coverages values('222', 'q3test2',1,'q3test', 1);



-- --
-- VIEW 2
-- --

CREATE OR REPLACE VIEW My_Coverages AS (
    -- list of products contracted today (company, product, version) with their coverages for the current user.
    SELECT cif as company, name as product, version, listagg(specialty, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY specialty) coverages
    FROM (
        SELECT company as cif, product as name, version 
        FROM Policies
        WHERE ((SYSDATE - start_date < 1) AND (client = package1.getCurrentUser()))
    ) JOIN (SELECT DISTINCT cif, name, version, specialty FROM Coverages)
        USING (cif, name, version)
    GROUP BY cif, name, version
);
--

-- This view will be operational, allowing the insertion of a row: if that product has that coverage, 
-- what is inserted is a new policy for this user and that product, so that from now on the row will appear in this view 
-- (the row inserted); it will also allow the deletion of a row (the policy will be deleted, so that the row will no longer 
-- belong to the view); updates won’t have effect on this view (no change made).
--
CREATE OR REPLACE TRIGGER TG_Insert_My_Coverages -- does not work :(
    INSTEAD OF INSERT ON My_Coverages
    BEGIN
    -- we assume you can try to insert (cif, product, version, coverages)
        IF :NEW.coverages IN (
            SELECT specialty FROM Coverages
            WHERE 
                cif=:NEW.company
                AND name=:NEW.product
                AND version=:NEW.version
        )
        THEN
            INSERT INTO Policies VALUES (
                :NEW.company,
                :NEW.product,
                :NEW.version,
                package1.getCurrentUser(), -- user
                SYSDATE, -- start
                365, -- duration, put default
                1 -- recipients, default
            );
        ELSE DBMS_OUTPUT.PUT_LINE('Invalid coverage');
        END IF;
    END;
    /
--
CREATE OR REPLACE TRIGGER TG_Delete_My_Coverages
    INSTEAD OF DELETE ON My_Coverages
    BEGIN
        DELETE FROM Policies
        WHERE 
            company=:OLD.company
            AND product=:OLD.product
            AND version=:OLD.version
            AND client=package1.getCurrentUser()
        ;
    END;
    /

-- test: 
BEGIN
    package1.procedure1('13869622-R');
END;
/
INSERT INTO Policies VALUES ('15755166M', 'P?liza Sensacion', to_number('2.02', '9.99'), '13869622-R', (sysdate), 69, 1);
SELECT * FROM My_Coverages;
INSERT INTO My_Coverages VALUES ('02757650L', 'Seguro Balada y ella', to_number('3.02', '9.99'), 'Inmunolog?a');
DELETE FROM My_Coverages WHERE company='02757650L' and product='Seguro Balada y ella' and version = to_number('3.02', '9.99');

-- --
-- VIEW 3
-- --
CREATE OR REPLACE VIEW Reccomendations AS (
    -- list coverages that the current user does not have, and any current product which latest (active) version has that
    -- coverage. This view is also "read-only".
    WITH 
    product_specialty AS (
        -- active products (with their max version), with their specialties
        SELECT cif, name AS product, MAX(version) AS max_version, specialty FROM (
            (SELECT cif, name, version, specialty FROM Coverages)
            JOIN Products USING (cif, name, version)
        )
        WHERE retired IS NULL
        GROUP BY cif, name, specialty
    ),
    uncovered_specialties AS (
        -- specialties that the user doesn't have
        SELECT name as specialty FROM Specialties
        WHERE name NOT IN (
            SELECT specialty FROM (
                SELECT company AS cif, product AS name, version FROM Policies
                WHERE 
                    client=package1.getCurrentUser()
                    AND (start_date + duration > SYSDATE)
            ) JOIN Coverages USING (cif, name, version)
        )
    )
    SELECT specialty, cif as company, product, max_version
    FROM product_specialty
    WHERE specialty IN (SELECT specialty FROM uncovered_specialties) -- idk why the select is needed tho
    ORDER BY specialty
) WITH READ ONLY;
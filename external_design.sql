-- --
-- VIEW 2
-- --

CREATE OR REPLACE VIEW My_Coverages AS (
    -- list of products contracted today (company, product, version) with their coverages for the current user.
    SELECT cif, name as product, version, listagg(specialty, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY specialty) coverages
    FROM (
        SELECT company as cif, product as name, version 
        FROM Policies
        WHERE ((SYSDATE - start_date < 1) AND (user = PKG_users.getCurrentUser()))
    ) JOIN (SELECT DISTINCT cif, name, version, specialty FROM Coverages)
        USING (cif, name, version)
    GROUP BY cif, name, version
);
--
-- test: 
-- insert into policies values ('15755166M', 'P?liza Sensacion', to_number('2.02', '9.99'), '13869622-R', (sysdate), 69, 1);
--
-- This view will be operational, allowing the insertion of a row: if that product has that coverage, 
-- what is inserted is a new policy for this user and that product, so that from now on the row will appear in this view 
-- (the row inserted); it will also allow the deletion of a row (the policy will be deleted, so that the row will no longer 
-- belong to the view); updates won’t have effect on this view (no change made).
--
CREATE OR REPLACE TRIGGER TG_Insert_My_Coverages
    INSTEAD OF INSERT ON My_Coverages
    BEGIN
    -- we assume you can try to insert (cif, product, version)
        INSERT INTO Policies VALUES (
            :NEW.cif,
            :NEW.product,
            :NEW.version,
            PKG_users.getCurrentUser(), -- user
            SYSDATE, -- start
            365, -- duration, put default
            1 -- recipients, default
        );
    END;
    /
--
CREATE OR REPLACE TRIGGER TG_Delete_My_Coverages
    INSTEAD OF DELETE ON My_Coverages
    BEGIN
        DELETE FROM Policies
        WHERE 
            company=:OLD.cif,
            AND product=:OLD.product,
            AND version=:OLD.version,
            AND user=PKG_users.getCurrentUser()
        ;
    END;
    /

-- --
-- VIEW 3
-- --
CREATE OR REPLACE VIEW Reccomendations AS (
    -- list coverages that the current user does not have, and any current product which latest (active) version has that
    -- coverage. This view is also "read-only".
    
);
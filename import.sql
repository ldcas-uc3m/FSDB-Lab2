-- ----------------------------------- --
-- - INSERTION SCRIPT                - --
-- ----------------------------------- --
-- ----------------------------------- --

-- ------------------------ -- 
-- INSERT INTO PEOPLE       --
-- ------------------------ -- 

-- INSERT INTO people (passport, name, surname1, surname2)
-- SELECT DISTINCT passport, name, surname1, surname2 FROM fsdb.clients;
-- this sentence does not work because it finds repeated passports

INSERT INTO people (passport, name, surname1, surname2)
SELECT DISTINCT passport, name, surname1, surname2 FROM fsdb.clients
WHERE passport NOT IN (SELECT passport FROM fsdb.clients group by passport having count('x')>1);
-- 99949 rows inserted

-- We should check what we have skipped
-- SELECT DISTINCT passport, name, surname1, surname2 FROM fsdb.clients
-- WHERE passport IN (SELECT passport FROM fsdb.clients group by passport having count('x')>1);
-- PASSPORT        NAME                                     SURNAME1                  SURNAME2
-- --------------- ---------------------------------------- ------------------------- -------------------------
-- 69100500-J      Urbano                                   Gomez                     Lopez
-- 69100500-J      Yoly                                     Perez                     Garcia
-- 2 rows skipped

-- Now, we insert also people from doctors
INSERT INTO people (passport, name, surname1, surname2)
SELECT DISTINCT passport, name, surname1, surname2 FROM fsdb.doctors;                 
-- 50000 rows inserted

-- Actually, this is better done in a single sentence, operating union on both
-- but it is not needed in this case (empty intersection between doctors & clients)
-- and thus we avoid grouping by passport (almost identifier) a workspace with 150 Krows 
-- which will require more comp. resources (the script will be run by hundreds of users)

COMMIT;

-- ------------------------ -- 
-- INSERT INTO PHYSICIANS   --
-- ------------------------ -- 
-- A format error occurs, so we have to transform phone into a number
-- Then a NULL PK error occurs, so we have to skip null values
INSERT INTO physicians (collegiateNum, passport, pager) 
SELECT DISTINCT collegiateNum, passport, to_number(substr(phonenum,1,4)||substr(phonenum,6)) 
   FROM fsdb.doctors
   WHERE collegiateNum is not null;
-- 50000 rows inserted

-- Now we display the row we have skipped
-- SELECT DISTINCT collegiateNum, passport FROM fsdb.doctors WHERE collegiateNum is null;
-- COLLEGIATENU PASSPORT
-- ------------ ---------------
--              59775061Q
-- 1 row skipped

-- If we query that passport number, we learn that the error is not important 
-- select collegiatenum, passport, name, specialty, phonenum from fsdb.doctors where passport='59775061Q';
-- COLLEGIATENU PASSPORT        NAME                                     SPECIALTY            PHONENUM
-- ------------ --------------- ---------------------------------------- -------------------- --------------
-- COM-7328IIA  59775061Q       Dr. Baudilio                             Nefrolog?a           0034 555653594
--              59775061Q       Dr. Baudilio                             Nefrolog?a           0034 555653594
-- As we can see, the row we skip is actually a repeated row 

COMMIT;

-- --------------------------------------- -- 
-- INSERT INTO SPECIALTIES AND SPECIALISTS --
-- --------------------------------------- -- 
-- Again, NULL into PK error occurs
INSERT INTO specialties (name, description)
SELECT DISTINCT specialty, desc_specialty FROM fsdb.doctors WHERE specialty IS NOT NULL;
-- 49 rows inserted
-- We display the skipped row, to learn it was a completely empty row
-- SELECT DISTINCT specialty, desc_specialty FROM fsdb.doctors WHERE specialty IS NULL;

-- The null error will be propagated to specialists, so we skip nulls
INSERT INTO specialists (doctor, speciality)
SELECT DISTINCT collegiateNum, specialty 
   FROM fsdb.doctors 
   WHERE collegiateNum IS NOT NULL AND specialty IS NOT NULL;
-- 63383 rows inserted

-- We display skipped rows
-- SELECT DISTINCT collegiateNum, specialty 
--    FROM fsdb.doctors WHERE collegiateNum IS NULL OR specialty IS NULL;
-- COLLEGIATENU SPECIALTY
-- ------------ --------------------------------------------------
--              Nefrolog?a
-- COM-1448EAI
-- 2 rows skipped
-- first one is the repeated doctor (does not matter); 
-- second one is worse (identified doctor without any specialty), and must be documented 

COMMIT;

-- ------------------------------------------------ -- 
-- INSERT INTO HOSPITALS, SERVICES AND ADSCRIPTIONS --
-- ------------------------------------------------ -- 
-- Again, null PK and wrong format in phone number
-- no CIF available so we skip the attribute (null will be inserted)
INSERT INTO hospitals (name, phone, address, emergency, ZIP, town, country)
SELECT DISTINCT hospital, to_number(substr(phone_hospital,1,4)||substr(phone_hospital,6)), 
                address_hospital, address_emergency, ZIP_hospital, town_hospital, country_hospital
       FROM fsdb.doctors WHERE hospital is not null;
-- 31 rows inserted

-- we display the skipped row, and it is entirely empty, so it does not matter
-- SELECT DISTINCT hospital, to_number(substr(phone_hospital,1,4)||substr(phone_hospital,6)), 
--                 address_hospital, address_emergency, ZIP_hospital, town_hospital, country_hospital
--        FROM fsdb.doctors WHERE hospital is null;

INSERT INTO services (specialty, hospital) 
SELECT DISTINCT specialty, hospital FROM fsdb.doctors WHERE hospital IS NOT NULL AND specialty IS NOT NULL;
-- 1000 rows inserted

-- We analyze the skipped rows
-- SELECT DISTINCT specialty, hospital FROM fsdb.doctors WHERE OR specialty IS NULL;
-- A single row, corresponding to the hospital where works the specialist COM-1448EAI (the one we had to skip)
-- So it is, actually, the same problem
-- SELECT DISTINCT specialty, hospital FROM fsdb.doctors WHERE OR hospital IS NULL;
-- Many rows, corresponding to unemployed doctors (non null specialty and no hospital)
-- we understand that those rows are ok, and shouldn't be retrieved 
-- (the quet without "hospital IS NOT NULL" was not properly built) 
-- actually, no skipped rows
 
-- Those rows with nulls (in collegiatenum, hospital, and specialties) will cause trouble in adscriptions
-- so we have to skip them (they cause no newly skipped rows, so no further analysis on them)
INSERT INTO adscriptions (doctor, specialty, hospital) 
SELECT DISTINCT collegiateNum, specialty, hospital 
   FROM fsdb.doctors 
   WHERE hospital IS NOT NULL AND specialty IS NOT NULL AND collegiatenum IS NOT NULL;
-- 69758 rows inserted

COMMIT;

-- ----------------------------------- -- 
-- INSERT INTO COMPANIES AND CONTRACTS --
-- ----------------------------------- -- 
-- A null into PK error occurs 
INSERT INTO companies (CIF, name, address, ZIP, town, phone, email, web)
SELECT DISTINCT taxID_insurer, insurer, address_insurer, ZIP_insurer, town_insurer, 
       to_number(substr(phone_insurer,1,4)||substr(phone_insurer,6)), email_insurer, web_insurer
  FROM fsdb.contracts WHERE taxID_insurer IS NOT NULL;
-- 20 rows inserted

-- we inspect null value in the tax ID, to find a single company
-- SELECT DISTINCT taxID_insurer, insurer, address_insurer, ZIP_insurer, town_insurer, 
--        to_number(substr(phone_insurer,1,4)||substr(phone_insurer,6)), email_insurer, web_insurer
--   FROM fsdb.contracts WHERE taxID_insurer IS NULL;
-- we query again that table, selecting by the name of that company, and find two rows 
-- regarding the same company, so it's ok to be skipping the partially null one (no data loss)

-- for inserting into contracts, we have to skip the null company and the null hospital (no data loss)
-- then arises a date problem, we can solve semantically by taking the following 'Implicit Semantic Asumption':
-- "when a contract ends before starting (wrong end_date), end_date will be the same as the starting date"
-- For implementing that, you can use general function CASE or function GREATEST which is simpler
INSERT INTO contracts (company, hospital, start_date, end_date)
SELECT DISTINCT taxID_insurer, hospital, TO_DATE(start_date,'DD/MM/YYYY'), 
                GREATEST(TO_DATE(end_date,'DD/MM/YYYY'), TO_DATE(start_date,'DD/MM/YYYY') ) 
  FROM fsdb.contracts 
  WHERE hospital IS NOT NULL AND taxID_insurer IS NOT NULL;
-- 1496 rows inserted

COMMIT;

-- ---------------------------------- -- 
-- INSERT INTO PRODUCTS AND COVERAGES --
-- ---------------------------------- -- 
-- A PK violation error occurs, and we follow the two steps to find and typify the problem
-- It seems that there are several launching dates for the same product 
-- We can solve by applying an implicit semantic asumption: 
-- "the valid dates are the oldest for launch_date, and the newest for retiring date"
INSERT INTO products (CIF, name, version, launch, retired) 
SELECT DISTINCT taxID_insurer, product, TO_NUMBER(version,'99.99'),
                TO_DATE(MIN(launch),'DD/MM/YYYY'), TO_DATE(MAX(retired),'DD/MM/YYYY') 
FROM fsdb.coverages group by taxID_insurer, product, version;
-- 4905 rows inserted

-- The coverages show a format problem in the waiting_period, with number in days, months, or weeks
-- we can run 3 insert sentences but we won't be aware of the repeated rows with different unit;
-- so we operate 'union' on the three of them to discover the same coverage occurs several times
-- we add implicit assumption "when there are several waiting periods, the lowest will be kept" 
INSERT INTO coverages (CIF, name, version, specialty, waiting_period) 
WITH allrows AS ( SELECT DISTINCT taxID_insurer, product, TO_NUMBER(version,'99.99') version, coverage, 
                                  TO_NUMBER(SUBSTR(waiting_period, 1, INSTR(waiting_period, ' ', 1, 1)-1)) days
                         FROM fsdb.coverages where waiting_period like '%days%'
                  UNION SELECT DISTINCT taxID_insurer, product, TO_NUMBER(version,'99.99') version, coverage, 
                               TO_NUMBER(SUBSTR(waiting_period, 1, INSTR(waiting_period, ' ', 1, 1)-1))*30 days
                          FROM fsdb.coverages where waiting_period like '%months%'
                  UNION SELECT DISTINCT taxID_insurer, product, TO_NUMBER(version,'99.99') version, coverage, 
                               TO_NUMBER(SUBSTR(waiting_period, 1, INSTR(waiting_period, ' ', 1, 1)-1))*7 days
                          FROM fsdb.coverages where waiting_period like '%weeks%' )
SELECT taxID_insurer, product, version, coverage, MIN(days) FROM allrows GROUP BY taxID_insurer, product, version, coverage;
-- 91709 rows inserted

COMMIT;

-- -------------------------------- -- 
-- INSERT INTO CLIENTS AND POLICIES --
-- -------------------------------- -- 
-- We have observed a single char for gender, so we have to decode that attribute
-- There were clients we have skipped, so integrity require to be inserting only those rows in table people
INSERT INTO clients (passport, gender, email) 
SELECT DISTINCT passport, decode(gender,'female','F','M'), email 
  FROM fsdb.clients where passport IN (select passport from people);
-- 99949 rows inserted

-- we can check the skipped rows are those with the repeated passport we've skipped while populating PEOPLE
-- SELECT DISTINCT passport, decode(gender,'female','F','M'), email 
--   FROM fsdb.clients where passport NOT IN (select passport from people);


-- no value for 'beneficiary' available so we skip the attribute (default value, 1, will be inserted)
-- we have to skip also the missing clients (those two with the same passport)
-- and it seems there is a non existent product, so we skip any non existent product
INSERT INTO policies (company, product, version, client, start_date, duration) 
SELECT DISTINCT CIF_insurer, product, version, passport, TO_DATE(contracted,'DD/MM/YYYY'), duration
  FROM fsdb.clients 
  where passport IN (select passport from people)
        AND (CIF_insurer,product,version) IN (select CIF,name,version from products);
-- 79750 rows inserted

-- we inspect the skipped rows
-- SELECT DISTINCT CIF_insurer, product, version, passport, TO_DATE(contracted,'DD/MM/YYYY'), duration
--   FROM fsdb.clients where (CIF_insurer,product,version) NOT IN (select CIF,name,version from products);
-- 20199 rows skipped
-- we can end here, or take implicit assumption for healing wrong purchases (the version does not exist)
-- those purchases of non existing version will be assumed to be regarding current (highest) version
INSERT INTO policies (company, product, version, client, start_date, duration) 
WITH valid AS (select CIF CIF_insurer, name product, MAX(version) newversion FROM products group by CIF,name)
SELECT DISTINCT CIF_insurer, product, valid.newversion, passport, TO_DATE(contracted,'DD/MM/YYYY'), duration
  FROM fsdb.clients JOIN valid using(CIF_insurer,product)
  where (CIF_insurer,product,version) NOT IN (select CIF,name,version from products);
-- 20198 rows skipped
-- There is still 1 missing row, because a client purchased a product that does not exist at all; we can display
-- SELECT DISTINCT CIF_insurer, product, passport, TO_DATE(contracted,'DD/MM/YYYY'), duration
--  FROM fsdb.clients where (CIF_insurer,product,version) NOT IN (select CIF,name,version from products)
-- MINUS
-- SELECT DISTINCT CIF_insurer, product, passport, TO_DATE(contracted,'DD/MM/YYYY'), duration
--   FROM fsdb.clients JOIN (select CIF CIF_insurer, name product, MAX(version) newversion FROM products group by CIF,name) valid using(CIF_insurer,product)
--        where (CIF_insurer,product,version) NOT IN (select CIF,name,version from products);

COMMIT;

-- appointments is empty (no previous data for that)
-- So, everything is done.

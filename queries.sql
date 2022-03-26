-- For each product currently offered (in use), report about how many doctors could be
-- appointed with that product (counting all the specialties covered and all the affiliated
-- hospitals). Outputs: company name, company tax id, product name, version, (number
-- of) coverages, (number of) doctors. 

-- TODO: not working properly - sumar doctores de diferentes hospitales

WITH 
  Num_coverages AS (
    -- Number of coverages(specialties) of each active product
    SELECT 
      count('x') AS num_cov,
      cif,
      name AS prod_name,
      version
    FROM Coverages
      JOIN Products USING (cif, name, version)
    WHERE retired is NULL and launch is not NULL
    GROUP BY cif, name, version
  ),
  Num_doctors AS (
    -- Number of doctors per specialty, per hospital
    SELECT count('x') AS num_doc, hospital, specialty
    FROM Adscriptions
    GROUP BY specialty, hospital
  ),
  Products_wComp AS (
    -- Products with the company names
    SELECT cif, name as prod_name, version, comp_name
    FROM 
      (SELECT cif, name as comp_name FROM Companies)
      JOIN (
        SELECT cif, name, version
        FROM Products
        WHERE retired is NULL and launch is not NULL
      )
      USING (cif)
  ),
  Hosp_products AS (
    -- Specialties of each product, for each hospital
    SELECT
      hospital,
      specialty,
      prod_name,
      cif,
      comp_name,
      version
    FROM Services 
      JOIN (
        SELECT cif, specialty, prod_name, comp_name, version
        FROM Products_wComp
          JOIN (
            SELECT cif, specialty, name as prod_name, version
            FROM Coverages
          ) USING (cif, prod_name, version)
      )
      USING (specialty)
  ),
  Prod_numDoc AS (
    -- Number of doctors for each product
    SELECT
      comp_name,
      prod_name,
      cif,
      version,
      num_doc
    FROM Hosp_products
      JOIN Num_doctors USING (hospital, specialty)
  )
SELECT
  comp_name,
  cif,
  prod_name,
  version,
  num_cov,
  num_doc
FROM Num_coverages
  JOIN Prod_numDoc USING (prod_name, cif, version)
;
  


-- Products (currently in use) offering some coverage that they cannot satisfy (because it
-- is not included among the services of any of the hospitals with which the company has
-- a contract). Outputs: Company name, company tax id, product name, version, list of
-- unsatisfied coverages (separated by the semicolon character ';'). 

-- [NOT WORKING]

with 

sq1 as (
SELECT DISTINCT
    fsdb254.contracts.company,
    fsdb254.services.specialty
FROM
    fsdb254.services
    JOIN fsdb254.contracts using (hospital)
)
;

sq2 as (
SELECT
    fsdb254.coverages.cif,
    fsdb254.coverages.name,
    fsdb254.coverages.version,
    fsdb254.coverages.specialty,
    fsdb254.companies.name AS name_company
FROM
    fsdb254.coverages
    JOIN fsdb254.companies using  (cif);

)

select cif, name_company, name, version, sq2.specialty
from sq2
inner join sq1 on  sq1. company = sq2.cif
where sq2.cif not in sq1.company





-- QUERY 3
-- For each specialty, minimum and maximum waiting periods, and brief desc of the
-- product (including the name of the company that offers it, the name of the product and
-- its version). If there are several “tied” companies, the product with the earlier release
-- date will be chosen (if still tied, any of the products is chosen). Outputs: specialty, type
-- of row (either ‘minimum’ or ‘maximum’ period), period in days, company name,
-- company tax id, product name, and version. Sort the output alphabetically by specialty.

WITH 
  Spec_max AS (
    SELECT cif, specialty, name as prod_name, version, upper(waiting_period) AS max_waiting_period 
    FROM Coverages
    ORDER BY waiting_period ASC
  ),
  Spec_min AS (
    SELECT cif, specialty, name as prod_name, version, upper(waiting_period) AS min_waiting_period 
    FROM Coverages
    ORDER BY waiting_period DESC
  ),
  QMax AS (
    SELECT cif, to_char('max') as type, specialty, max_waiting_period as days, name as comp_name, prod_name, version
    FROM Companies 
      JOIN (
        SELECT cif, prod_name, version, max_waiting_period, specialty
        FROM (
          SELECT cif, name as prod_name, version
          FROM Products
        )
        JOIN Spec_max
          USING (cif, prod_name, version)
      )
      USING (cif)
  ),
  QMin AS (
    SELECT cif, to_char('min') as type, specialty, min_waiting_period as days, name as comp_name, prod_name, version
    FROM Companies
      JOIN (
        SELECT cif, prod_name, version, min_waiting_period, specialty
        FROM (
          SELECT cif, name as prod_name, version
          FROM Products
        )
        JOIN Spec_min
          USING (cif, prod_name, version)
      )
      USING (cif)
  )
SELECT cif, comp_name, specialty, prod_name, version, type, days FROM QMax 
UNION  
SELECT cif, comp_name, specialty, prod_name, version, type, days FROM QMin
ORDER BY cif, specialty
;

-- TEST QUERY 3

  
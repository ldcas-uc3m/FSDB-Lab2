-- For each product currently offered (in use), report about how many doctors could be
-- appointed with that product (counting all the specialties covered and all the affiliated
-- hospitals). Outputs: company name, company tax id, product name, version, (number
-- of) coverages, (number of) doctors. 

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
    SELECT count('x') AS num_doc, hospital as hosp_name, specialty
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
      version
    FROM Services 
      JOIN (
        SELECT cif, specialty, name as prod_name, version
        FROM Products_wComp
          JOIN Coverages USING (cif, name, version)
      )
      USING (specialty)
  ),
  Prod_numDoc AS (
    -- Number of doctors for each product
    SELECT
      prod_name,
      cif,
      version,
      num_doc
    FROM Hosp_products
      JOIN Num_doctors USING (prod_name, cif, version)
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

WITH prod_specialties AS (
  SELECT
    Companies.name AS company_name,
    Products.name,
    Coverages.version,
    Companies.cif,
    specialty
  FROM
    Products INNER JOIN Coverages 
      ON Products.cif = Coverages.cif
      AND Products.name = Coverages.name
      AND Products.version = Coverages.version
    INNER JOIN Companies ON Products.cif = Companies.cif
  WHERE retired IS NULL
  ),
  comp_specialties AS (
    SELECT
      specialty,
      company
    FROM
      Hospitals INNER JOIN Services
        ON services.hospital = hospitals.name
      INNER JOIN contracts
        ON contracts.hospital = hospitals.name
  )
SELECT company_name, name, version, cif, listagg(comp_specialties.specialty, ';') within group (ORDER BY comp_specialties.specialty) AS specialties
  FROM prod_specialties
    INNER JOIN comp_specialties ON comp_specialties.specialty != prod_specialties.specialty AND comp_specialties.company = prod_specialties.cif
  GROUP BY company_name, cif, name, version
;





--- QUERY 3
WITH product_max AS (
SELECT * FROM QMAX JOIN
)

WITH QMAX AS (
SELECT UPPER(waiting_period), cif, name, version  from coverages order by waiting_period ASC;
)

WITH QMIN AS (
SELECT UPPER(waiting_period), cif, name, version,  from coverage order by waiting_period DESC;
)


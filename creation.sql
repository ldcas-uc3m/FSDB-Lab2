-- -----------------------------------
-- - CREATION SCRIPTS                -
-- -----------------------------------

-- - DESTRUCTION OF FORMER TABLES    -
-- -----------------------------------

DROP TABLE appointments CASCADE CONSTRAINTS;
DROP TABLE policies CASCADE CONSTRAINTS;
DROP TABLE clients CASCADE CONSTRAINTS;
DROP TABLE coverages CASCADE CONSTRAINTS;
DROP TABLE products CASCADE CONSTRAINTS;
DROP TABLE contracts CASCADE CONSTRAINTS;
DROP TABLE companies CASCADE CONSTRAINTS;
DROP TABLE adscriptions CASCADE CONSTRAINTS;
DROP TABLE services CASCADE CONSTRAINTS;
DROP TABLE hospitals CASCADE CONSTRAINTS;
DROP TABLE specialists CASCADE CONSTRAINTS;
DROP TABLE specialties CASCADE CONSTRAINTS;
DROP TABLE physicians CASCADE CONSTRAINTS;
DROP TABLE people CASCADE CONSTRAINTS;


-- - TABLES CREATION - - - - - - - - -
-- -----------------------------------

CREATE TABLE people(
passport          VARCHAR2(15),
name              VARCHAR2(40) NOT NULL,
surname1          VARCHAR2(25) NOT NULL,
surname2          VARCHAR2(25),
CONSTRAINT PK_people PRIMARY KEY (passport)
);

CREATE TABLE physicians(
collegiateNum     VARCHAR2(12), 
passport          VARCHAR2(15) NOT NULL,
pager             NUMBER(13),
CONSTRAINT PK_physicians PRIMARY KEY (collegiateNum),
CONSTRAINT UK_physicians_passport UNIQUE (passport),
CONSTRAINT FK_physicians_people FOREIGN KEY (passport) 
           REFERENCES people
);

CREATE TABLE specialties(
name              VARCHAR2(50),
description       VARCHAR2(150) NOT NULL,
CONSTRAINT PK_specialties PRIMARY KEY (name)
);

CREATE TABLE specialists (
doctor            VARCHAR2(12),
speciality        VARCHAR2(50),
CONSTRAINT PK_especialista PRIMARY KEY (doctor, speciality),
CONSTRAINT FK_specialists_physicians FOREIGN KEY (doctor) 
           REFERENCES physicians (collegiateNum) ON DELETE CASCADE,
CONSTRAINT FK_specialists_specialties FOREIGN KEY (speciality) 
           REFERENCES specialties (name)
);

-- ---------------------------------

CREATE TABLE hospitals(
name              VARCHAR2(50),
phone             NUMBER(13) NOT NULL,
CIF               VARCHAR2(10),
address           VARCHAR2(50) NOT NULL,
emergency         VARCHAR2(50),
ZIP               NUMBER(5) NOT NULL,
town              VARCHAR2(35) NOT NULL,
country           VARCHAR2(50) NOT NULL,
CONSTRAINT PK_hospitals PRIMARY KEY (name)
-- CONSTRAINT UK_hospitals_CIF UNIQUE (CIF),
-- CONSTRAINT UK_hospitals_phone UNIQUE (phone)
);

CREATE TABLE services (
specialty        VARCHAR2(50),
hospital         VARCHAR2(50),
CONSTRAINT PK_services PRIMARY KEY (specialty, hospital),
CONSTRAINT FK_services_specialty FOREIGN KEY (specialty) 
           REFERENCES specialties, 
CONSTRAINT FK_services_hospital FOREIGN KEY (hospital) 
           REFERENCES hospitals ON DELETE CASCADE
);


CREATE TABLE adscriptions (
doctor           VARCHAR2(12),
specialty        VARCHAR2(50),
hospital         VARCHAR2(50),
CONSTRAINT PK_adscriptions PRIMARY KEY (doctor, specialty, hospital),
CONSTRAINT FK_adscriptions_specialists FOREIGN KEY (doctor, specialty) 
           REFERENCES specialists ON DELETE CASCADE, 
CONSTRAINT FK_adscriptions_services FOREIGN KEY (specialty, hospital) 
           REFERENCES services ON DELETE CASCADE
);

-- --------------------------------

CREATE TABLE companies (
CIF               VARCHAR2(10),
name              VARCHAR2(40) NOT NULL,
address           VARCHAR2(50) NOT NULL,
ZIP               NUMBER(5) NOT NULL,
town              VARCHAR2(35) NOT NULL,
phone             NUMBER(13) NOT NULL,
email             VARCHAR2(30) NOT NULL,
web               VARCHAR2(30) NOT NULL,
CONSTRAINT PK_companies PRIMARY KEY (CIF)
-- CONSTRAINT UK_companies_phone UNIQUE (phone)
-- CONSTRAINT UK_companies_email UNIQUE (email)
-- CONSTRAINT UK_companies_web UNIQUE (web)
);

CREATE TABLE contracts (
company          VARCHAR2(10),
hospital         VARCHAR2(50),
start_date       DATE,
end_date         DATE NOT NULL,
CONSTRAINT PK_contracts PRIMARY KEY (company, hospital, start_date),
CONSTRAINT FK_contracts_companies FOREIGN KEY (company) REFERENCES companies, 
CONSTRAINT FK_contracts_hospitals FOREIGN KEY (hospital) REFERENCES hospitals,
CONSTRAINT CH_fechas CHECK (start_date<=end_date)
);

CREATE TABLE products (
CIF              VARCHAR2(10),
name             VARCHAR2(50),
version          NUMBER(4,2),
launch           DATE,
retired          DATE,
CONSTRAINT PK_products PRIMARY KEY (CIF,name,version),
CONSTRAINT FK_products_companies FOREIGN KEY (CIF) 
           REFERENCES companies ON DELETE CASCADE
);

CREATE TABLE coverages(
CIF              VARCHAR2(10),
name             VARCHAR2(50),
version          NUMBER(4,2),
specialty        VARCHAR2(50),
waiting_period   VARCHAR2(12) DEFAULT (0) NOT NULL,
CONSTRAINT PK_coverages PRIMARY KEY (CIF, name, version, specialty),
CONSTRAINT FK_coverages_products FOREIGN KEY (CIF, name, version) 
           REFERENCES products ON DELETE CASCADE, 
CONSTRAINT FK_coverages_specialties FOREIGN KEY (specialty) 
           REFERENCES specialties
);

-- --------------------------------

CREATE TABLE clients (
passport          VARCHAR2(15),
gender            CHAR(1),     -- values 'F'/'M'
email             VARCHAR2(60), 
CONSTRAINT PK_clients PRIMARY KEY (passport),
CONSTRAINT FK_clients_people FOREIGN KEY (passport) 
           REFERENCES people ON DELETE CASCADE
);

CREATE TABLE policies (
company           VARCHAR2(10),
product           VARCHAR2(50),
version           NUMBER(4,2),
client            VARCHAR2(15),
start_date        DATE, 
duration          NUMBER(5) NOT NULL, 
recipients        NUMBER(2) DEFAULT(1) NOT NULL,
CONSTRAINT PK_policies PRIMARY KEY (company, product, version, client, start_date),
CONSTRAINT FK_policies_products FOREIGN KEY (company, product, version) 
           REFERENCES products,  
CONSTRAINT FK_policies_clients FOREIGN KEY (client) 
           REFERENCES clients,  
CONSTRAINT CK_policies_nonempty CHECK(duration>0 AND recipients>0) 
);

CREATE TABLE appointments (
company           VARCHAR2(10) NOT NULL,
product           VARCHAR2(50) NOT NULL,
version           NUMBER(4,2) NOT NULL,
client            VARCHAR2(15),
start_date        DATE NOT NULL, 
doctor            VARCHAR2(12) NOT NULL,
specialty         VARCHAR2(50) NOT NULL,
hospital          VARCHAR2(50) NOT NULL,
schedule          DATE,
CONSTRAINT PK_appointments PRIMARY KEY (client, schedule),
CONSTRAINT FK_appointments_policies FOREIGN KEY (company, product, version, client, start_date) 
           REFERENCES policies,  
CONSTRAINT FK_appointments_adscriptions FOREIGN KEY (doctor, specialty, hospital) 
           REFERENCES adscriptions,  
CONSTRAINT CK_appointment_validdate CHECK(schedule>start_date) 
);


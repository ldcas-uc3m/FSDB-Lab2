# FSDB-Lab2
By Ignacio Arnaiz Tierraseca, Luis Daniel Casais Mezquida & Iván Darío Cersósimo  
Bachelor's Degree in Computer Science and Engineering,  
Universidad Carlos III de Madrid

## Problem description
On the DB designed for CONGATE, some queries, views, procedures, and triggers must be developed. The lecturers will provide a solution to 1st assignment that will serve as a common starting point for all students (so they have equal opportunities).  
The first step will be, therefore, to run the scripts provided by the lecturers (new DB creation script, and script for inserting data into those new tables). Once this is done, a series of elements (composing this assignment) must be developed and documented.  
The description of these elements is as follows:

## Queries
1. For each product currently offered (in use), report about how many doctors could be appointed with that product (counting all the specialties covered and all the affiliated hospitals). Outputs: company name, company tax id, product name, version, (number of) coverages, (number of) doctors.
2. Products (currently in use) offering some coverage that they cannot satisfy (because it is not included among the services of any of the hospitals with which the company has a contract). Outputs: Company name, company tax id, product name, version, list of unsatisfied coverages (separated by the semicolon character `;`).
3. For each specialty, minimum and maximum waiting periods, and brief desc of the product (including the name of the company that offers it, the name of the product and its version). If there are several “tied” companies, the product with the earlier release date will be chosen (if still tied, any of the products is chosen). Outputs: specialty, type of row (either ‘minimum’ or ‘maximum’ period), period in days, company name, company tax id, product name, and version. Sort the output alphabetically by specialty.

This was implemented in `queries.sql`.

## Operability
Define and create a package that contains at least the following elements:

* Variable `curr_user` (active or “current user”)
* Procedure that allows assigning a value to the `current user` variable (it must be verified that the user, identified by his passport, is registered in the client table; the success of the operation must be reported on the display).
* Procedure to insert a new product for the current customer (active user). The procedure will allow specifying both the company and the product name, and will assign the most recent version of it. If the product is withdrawn, it should not insert it, and in any case it will report the result of the operation on the shell. 
* Procedure to insert a new appointment for the current user, with the indicated specialty covered by the given policy, on the date provided, and with the specified doctor and hospital. Before insertion, the validity of the appointment will be checked (the policy is valid on that date and covers that specialty, the hospital and the doctor are accessible with that company, and there is no other appointment with that doctor overlapping with the new one within ±15 minutes).

This was implemented in `package.sql`.

## External design: "user" profile
Users must have access to the Overlaps, My_Coverages, and Recommendations tables. These tables contain information derived from other tables in the DB, and should be implemented as (logical) views. All of them give access only to the data corresponding to the current user (whose identifier is currently stored in the "current user" variable of the package created in the former section).

* **Overlaps**: informs about overlapping coverages (as of today) related to the current user’s policies (that is, whenever s/he has the same coverage in two products contracted by her/him and active today). This view should be “read only”.
* **My_Coverages**: list of products contracted today (company, product, version) with their coverages for the current user. This view will be operational, allowing the insertion of a row: if that product has that coverage, what is inserted is a new policy for this user and that product, so that from now on the row will appear in this view (the row inserted); it will also allow the deletion of a row (the policy will be deleted, so that the row will no longer belong to the view); updates won’t have effect on this view (no change made).
* **Recommendations**: list coverages that the current user does not have, and any current product which latest (active) version has that coverage. This view is also "read-only".

This was implemented in `external_design.sql`.

## Active databases
Implement one or more triggers to address each of the following needs:

1. Anytime a new version of a product is added, that version becomes the current one (without an specific expiration date) and all other previous versions will be obsolete (with a withdrawal date prior to or equal to the present time). The new version must be the highest value of version (if the value provided is not the highest, the insert is rejected). In addition, a client must be prevented from contracting an obsolete version.
2. Every time a client inserts a new appointment for any specialty, it will be inserted in the database only if there was no other previous appointment of that client for the same specialty. In case that appointment already exists, a new row won’t be inserted, but the existing row will be modified (the date, the hospital, the doctor, ... will be changed by the values that new row had). For tracking appointment modifications, it is necessary to store (along with the appointments) the dates of creation (date on which it is inserted as a new appointment) and last modification (date on which the existing row is updated). These two new columns must be added to the Appointments table.

This was implemented in `triggers.sql`.
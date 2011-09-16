-- This creates a basis for the schema for testing the 'unexpected columns in
-- DB' functioanlity added by jason
BEGIN TRANSACTION;
    CREATE TABLE spanish_inquisition (
        id integer          PRIMARY KEY AUTOINCREMENT,
        name varchar(255)
    );
COMMIT;

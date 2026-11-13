ALTER TABLE users
    ADD COLUMN IF NOT EXISTS firebaseuid varchar(128);

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_firebaseuid
    ON users (firebaseuid)
    WHERE firebaseuid IS NOT NULL;

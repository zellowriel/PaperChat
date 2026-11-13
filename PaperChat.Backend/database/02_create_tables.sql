CREATE TABLE IF NOT EXISTS users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email varchar(255) NOT NULL,
    passwordhash varchar(255) NOT NULL,
    fullname varchar(100),
    storageusedbytes bigint NOT NULL DEFAULT 0,
    plantype varchar(50) NOT NULL DEFAULT 'FREE',
    createdat timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email
    ON users (email);

CREATE TABLE IF NOT EXISTS documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    userid uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    authors varchar(255),
    fileurl varchar(500) NOT NULL,
    sizebytes bigint NOT NULL,
    pagecount integer NOT NULL DEFAULT 0,
    readingprogress integer NOT NULL DEFAULT 0,
    isprocessed boolean NOT NULL DEFAULT false,
    createdat timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_userid
    ON documents (userid);

CREATE TABLE IF NOT EXISTS chatmessages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    documentid uuid NOT NULL REFERENCES documents (id) ON DELETE CASCADE,
    userid uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    senderrole varchar(10) NOT NULL,
    content text NOT NULL,
    quotereference text,
    citationpage integer,
    createdat timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chatmessages_documentid
    ON chatmessages (documentid);

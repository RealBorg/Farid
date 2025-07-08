/*
CREATE TABLE articles (
    id BIGINT NOT NULL,
    path TEXT NOT NULL,
    lang TEXT NOT NULL,
    format TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_articles_path ON articles(path);
*/
CREATE TABLE access_log (
    id BIGINT PRIMARY KEY,
    ip INET NOT NULL,
    path TEXT NOT NULL,
    status INTEGER NOT NULL,
    duration BIGINT NOT NULL,
    server TEXT NOT NULL,
    referer TEXT NOT NULL
);
CREATE INDEX idx_access_log_path ON access_log (path);
CREATE TABLE airports (
    id TEXT PRIMARY KEY,
    country TEXT NOT NULL,
    municipality TEXT NOT NULL,
    name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL
);
CREATE TABLE aviationweather (
    id TEXT NOT NULL,
    type TEXT NOT NULL,
    text TEXT NOT NULL,
    date BIGINT NOT NULL,
    PRIMARY KEY (id, type)
);
CREATE TABLE checkit (
    server TEXT NOT NULL,
    test TEXT NOT NULL,
    args TEXT NOT NULL,
    date INTEGER,
    result TEXT,
    PRIMARY KEY (server, test)
);
CREATE TABLE dns (
    name TEXT NOT NULL,
    class TEXT NOT NULL,
    type TEXT NOT NULL,
    data TEXT NOT NULL,
    PRIMARY KEY (name, class, type, data)
);
CREATE TABLE impressions (
    id BIGINT PRIMARY KEY,
    ip INET NOT NULL,
    path TEXT NOT NULL,
    referer TEXT NOT NULL,
    server TEXT NOT NULL
);
CREATE INDEX idx_impressions_path ON impressions (path);
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    displayname TEXT NOT NULL,
    bio TEXT NOT NULL DEFAULT '',
    website TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    source TEXT NOT NULL DEFAULT ''
);
CREATE TABLE postings (
    id BIGINT PRIMARY KEY,
    xid BIGINT,
    text TEXT NOT NULL,
    lang CHAR(3) NOT NULL DEFAULT '',
    parent BIGINT,
    user_id BIGINT REFERENCES users(id) NOT NULL
);
CREATE INDEX idx_postings_xid ON postings (xid);
CREATE INDEX idx_postings_parent ON postings(parent);
CREATE TABLE medias (
    posting_id BIGINT REFERENCES postings(id) NOT NULL,
    filename TEXT PRIMARY KEY,
    type TEXT NOT NULL
);
CREATE INDEX idx_medias_posting ON medias(posting_id);
CREATE TABLE login_tokens (
    user_id BIGINT REFERENCES users(id),
    token TEXT NOT NULL PRIMARY KEY,
    created TIMESTAMP NOT NULL
);
CREATE TABLE sessions (
    id CHAR(72) PRIMARY KEY,
    session_data TEXT,
    expires INTEGER
);
CREATE TABLE peers (
    url TEXT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    access_log_id BIGINT,
    impressions_id BIGINT,
    posting_id BIGINT
);

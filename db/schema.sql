CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'field',
    password_hash TEXT
);

CREATE TABLE routes (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN('macro','micro')),
    geom geometry(LINESTRING, 4326) NOT NULL,
    last_checked DATE
);

CREATE TABLE markers (
    id SERIAL PRIMARY KEY,
    route_id INT REFERENCES routes(id) ON DELETE CASCADE,
    label TEXT,
    geom geometry(POINT, 4326) NOT NULL
);

CREATE TABLE inspections (
    id SERIAL PRIMARY KEY,
    route_id INT REFERENCES routes(id) ON DELETE CASCADE,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes TEXT
);

CREATE INDEX routes_gix ON routes USING GIST (geom);
CREATE INDEX markers_gix ON markers USING GIST (geom);
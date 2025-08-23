INSERT INTO users (username, role) VALUES ('demo','field') ON CONFLICT DO NOTHING;

INSERT INTO routes (name, type, geom, last_checked) VALUES (
    'Delhi - Jaipur Macro', 'macro',
    ST_SetSRID(ST_GeomFromText('LINESTRING(77.2090 28.6139, 74.2179 27.0238)'), 4326),
    CURRENT_DATE
);

INSERT INTO routes (name, type, geom) VALUES (
    'Section Micro','micro',
    ST_SetSRID(ST_GeomFromText('LINESTRING(77.2090 28.6139, 77.1855 28.5244, 77.3178 28.4089)'), 4326)
);

INSERT INTO markers (route_id, label, geom) VALUES (1, 'Joint Pit A', ST_SetSRID(ST_Point(77.20, 28.60), 4326));
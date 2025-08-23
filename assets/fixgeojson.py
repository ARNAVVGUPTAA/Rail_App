import json

# --- Configuration ---
geojson_file_path = 'lucknow_cables.geojson'
route_name = 'BNZ-GKP (no.2)'
route_type = 'macro'
output_sql_file = 'insert_fixed_route.sql'

# --- Script ---
try:
    with open(geojson_file_path, 'r') as f:
        data = json.load(f)

    all_linestrings_2d = []
    # Loop through each line segment in the GeoJSON
    for feature in data['features']:
        if feature['geometry']['type'] == 'LineString':
            linestring_3d = feature['geometry']['coordinates']
            # Convert 3D coordinates to 2D by taking only the first two values
            linestring_2d = [[coord[0], coord[1]] for coord in linestring_3d]
            all_linestrings_2d.append(linestring_2d)

    # Create the MultiLineString geometry object with the corrected 2D coordinates
    multilinestring_geojson = {
        "type": "MultiLineString",
        "coordinates": all_linestrings_2d
    }

    # Create the final SQL command
    sql_command = (
        f"INSERT INTO cable_routes (name, type, geom) VALUES "
        f"('{route_name}', '{route_type}', ST_GeomFromGeoJSON('{json.dumps(multilinestring_geojson)}'));\n"
    )

    with open(output_sql_file, 'w') as f_out:
        f_out.write(sql_command)

    print(f"Success! The corrected SQL command has been written to {output_sql_file}")

except Exception as e:
    print(f"An error occurred: {e}")
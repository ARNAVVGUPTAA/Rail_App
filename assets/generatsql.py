import json

# --- Configuration ---
geojson_file_path = 'lucknow_cables.geojson'
route_name = 'BNZ-GKP (no.2)'
route_type = 'macro'
output_sql_file = 'insert_routes.sql'

# --- Script ---
try:
    with open(geojson_file_path, 'r') as f:
        data = json.load(f)

    with open(output_sql_file, 'w') as f_out:
        print(f"Reading from {geojson_file_path}...")

        # The GeoJSON is a FeatureCollection, so we loop through its features
        for i, feature in enumerate(data['features']):
            if feature['geometry']['type'] == 'LineString':

                # Get the geometry object for this specific line segment
                geometry_object = json.dumps(feature['geometry'])

                # Create a unique name for each segment
                segment_name = f"{route_name} - Segment {i + 1}"

                # Create the SQL INSERT statement
                sql_command = (
                    f"INSERT INTO cable_routes (name, type, geom) VALUES "
                    f"('{segment_name}', '{route_type}', ST_GeomFromGeoJSON('{geometry_object}'));\n"
                )

                # Write the command to the output file
                f_out.write(sql_command)

        print(f"Success! All INSERT commands have been written to {output_sql_file}")

except FileNotFoundError:
    print(f"Error: The file '{geojson_file_path}' was not found.")
except Exception as e:
    print(f"An error occurred: {e}")
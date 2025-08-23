import json

def generate_multistring_sql(file_path, route_name, route_type='macro'):
    """
    Reads a GeoJSON file, extracts all LineString coordinates,
    and generates a single SQL INSERT command for a MultiLineString.
    """
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)

        all_linestrings_2d = []
        # Loop through each feature in the GeoJSON FeatureCollection
        for feature in data['features']:
            if feature.get('geometry', {}).get('type') == 'LineString':
                linestring_3d = feature['geometry']['coordinates']
                # Convert 3D coordinates to 2D by taking only the first two values
                linestring_2d = [[coord[0], coord[1]] for coord in linestring_3d]
                all_linestrings_2d.append(linestring_2d)

        if not all_linestrings_2d:
            print("No LineString features found in the file.")
            return

        # Create the final MultiLineString geometry object
        multilinestring_geojson = {
            "type": "MultiLineString",
            "coordinates": all_linestrings_2d
        }
        
        # Escape single quotes in the JSON string for SQL compatibility
        geojson_string = json.dumps(multilinestring_geojson).replace("'", "''")
        
        # Create the final SQL command
        sql_command = (
            f"INSERT INTO cable_routes (name, type, geom) VALUES "
            f"('{route_name}', '{route_type}', ST_GeomFromGeoJSON('{geojson_string}'));\n"
        )

        # Save the command to an output file
        output_file = 'output.sql'
        with open(output_file, 'w') as f_out:
            f_out.write(sql_command)
            
        print(f"✅ Success! The SQL command has been written to '{output_file}'")
        print("You can now copy the content of that file and run it in the Supabase SQL Editor or a DB client.")

    except FileNotFoundError:
        print(f"❌ Error: The file '{file_path}' was not found.")
    except Exception as e:
        print(f"❌ An error occurred: {e}")

# --- Main execution ---
if __name__ == "__main__":
    input_file = input("Enter the path to your GeoJSON file: ")
    input_name = input("Enter the name for this cable route: ")
    generate_multistring_sql(input_file, input_name)
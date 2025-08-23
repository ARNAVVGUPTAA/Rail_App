import json

def generate_poles_sql(file_path, route_name):
    """
    Reads a GeoJSON file containing Point features, ensures they are 2D,
    and generates SQL INSERT commands for the ohe_poles table.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        output_sql_file = 'insert_poles.sql'
        with open(output_sql_file, 'w', encoding='utf-8') as f_out:
            print(f"Reading from {file_path}...")
            
            feature_count = 0
            for feature in data['features']:
                if feature.get('geometry', {}).get('type') == 'Point':
                    
                    properties = feature.get('properties', {})
                    # --- IMPORTANT: Adjust these keys if your GeoJSON uses different names ---
                    pole_no = properties.get('pole_no') or properties.get('Name') or 'N/A'
                    km = properties.get('km', 'N/A')
                    height_m = properties.get('height_m', 5.5) # Default height if not found
                    
                    # --- THIS SECTION FIXES THE 3D COORDINATE ISSUE ---
                    coordinates_3d = feature['geometry']['coordinates']
                    
                    # Create a new 2D geometry object by taking only the first two values
                    geometry_2d = {
                        "type": "Point",
                        "coordinates": [coordinates_3d[0], coordinates_3d[1]] 
                    }
                    geometry_object_string = json.dumps(geometry_2d)
                    # --- End of fix ---

                    # Escape single quotes in text fields for SQL
                    pole_no_sql = str(pole_no).replace("'", "''")
                    km_sql = str(km).replace("'", "''")
                    route_name_sql = route_name.replace("'", "''")

                    # Create the SQL INSERT statement
                    sql_command = (
                        f"INSERT INTO ohe_poles (route_id, pole_no, km, height_m, geom) VALUES ("
                        f"(SELECT id FROM cable_routes WHERE name = '{route_name_sql}'), "
                        f"'{pole_no_sql}', "
                        f"'{km_sql}', "
                        f"{height_m}, "
                        f"ST_GeomFromGeoJSON('{geometry_object_string}')"
                        f");\n"
                    )
                    
                    f_out.write(sql_command)
                    feature_count += 1
            
            if feature_count > 0:
                print(f"✅ Success! {feature_count} INSERT commands have been written to {output_sql_file}")
                print("You can now run this file in your database client (like DBeaver).")
            else:
                print("⚠️ No Point features were found in the file.")

    except FileNotFoundError:
        print(f"❌ Error: The file '{file_path}' was not found.")
    except json.JSONDecodeError:
        print(f"❌ Error: The file '{file_path}' is not a valid JSON file.")
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

# --- Main execution ---
if __name__ == "__main__":
    input_file = input("Enter the path to your Point GeoJSON file: ")
    input_route_name = input("Enter the EXACT name of the route these poles belong to: ")
    generate_poles_sql(input_file, input_route_name)
# Supabase Map Data Integration

This guide explains how to configure the map data integration with Supabase in your Flutter Rail App.

## Overview

The app now fetches map data (routes, poles, and inspections) from Supabase instead of using static data. The integration includes:

- **Routes**: Railway routes with coordinates for polylines
- **Poles**: Individual poles along routes with position markers
- **Inspections**: Inspection records linked to routes and poles

## Files Modified

1. **`lib/map_data_service.dart`** - Service layer for Supabase communication
2. **`lib/map_view_page.dart`** - Updated to use live data from Supabase
3. **`pubspec.yaml`** - Added fluttertoast dependency

## Database Setup Required

### 1. Create Tables in Supabase

You need to create the following tables in your Supabase database:

#### Routes Table
```sql
CREATE TABLE railway_routes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  geometry JSONB, -- Array of coordinates: [{"lat": 28.6139, "lng": 77.2090}, ...]
  last_maintenance TIMESTAMP,
  status TEXT DEFAULT 'active',
  route_type TEXT DEFAULT 'all', -- 'macro', 'micro', or 'all'
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Poles Table
```sql
CREATE TABLE railway_poles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  route_id UUID REFERENCES railway_routes(id),
  name TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  height DECIMAL(5, 2) DEFAULT 0.0,
  status TEXT DEFAULT 'active',
  last_inspection TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Inspections Table
```sql
CREATE TABLE inspections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  route_id UUID REFERENCES railway_routes(id),
  pole_id UUID REFERENCES railway_poles(id),
  inspector_name TEXT NOT NULL,
  inspection_date TIMESTAMP DEFAULT NOW(),
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  notes TEXT,
  photos TEXT[], -- Array of photo URLs
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 2. Configure Table Names

Open `lib/map_data_service.dart` and update the table names if different:

```dart
// TODO: Replace these table names with your actual Supabase table names
static const String _routesTableName = 'railway_routes'; // Your routes table name
static const String _polesTableName = 'railway_poles'; // Your poles table name
static const String _inspectionsTableName = 'inspections'; // Your inspections table name
```

### 3. Configure Field Names

If your database uses different field names, update the model factories:

#### RouteData.fromMap()
```dart
// TODO: Replace 'geometry' with your actual coordinate field name
coordinates: _parseCoordinates(map['geometry'] ?? map['coordinates'] ?? []),
```

#### PoleData.fromMap()
```dart
// TODO: Replace 'latitude' and 'longitude' with your actual field names
position: LatLng(
  (map['latitude'] ?? map['lat'] ?? 0.0).toDouble(),
  (map['longitude'] ?? map['lng'] ?? 0.0).toDouble(),
),
```

## Sample Data

### Insert Sample Route
```sql
INSERT INTO railway_routes (name, description, geometry, status, route_type) VALUES
('Delhi Metro Red Line', 'Main metro route through Delhi', 
 '[{"lat": 28.6139, "lng": 77.2090}, {"lat": 28.6200, "lng": 77.2150}, {"lat": 28.6250, "lng": 77.2200}]',
 'active', 'macro');
```

### Insert Sample Poles
```sql
INSERT INTO railway_poles (route_id, name, latitude, longitude, height, status) VALUES
((SELECT id FROM railway_routes WHERE name = 'Delhi Metro Red Line'), 'Pole-001', 28.6139, 77.2090, 12.5, 'active'),
((SELECT id FROM railway_routes WHERE name = 'Delhi Metro Red Line'), 'Pole-002', 28.6200, 77.2150, 12.5, 'active');
```

### Insert Sample Inspection
```sql
INSERT INTO inspections (route_id, pole_id, inspector_name, status, notes) VALUES
((SELECT id FROM railway_routes WHERE name = 'Delhi Metro Red Line'),
 (SELECT id FROM railway_poles WHERE name = 'Pole-001'),
 'John Doe', 'completed', 'All systems normal');
```

## Features

### Map View Features
- **Route Visualization**: Routes are displayed as colored polylines
- **Pole Markers**: Poles show as orange electrical service icons
- **Inspection Markers**: Color-coded based on status (green=completed, orange=pending, red=failed)
- **Filter Options**: 
  - Macro: Shows routes with thicker lines
  - Micro: Shows poles and detailed markers
  - All: Shows everything including inspections

### Interactive Elements
- **Pole Click**: Shows pole information dialog with inspection option
- **Inspection Click**: Shows detailed inspection information
- **Refresh Button**: Reloads data from Supabase
- **Add Inspection**: Opens dialog to add new inspections

### Error Handling
- Toast notifications for data loading errors
- Graceful fallbacks for missing data
- Loading indicators during data fetch

## Troubleshooting

### No Data Showing
1. Check your Supabase connection in `lib/supabase_config.dart`
2. Verify table names in `map_data_service.dart`
3. Ensure Row Level Security (RLS) policies allow reading
4. Check browser console for network errors

### Incorrect Positions
1. Verify coordinate field names in `PoleData.fromMap()`
2. Check that coordinates are in decimal degrees format
3. Ensure longitude/latitude are not swapped

### Permission Errors
1. Set up RLS policies in Supabase for authenticated users
2. Check user authentication status
3. Verify API keys and project URL

## Next Steps

1. **Customize Database Schema**: Adapt table structures to your needs
2. **Add Real-time Updates**: Use Supabase subscriptions for live updates
3. **Implement Inspection Form**: Create full CRUD interface for inspections
4. **Add Caching**: Implement offline caching for better performance
5. **Custom Map Styles**: Add different map themes and overlays

## Support

- Check Supabase documentation for database setup
- Review Flutter Map documentation for map customization
- Refer to the app's existing authentication setup in `SUPABASE_AUTH_SETUP.md`

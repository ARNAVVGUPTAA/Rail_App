# Supabase Authentication Setup

This Flutter app uses Supabase for authentication. To get it working, you need to set up your Supabase project credentials.

## Setup Instructions

1. **Create a Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new account or sign in
   - Create a new project

2. **Get Your Project Credentials**
   - In your Supabase dashboard, go to Settings > API
   - Copy your `Project URL` and `anon/public key`

3. **Update the Configuration**
   - Open `lib/supabase_config.dart`
   - Replace `YOUR_SUPABASE_PROJECT_URL` with your actual project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your actual anon key

   ```dart
   static const String supabaseUrl = 'https://your-project-ref.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key-here';
   ```

4. **Set up Authentication in Supabase**
   - In your Supabase dashboard, go to Authentication
   - Configure your authentication settings as needed
   - Enable email confirmations if desired

## Features Implemented

- ✅ Email/Password Sign Up
- ✅ Email/Password Sign In
- ✅ Password Reset (Forgot Password)
- ✅ User Session Management
- ✅ Automatic Auth State Handling
- ✅ Logout Functionality

## Authentication Flow

1. App starts with `AuthWrapper` that checks authentication state
2. If user is not authenticated → `LoginPage`
3. User can sign in or navigate to `SignupPage`
4. After successful authentication → `RoleSelectionPage`
5. User can logout from the role selection page

## Error Handling

The app includes comprehensive error handling with toast messages for:
- Invalid email formats
- Empty fields
- Authentication errors
- Network errors

## Security Note

Never commit your actual Supabase keys to version control. Consider using environment variables or Flutter's build configurations for production apps.

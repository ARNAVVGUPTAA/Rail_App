# Supabase Authentication Setup Guide

## 🚀 Getting Started with Supabase

### Step 1: Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in your project details:
   - **Name**: Your app name (e.g., "Rail App")
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to your users
5. Click "Create new project"

### Step 2: Get Your API Keys
1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these two values:
   - **Project URL**: `https://your-project-ref.supabase.co`
   - **anon public key**: Long string starting with `eyJ...`

### Step 3: Update Your Flutter App
1. Open `lib/supabase_config.dart`
2. Replace the placeholder values:

```dart
static const String supabaseUrl = 'https://your-project-ref.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### Step 4: Enable Authentication
1. In Supabase dashboard, go to **Authentication** → **Settings**
2. Under **Auth Providers**, make sure **Email** is enabled
3. Configure your site URL (for email verification):
   - Site URL: `https://your-app-domain.com` (or `http://localhost:3000` for development)

### Step 5: Test Your Setup
1. Run your Flutter app: `flutter run`
2. Try creating a new account
3. Check your Supabase dashboard under **Authentication** → **Users** to see if users are being created

## 🔒 Security Notes

- **Never commit your keys to public repositories**
- The `anon` key is safe to use in client apps
- For production, consider using environment variables
- Set up Row Level Security (RLS) policies in Supabase for data protection

## 📧 Email Configuration (Optional)
To enable email verification and password reset:
1. Go to **Authentication** → **Settings**
2. Configure SMTP settings or use Supabase's built-in email service
3. Customize email templates if needed

## 🎯 Ready to Use Features
Once configured, your app will have:
- ✅ User registration with email/password
- ✅ User login
- ✅ Password reset via email
- ✅ Automatic session management
- ✅ Logout functionality

## 🆘 Troubleshooting
- **"Invalid API key"**: Double-check your URL and anon key
- **"User not confirmed"**: Check if email confirmation is required
- **Network errors**: Verify your internet connection and Supabase project status

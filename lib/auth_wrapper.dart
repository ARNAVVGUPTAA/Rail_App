import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loginpage.dart';
import 'role_selection_page.dart';
import 'supabase_config.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    // Always start fresh - clear any existing session for testing
    print('Initializing auth - clearing any existing session');
    await supabase.auth.signOut();

    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print(
          'Auth state changed: ${event.name}, Session: ${session?.user.email ?? 'No session'}');

      if (mounted) {
        if (event == AuthChangeEvent.signedIn && session != null) {
          // User signed in, navigate to role selection
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const RoleSelectionPage(),
            ),
          );
        } else if (event == AuthChangeEvent.signedOut) {
          // User signed out, navigate to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always start with login page to ensure proper auth flow
    return const LoginPage();
  }
}

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

  void _initializeAuth() {
    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

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
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is authenticated
          return const RoleSelectionPage();
        } else {
          // User is not authenticated
          return const LoginPage();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth.dart';
import '../screens/home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored preferences
      
      // Only sign out if there's a current user
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If there's an error in the auth state
        if (snapshot.hasError) {
          _clearAuthState();
          return const AuthPage();
        }

        // If user is logged in and data is valid
        if (snapshot.hasData && snapshot.data != null) {
          // Verify the user's token is still valid
          return FutureBuilder<IdTokenResult>(
            future: snapshot.data!.getIdTokenResult(),
            builder: (context, tokenSnapshot) {
              if (tokenSnapshot.hasError || 
                  tokenSnapshot.data?.token == null) {
                _clearAuthState();
                return const AuthPage();
              }
              return const HomeScreen();
            },
          );
        }

        // If no user is logged in
        return const AuthPage();
      },
    );
  }
}

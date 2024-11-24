import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SharedPreferences _prefs;

  AuthService(this._prefs) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _auth.setLanguageCode('en');
    } catch (e) {
      print('Firebase Auth initialization error: $e');
    }
  }

  // Get remembered credentials
  String? getRememberedEmail() => _prefs.getString('remembered_email');
  String? getRememberedPassword() => _prefs.getString('remembered_password');

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      print('Attempting to sign in with email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('Sign in successful for user: ${credential.user?.email}');

      if (rememberMe) {
        await _prefs.setString('remembered_email', email);
        await _prefs.setString('remembered_password', password);
      } else {
        await _prefs.remove('remembered_email');
        await _prefs.remove('remembered_password');
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Register with email and password
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Attempting to register with email: $email');

      // Sign out any existing user first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('Registration successful for user: ${credential.user?.email}');
    } on FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException during registration: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process');

      // Sign out any existing user first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In aborted by user');
        throw 'Google sign in was cancelled';
      }

      print('Getting Google auth credentials');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with Google credential');
      await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error during Google Sign In: $e');
      if (e is FirebaseAuthException) {
        throw _handleAuthError(e);
      }
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user');
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _prefs.clear(); // Clear all stored preferences
      print('Sign out successful');
    } catch (e) {
      print('Error during sign out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    print('Handling auth error: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Please enter a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

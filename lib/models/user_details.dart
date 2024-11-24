import 'package:firebase_auth/firebase_auth.dart';

class UserDetails {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserDetails({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserDetails.fromFirebaseUser(User user) {
    return UserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }
}

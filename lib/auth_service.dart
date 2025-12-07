import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:io_mom/smtp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginType'); // ← always clear old value first

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        await prefs.setString('loginType', 'Canceled');
        return null;
      }

      var user = await dbService.getUserByEmail(googleUser.email);

      if (user != null && user.loginType == 'P') {
        await prefs.setString('loginType', 'Password');
        return null;
      }
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in into Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google Sign-in Error: $e");
      return null;
    }
  }
}

Future<Users?> getUser(String uid) async {
  final dbService = await DatabaseService();
    return dbService.getUserByUID(uid);
}
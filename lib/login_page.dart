import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_home_page.dart';
import 'auth_service.dart';
import 'cc_register_page.dart';
import 'forget_password.dart';
import 'otp_page.dart';
import 'smtp_service.dart';
import 'home.dart';
import 'user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final dbService = DatabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      await _showDialog('Login Failed', 'Please fill in both email and password.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Attempt sign-in
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final firebaseUser = userCredential.user;

      // If login successful → check user type and send OTP
      if (firebaseUser != null) {
        final userEmail = firebaseUser.email;
        if (userEmail == null || userEmail.isEmpty) {
          await _showDialog('Login Failed', 'Account has no email.');
          return;
        }

        final trimmedEmail = userEmail.trim();
        final prefs = await SharedPreferences.getInstance();

        // ✅ Check for admin using email directly (safer)
        if (trimmedEmail == 'admin@iomom.com') {
          await prefs.setString('userID', firebaseUser.uid);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminHomePage()),
          );
        } else {
          // Regular user - send OTP
          final otp = generateOtp();
          await sendOtpEmail(trimmedEmail, otp);

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpPage(
                email: trimmedEmail,
                expectedOtp: otp,
                isFrom: "Login",
                issuedAt: DateTime.now(),
                password: "",
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      await _showDialog('Login Failed', 'Invalid email or password. Please try again.');
    } catch (e) {
      await _showDialog('Error', 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // CHANGED: prevents content from moving up when keyboard appears
      body: Column(
        children: [
          // Main scrollable content - takes up remaining space
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo/logo.png', height: 120),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Io",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: "Mom",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: pink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("E Mail",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Password",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "********",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      ),
                      child: const Text("Forgot password?",
                          style: TextStyle(color: pink, fontWeight: FontWeight.w500)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Login",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.black54)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        ),
                        child: const Text("Sign Up",
                            style: TextStyle(color: pink, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: Image.asset('assets/images/logo/google.png', height: 24),
                      label: const Text("Login with Google"),
                      onPressed: () async {
                        final authService = AuthService();
                        final user = await authService.signInWithGoogle();
                        final prefs = await SharedPreferences.getInstance();
                        final loginType = await prefs.getString('loginType');

                        if (loginType == 'Password') {
                          await _showDialog('Login Cancelled', 'Please sign in with your password.');
                          await prefs.remove('loginType');
                          return;
                        } else if (loginType == 'Canceled') {
                          await _showDialog('Login Cancelled', 'You cancelled Google sign in.');
                          await prefs.remove('loginType');
                          return;
                        }

                        final email = user!.email;
                        if (email == null || email.isEmpty) {
                          await _showDialog('Login Failed', 'Google account has no email.');
                          return;
                        }

                        final uid = user.uid;

                        try {
                          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

                          if (methods.contains('password')) {
                            final googleSignIn = GoogleSignIn();
                            await googleSignIn.signOut();

                            await _showDialog(
                              'Login Failed',
                              'This email is already registered with a password. Please login using your email and password instead.',
                            );
                            return;
                          }
                        } catch (e) {
                          debugPrint("Firebase fetchSignInMethods error: $e");
                        }

                        final existingUser = await dbService.getUserByEmail(email);

                        if (existingUser == null) {
                          final newUser = Users(
                            userID: uid,
                            userName: "",
                            userEmail: email,
                            userRegDate: DateTime.now(),
                            phoneNo: "",
                            userStatus: "A",
                            profileImgPath: "",
                            userRole: "",
                            loginType: "G",
                              isPhoneVerify: "F",
                          );
                          await dbService.insertUser(newUser);
                        }

                        await prefs.setString('userID', uid);

                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomePage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed collaboration link - always at the bottom
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestCollaborationPage()),
                  ),
                  child: const Text(
                    "Confinement Center Collaboration",
                    style: TextStyle(
                      color: pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

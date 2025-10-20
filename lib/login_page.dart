import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
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

      // If login successful → send OTP
      if (firebaseUser != null) {
        final otp = generateOtp();
        await sendOtpEmail(firebaseUser.email!.trim(), otp);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              email: firebaseUser.email!,
              expectedOtp: otp,
              isFrom: "Login",
              issuedAt: DateTime.now(),
              password: "",
            ),
          ),
        );
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
      body: SingleChildScrollView(
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
                const Text("Don’t have an account? ",
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

                  if (user == null) {
                    await _showDialog('Login Cancelled', 'You cancelled Google sign in.');
                    return;
                  }

                  final email = user.email!;
                  final uid = user.uid;

                  // 🔎 Step 1: Check if this email exists in Firebase (email/password account)
                  try {
                    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

                    if (methods.contains('password')) {
                      // 🚫 Email already registered using password
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

                  // 🔎 Step 2: Check if this email already exists in your local SQLite DB
                  final existingUser = await dbService.getUserByEmail(email);

                  if (existingUser == null) {
                    // 🟢 New Google user → insert into DB
                    final newUser = Users(
                      userID: uid,
                      userName: "",
                      userEmail: email,
                      userRegDate: DateTime.now(),
                      phoneNo: "",
                      userStatus: "A",
                      profileImgPath: "",
                    );
                    await dbService.insertUser(newUser);
                  }

                  // 💾 Step 3: Save user locally
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userID', uid);

                  // 🏠 Step 4: Navigate to home page
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
    );
  }
}

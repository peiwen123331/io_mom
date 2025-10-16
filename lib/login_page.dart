import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/register_page.dart';
import 'auth_service.dart';
import 'forget_password.dart';
import 'otp_page.dart';
import 'smtp_service.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  final dbService = DatabaseService();

  bool _emailExists = false;
  bool _checkingEmail = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(seconds: 1), () async {
      final email = _emailController.text.trim();

      if (email.isEmpty || !email.contains("@")) {
        setState(() {
          _emailExists = false;
          _checkingEmail = false;
        });
        return;
      }

      setState(() => _checkingEmail = true);

      final user = await dbService.getUserByEmail(email);
      if (!mounted) return;

      setState(() {
        _checkingEmail = false;
        _emailExists = user != null;
      });
    });
  }

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        await _showDialog('Login Failed', 'Please fill in both email and password.');
        return;
      }

      if (!_emailExists) {
        await _showDialog('Login Failed',
            'User does not exist. Please register before logging in.');
        return;
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final firebaseUser = userCredential.user;
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
    } on FirebaseAuthException {
      await _showDialog('Login Failed', 'The password is incorrect. Please try again.');
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
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            // Logo
            Image.asset('assets/images/logo/logo.png', height: 120),
            const SizedBox(height: 16),

            // App Name
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: "Io",
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: "Mom",
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: pink)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Email label
            Align(
              alignment: Alignment.centerLeft,
              child: Text("E Mail",
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            const SizedBox(height: 6),

            // Email field + status
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter here...",
                suffixIcon: _checkingEmail
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : _emailController.text.isEmpty
                    ? null
                    : Icon(
                  _emailExists ? Icons.check_circle : Icons.error_outline,
                  color: _emailExists ? Colors.green : Colors.red,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            if (_emailController.text.isNotEmpty && !_checkingEmail)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailExists
                        ? "Email found in system ✓"
                        : "Email not registered. Please sign up.",
                    style: TextStyle(
                      color: _emailExists ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Password label
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Password",
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "********",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

            // Login Button
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
                const Text("Don’t have account? ",
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
                  final user = await AuthService().signInWithGoogle();
                  if (user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  }
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

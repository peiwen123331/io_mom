import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_page.dart';
import 'smtp_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _passwordError;
  String? _emailError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Password validation rules
  List<String> validatePassword(String password) {
    List<String> errors = [];
    if (password.length < 8) errors.add("At least 8 characters");
    if (password.length > 16) errors.add("At most 16 characters");
    if (!RegExp(r'[A-Z]').hasMatch(password)) errors.add("One uppercase letter");
    if (!RegExp(r'[a-z]').hasMatch(password)) errors.add("One lowercase letter");
    if (!RegExp(r'[0-9]').hasMatch(password)) errors.add("One number");
    if (!RegExp(r'[$@!#.&_-]').hasMatch(password)) errors.add("One special symbol \$@!#.&_-");
    return errors;
  }

  void validatePasswordMatch() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final rules = validatePassword(password);
    if (rules.isNotEmpty) {
      setState(() => _passwordError = rules.join(", "));
    } else if (password != confirm) {
      setState(() => _passwordError = "Passwords do not match");
    } else {
      setState(() => _passwordError = null);
    }
  }

  Future<void> _register() async {
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      await _showDialog("Error", "Please fill in all fields.");
      setState(() => _loading = false);
      return;
    }

    validatePasswordMatch();
    if (_passwordError != null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // ✅ Try creating a Firebase account
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Send OTP after successful registration
      final otp = generateOtp();
      await sendOtpEmail(email, otp);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: email,
            expectedOtp: otp,
            isFrom: "Register",
            issuedAt: DateTime.now(),
            password: password,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle common registration errors
      if (e.code == 'email-already-in-use') {
        await _showDialog(
          'Registration Failed',
          'This email is already registered. Please login instead.',
        );
      } else if (e.code == 'invalid-email') {
        await _showDialog('Registration Failed', 'Invalid email format.');
      } else if (e.code == 'weak-password') {
        await _showDialog('Registration Failed', 'Password is too weak.');
      } else {
        await _showDialog('Error', e.message ?? 'Unknown error occurred.');
      }
    } catch (e) {
      await _showDialog('Error', 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const Text(
                "Enter your details below to sign up",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Enter your email",
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "example@gmail.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Create your password",
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => validatePasswordMatch(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9$@!#.&_-]')),
                ],
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
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Confirm your password",
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onChanged: (_) => validatePasswordMatch(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9$@!#.&_-]')),
                ],
                decoration: InputDecoration(
                  hintText: "********",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  errorText: _passwordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Login",
                        style:
                        TextStyle(color: pink, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

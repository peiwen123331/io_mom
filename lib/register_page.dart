import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database.dart';
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
  final dbService = DatabaseService();

  bool _loading = false;
  String? _passwordError;
  String? _emailError;

  // OTP generator
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

  // Check user existence in real time
  Future<void> checkUserExistence(String email) async {
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final user = await dbService.getUserByEmail(email);
    setState(() {
      _emailError = (user != null) ? "This email is already registered" : null;
    });
  }

  // password validation
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

  // Register function
  Future<void> _register() async {
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_emailError != null || _passwordError != null) {
      setState(() => _loading = false);
      return;
    }

    try {
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Error: $e"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pink = const Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo/logo.png', // Change this to your logo path
                height: 120,
              ),
              const SizedBox(height: 16),
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
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink)),
                  ],
                ),
              ),
              const Text(
                "Enter your details below to sign up",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Enter your email",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: checkUserExistence,
                decoration: InputDecoration(
                  hintText: "example@gmail.com",
                  errorText: _emailError,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Create your password",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => validatePasswordMatch(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9$@!#.&_-]')),
                ],
                decoration: InputDecoration(
                  hintText: "********",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Confirm your password",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                onChanged: (_) => validatePasswordMatch(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9$@!#.&_-]')),
                ],
                decoration: InputDecoration(
                  hintText: "********",
                  errorText: _passwordError,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Sign Up button
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
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(color: pink, fontWeight: FontWeight.bold),
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

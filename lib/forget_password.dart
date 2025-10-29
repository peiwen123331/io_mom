import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:io_mom/database.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  final dbService = DatabaseService();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _resetSent = false;

  bool _emailValid = false;
  String? _emailStatusMsg;
  Timer? _debounce;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _showDialog("Success",
          "A password reset link has been sent to your email.");

      setState(() => _resetSent = true);
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        await _showDialog("Network Error",
            "Please check your internet connection and try again.");
      } else {
        await _showDialog("Error", e.message ?? "Something went wrong");
      }
    } catch (e) {
      await _showDialog("Error", "Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCooldown() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _showDialog(String title, String message) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = !_resetSent
        ? "Reset Password"
        : _secondsLeft > 0
        ? "Request Again in $_secondsLeft s"
        : "Request Again";

    final buttonEnabled = _emailValid && (!_resetSent || _secondsLeft == 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/images/logo/logo.png', // replace with your actual logo path
                height: 100,
              ),
              const SizedBox(height: 24),

              // App name
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                        text: "Io",
                        style:
                        TextStyle(color: Colors.black, fontFamily: 'Poppins')),
                    TextSpan(
                        text: "Mom",
                        style: TextStyle(
                            color: Color(0xFFE91E63), fontFamily: 'Poppins')),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Title
              const Text(
                "Password Recovery",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C2541),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              const Text(
                "Enter your email to recover your password",
                style: TextStyle(color: Color(0xFF7B7B8B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Email label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "E Mail",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter here...",
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Email validation feedback
              if (_emailStatusMsg != null)
                Text(
                  _emailStatusMsg!,
                  style: TextStyle(
                    color: _emailValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 24),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: buttonEnabled ? _sendResetEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Login redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

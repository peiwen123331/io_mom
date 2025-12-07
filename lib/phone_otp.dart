import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneOtpPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String from; // Can be "Register", "EditProfile", etc.

  const PhoneOtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.from,
  });

  @override
  State<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends State<PhoneOtpPage> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _attempts = 0;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isLoading = false;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startCooldown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _enteredOtp =>
      _otpControllers.map((controller) => controller.text).join();

  void _startCooldown() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final entered = _enteredOtp.trim();

    if (entered.length != 6) {
      _showSnackBar("Please enter the 6-digit OTP", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create PhoneAuthCredential with the verification ID and SMS code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: entered,
      );

      // Link or sign in with the credential
      if (widget.from == "EditProfile" || widget.from == "Register") {
        // Link phone number to existing user
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          await currentUser.linkWithCredential(credential);

          if (!mounted) return;
          await _showDialog(
            "Success",
            "Phone number verified successfully!",
            onConfirm: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous page with success
            },
          );
        } else {
          throw Exception("No user is currently logged in");
        }
      } else {
        // Sign in with phone credential (standalone phone authentication)
        await _auth.signInWithCredential(credential);

        if (!mounted) return;
        await _showDialog(
          "Success",
          "Phone number verified successfully!",
          onConfirm: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context, true); // Return to previous page with success
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      _attempts++;

      if (e.code == 'invalid-verification-code') {
        if (_attempts >= 3) {
          if (!mounted) return;
          await _showDialog(
            "Too Many Failed Attempts",
            "Please request a new OTP code.",
            onConfirm: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Return to previous page
            },
          );
        } else {
          _showSnackBar(
            "Invalid OTP. Attempts left: ${3 - _attempts}",
            Colors.redAccent,
          );
        }
      } else if (e.code == 'session-expired') {
        _showSnackBar(
          "OTP has expired. Please request a new one.",
          Colors.orangeAccent,
        );
      } else if (e.code == 'credential-already-in-use') {
        _showSnackBar(
          "This phone number is already linked to another account.",
          Colors.redAccent,
        );
      } else {
        _showSnackBar(
          "Verification failed: ${e.message}",
          Colors.redAccent,
        );
      }
    } catch (e) {
      _showSnackBar("Unexpected error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            if (widget.from == "EditProfile" || widget.from == "Register") {
              await _auth.currentUser?.linkWithCredential(credential);
            } else {
              await _auth.signInWithCredential(credential);
            }

            if (!mounted) return;
            _showSnackBar("Phone verified automatically!", Colors.green);
            Navigator.pop(context, true);
          } catch (e) {
            _showSnackBar("Auto-verification failed", Colors.redAccent);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            _showSnackBar(
              "Failed to send OTP: ${e.message}",
              Colors.redAccent,
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _currentVerificationId = verificationId;
          });
          _startCooldown();
          _showSnackBar(
            "New OTP sent to ${widget.phoneNumber}",
            Colors.green,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _currentVerificationId = verificationId;
          });
        },
      );
    } catch (e) {
      _showSnackBar("Failed to resend OTP: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showDialog(String title, String message,
      {VoidCallback? onConfirm}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onConfirm ??
                    () {
                  Navigator.pop(context);
                },
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: _otpControllers[index],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Image.asset(
                      'assets/images/logo/logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: "Io", style: TextStyle(color: Colors.black)),
                          TextSpan(
                            text: "Mom",
                            style: TextStyle(color: Color(0xFFE91E63)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Verify Phone Number",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2541),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "We have just sent a code to\n${widget.phoneNumber}",
                      style: const TextStyle(color: Color(0xFF7B7B8B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildOtpFields(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          disabledBackgroundColor: Colors.grey,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "Verify",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _secondsLeft == 0 && !_isLoading
                            ? _resendOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondsLeft == 0
                              ? const Color(0xFFF8F8F8)
                              : const Color(0xFFEFEFEF),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFFEFEFEF),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _secondsLeft == 0
                              ? "Send again"
                              : "Send again in $_secondsLeft s",
                          style: TextStyle(
                            color: _secondsLeft == 0
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
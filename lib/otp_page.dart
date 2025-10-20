import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/reset_password.dart';
import 'home.dart';
import 'login_page.dart';
import 'smtp_service.dart';
import 'user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String expectedOtp;
  final String isFrom;
  final DateTime issuedAt;
  final String password;

  const OtpPage({
    super.key,
    required this.email,
    required this.expectedOtp,
    required this.isFrom,
    required this.issuedAt,
    required this.password,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  int _attempts = 0;
  int _secondsLeft = 60;
  Timer? _timer;
  late String expectedOTP = widget.expectedOtp;

  @override
  void initState() {
    super.initState();
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

  //save in to user sharedPreference
  Future<void> saveUserID(String userID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', userID);
  }

  Future<void> _verifyOtp() async {
    final entered = _enteredOtp.trim();
    late Users users;
    final dbService = DatabaseService();

    if (entered.length != 6) {
      await _showDialog("Error", "Please enter the 6-digit OTP.");
      return;
    }

    if (entered == expectedOTP) {
      if (!mounted) return;

      if (widget.isFrom == "Register") {
        try {
          UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

          final uid = cred.user!.uid;
          users = Users(
            userID: uid,
            userName: "",
            userEmail: widget.email,
            userRegDate: DateTime.timestamp(),
            phoneNo: "",
            userStatus: "A",
            profileImgPath: "",
          );

          dbService.insertUser(users);

          await _showDialog("Success", "Registration successful. Please log in.",
              redirectTo: const LoginPage());
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            await _showDialog(
              "Registration Failed",
              "This email is already registered. Please login instead.",
              redirectTo: const LoginPage(),
            );
          } else {
            await _showDialog("Error", e.message ?? "Unknown error");
          }
        }
      } else if (widget.isFrom == "Login") {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          String uid = user.uid;
          print("Current UID: $uid");

          // save uid to SharedPreference
          await saveUserID(uid);

        } else {
          print("No user is logged in");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );

      } else if (widget.isFrom == "ResetPassword") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => ResetPasswordPage(email: widget.email)),
              (route) => false,
        );
      }
    } else {
      _attempts++;
      if (_attempts >= 3) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        await _showDialog("Too Many Failed Attempts", "Please login again.",
            redirectTo: const LoginPage());
      } else {
        await _showDialog("Invalid OTP", "Attempts left: ${3 - _attempts}");
      }
    }
  }
  // OTP generator
  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _requestOtp() async {
    _startCooldown();
    final otp = generateOtp();
    await sendOtpEmail(widget.email, otp);
    await _showDialog(
        "OTP Sent", "A new OTP has been sent to ${widget.email}.");
    setState(() {
      expectedOTP = otp;
    });
  }

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

  Future<void> _showDialog(String title, String message,
      {Widget? redirectTo}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (redirectTo != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => redirectTo),
                      (route) => false,
                );
              }
            },
            child: const Text("OK"),
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
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent),
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
    final resendEnabled = _secondsLeft == 0;
    final resendText = resendEnabled
        ? "Send again"
        : "Send again in $_secondsLeft s";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Back Button fixed at top-left corner ---
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // --- Main content centered ---
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60), // space below back button
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
                              style: TextStyle(color: Color(0xFFE91E63))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2541),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "We have just sent a code to\n${widget.email}",
                      style: const TextStyle(color: Color(0xFF7B7B8B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildOtpFields(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Proceed",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _secondsLeft == 0 ? _requestOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondsLeft == 0
                              ? const Color(0xFFF8F8F8)
                              : const Color(0xFFEFEFEF),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_secondsLeft == 0
                            ? "Send again"
                            : "Send again in $_secondsLeft s"),
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

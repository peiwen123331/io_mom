import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  List<String> _passwordErrors = [];
  String? _matchError;

  // Client-side password rule validation
  List<String> _validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 8) errors.add("At least 8 characters");
    if (password.length > 16) errors.add("At most 16 characters");
    if (!RegExp(r'[A-Z]').hasMatch(password)) errors.add("One uppercase letter");
    if (!RegExp(r'[a-z]').hasMatch(password)) errors.add("One lowercase letter");
    if (!RegExp(r'[0-9]').hasMatch(password)) errors.add("One number");
    if (!RegExp(r'[$@!#.&_-]').hasMatch(password)) {
      errors.add("One special symbol \$@!#.&_-");
    }

    return errors;
  }

  // 🔄 Real-time checks
  void _onNewPasswordChanged(String value) {
    final errors = _validatePassword(value);
    setState(() {
      _passwordErrors = errors;
      _matchError = _confirmPasswordController.text.isEmpty
          ? null
          : (_confirmPasswordController.text == value ? null : "Passwords do not match");
    });
  }

  void _onConfirmPasswordChanged(String value) {
    setState(() {
      _matchError =
      value == _newPasswordController.text ? null : "Passwords do not match";
    });
  }

  // 🔐 Reset password via Firebase
  Future<void> _resetPassword() async {
    if (_passwordErrors.isNotEmpty || _matchError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix password issues before continuing")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception("User not signed in");

      // Reauthenticate with old password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      // ✅ Show success dialog asking to re-login
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false, // prevent closing by tapping outside
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Password Changed",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Your password has been changed successfully.\n\nFor security reasons, please log in again.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Sign out the current user
                  await FirebaseAuth.instance.signOut();

                  // Navigate to login page
                  if (context.mounted) {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
                  }
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset password: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Change Password"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- Logo ---
                Column(
                  children: [
                    Image.asset('assets/images/logo/logo.png', height: 120),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                          TextSpan(text: 'Io'),
                          TextSpan(
                            text: 'Mom',
                            style: TextStyle(color: Colors.pink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Title ---
                const Text(
                  "Reset your password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C3C57),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "At least 8 characters including uppercase and lowercase letters",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 36),

                // --- Old password ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create your password",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOld,
                  decoration: InputDecoration(
                    hintText: "********",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOld
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                  ),
                ),

                const SizedBox(height: 20),

                // --- New password ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create your password",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  onChanged: (value) {
                    _onNewPasswordChanged(value);
                    setState(() {}); // Refresh rule icons
                  },
                  decoration: InputDecoration(
                    hintText: "********",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                  ),
                ),
                const SizedBox(height: 8),
                
                passwordRules(_newPasswordController.text),

                /*if (_passwordErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _passwordErrors
                          .map(
                            (e) => Text(
                          "• $e",
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      )
                          .toList(),
                    ),
                  ),*/

                const SizedBox(height: 20),

                // --- Confirm password ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Confirm your password",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  onChanged: _onConfirmPasswordChanged,
                  decoration: InputDecoration(
                    hintText: "********",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                  ),
                ),
                if (_matchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _matchError!,
                        style:
                        const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),

                const SizedBox(height: 36),

                // --- Reset Button ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Reset Password",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget passwordRules(String password) {
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSymbol = RegExp(r'[$@!#.&_-]').hasMatch(password);
    bool hasMinLength = password.length >= 8;
    bool hasMaxLength = password.length <= 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ruleItem("At least 8 characters", hasMinLength),
        ruleItem("At most 16 characters", hasMaxLength),
        ruleItem("One uppercase letter (A–Z)", hasUpper),
        ruleItem("One lowercase letter (a–z)", hasLower),
        ruleItem("One number (0–9)", hasNumber),
        ruleItem("One special symbol \$@!#.&_-", hasSymbol),
      ],
    );
  }

  Widget ruleItem(String text, bool fulfilled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            fulfilled ? Icons.check_circle : Icons.circle_outlined,
            color: fulfilled ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fulfilled ? Colors.green : Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }



}

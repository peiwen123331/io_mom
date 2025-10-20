import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:io_mom/database.dart';
import 'login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final dbService = DatabaseService();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _showDialog(String title, String message, {bool isError = false}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: isError ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  /// 🔒 Shows a confirmation dialog before proceeding
  Future<bool> _confirmDeleteDialog() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirm Deletion",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to permanently delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              confirmed = false;
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context);
              confirmed = true;
            },
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirmed;
  }

  Future<void> _deleteAccount() async {
    // 🧠 Ask for confirmation before continuing
    final confirm = await _confirmDeleteDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user signed in.");
      }

      final providerId = user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password';

      // --- 1️⃣ Reauthenticate based on provider ---
      if (providerId == 'password') {
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          await _showDialog("Missing Password", "Please enter your password.", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

      } else if (providerId == 'google.com') {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          await _showDialog("Cancelled", "Google sign-in was cancelled.", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // --- 2️⃣ Delete from Firestore / Realtime DB ---
      await dbService.deleteUser(user.uid);

      // --- 3️⃣ Delete Firebase Auth account ---
      await user.delete();

      // --- 4️⃣ Clear local data ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("userID");

      if (!mounted) return;
      await _showDialog("Account Deleted", "Your account has been successfully deleted.");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Failed to delete account.";
      if (e.code == 'wrong-password') {
        message = "Incorrect password. Please try again.";
      } else if (e.code == 'requires-recent-login') {
        message = "Please log in again before deleting your account.";
      } else {
        message = e.message ?? message;
      }
      await _showDialog("Error", message, isError: true);
    } catch (e) {
      await _showDialog("Error", "Something went wrong: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser = user?.providerData.first.providerId == 'google.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Delete Account"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              Image.asset('assets/images/logo/logo.png', height: 120),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: 'Io'),
                    TextSpan(text: 'Mom', style: TextStyle(color: Colors.pink)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Delete your account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3C57),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isGoogleUser
                    ? "Please confirm by signing in again with Google to delete your account."
                    : "Please confirm your password to permanently delete your account.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 36),

              if (!isGoogleUser)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your password",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "********",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "This action cannot be undone.",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

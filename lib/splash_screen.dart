import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home.dart';
import 'edit_profile.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {
    await Future.delayed(const Duration(seconds: 3)); // Show logo for 3 sec
    final dbService = DatabaseService();
    final prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');


    if (userID != null) {
      final user = await dbService.getUserByUID(userID);

      if (user != null) {
        //check profile complete or not if not link to edit profile page
        bool isProfileComplete =
            (user.userName != null && user.userName!.isNotEmpty) &&
                (user.phoneNo != null && user.phoneNo!.isNotEmpty) &&
                (user.profileImgPath != null && user.profileImgPath!.isNotEmpty);

        if (isProfileComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => EditProfilePage(
              userID: userID,
              fromSplash: true,
            )),
          );
        }
      } else {
        // If no user record found in DB
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo/logo.png', // Your logo path
          height: 150,
        ),
      ),
    );
  }
}

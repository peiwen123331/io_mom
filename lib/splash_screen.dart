import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_home_page.dart';
import 'cc_profile_page.dart';
import 'confinement_center.dart';
import 'confinement_center_home_page.dart';
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
    await Future.delayed(const Duration(seconds: 1)); // Show logo for 3 sec
    final dbService = DatabaseService();
    final prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    String? centerID = prefs.getString('CenterID');
    User? currentUser = FirebaseAuth.instance.currentUser;


    if (userID != null) {
      final user = await dbService.getUserByUID(userID);

      if (user != null) {
        if(user.userRole == 'A' || user.userRole == 'P' || user.userRole == 'FC'){
          //check profile complete or not if not link to edit profile page
          bool isProfileComplete =
              (user.userRole != null && user.userRole!.isNotEmpty)&&
                  (user.userName != null && user.userName!.isNotEmpty) &&
                  (user.phoneNo != null && user.phoneNo!.isNotEmpty) &&
                  (user.profileImgPath != null && user.profileImgPath!.isNotEmpty);

          if (isProfileComplete) {
            if(user.userRole == 'A'){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomePage()),
              );
            }else{
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => EditProfilePage(
                userID: userID,
                from: 'Splash',
              )),
            );
          }
        }else{
          late ConfinementCenter? center;
          if(currentUser!.email != null){
          center = await dbService.getConfinementByEmail(currentUser.email);
          }else{
            print('No center found by email at OTP page');
          }

          print('Center data:');
          print('ContactPersonName: "${center!.ContactPersonName}"');
          print('centerContact: "${center.centerContact}"');
          print('description: "${center.description}"');
          print('centerImgPath: "${center.centerImgPath}"');

          bool isProfileComplete =
              center != null &&
                  (center.centerContact?.trim().isNotEmpty ?? false) &&
                  (center.description?.trim().isNotEmpty ?? false) &&
                  (center.centerImgPath?.trim().isNotEmpty ?? false) &&
                  (center.ContactPersonName.trim().isNotEmpty);

          print('isProfileComplete: $isProfileComplete');

          if (isProfileComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ConfinementCenterHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CcProfilePage(
                centerID: centerID!,
                from: 'Splash',
              )),
            );
          }
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

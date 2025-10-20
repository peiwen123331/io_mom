import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password.dart';
import 'custom_bottom.dart';
import 'custom_drawer.dart';
import 'delete_acc.dart';
import 'edit_profile.dart';
import 'login_page.dart';
import 'user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key

  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
final dbService = DatabaseService();
Future<Users?>? userFuture;
late String userId = "";

//get user by retrieve uid from shared preference
  Future<Users?> getUser() async{
    final prefs = await SharedPreferences.getInstance();
    final String? uid = await prefs.getString("userID");

    //check user id whether is empty or not
    if(uid!.isNotEmpty) {
      userId = uid;
      final users = dbService.getUserByUID(uid);
      return users;
    }
    return null;
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1C2541)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
  @override
  void initState() {
    super.initState();
    userFuture = getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Profile Management",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // --- Profile Image + Name with FutureBuilder ---
            FutureBuilder<Users?>(
              future: getUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return Column(
                    children: const [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: AssetImage('assets/images/profile/profile.png'),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }

                Users user = snapshot.data!;

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: user.profileImgPath != null &&
                          user.profileImgPath!.isNotEmpty
                          ? (user.profileImgPath!.startsWith('assets/')
                          ? AssetImage(user.profileImgPath!) as ImageProvider
                          : FileImage(File(user.profileImgPath!)))
                          : const AssetImage('assets/images/profile/profile.png'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.userName ?? "Unnamed User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // --- General Section ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: const Text(
                      "General",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B7B8B),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.person_outline,
                    title: "Account information",
                    subtitle: "Change your Account information",
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            userID: userId,
                            fromSplash: false,
                          ),
                        ),
                      );

                      if (updated == true) {
                        setState(() {
                          userFuture = getUser(); // refresh the Future
                        }); // Reload UI with updated image
                      }

                    },
                  ),
                  _buildListTile(
                    icon: Icons.lock_outline,
                    title: "Password",
                    subtitle: "Change your Password",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangePasswordPage()
                          ),
                      );
                    },
                  ),
                  _buildListTile(
                    icon: Icons.account_tree_outlined,
                    title: "Linked Account",
                    subtitle: "Add linked account and set access",
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.image_outlined,
                    title: "Milestone Images",
                    subtitle: "Upload your ultrasound image",
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // --- Delete account Section ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                title: const Text(
                  "Delete Account",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // --- Logout Section ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                title: const Text(
                  "Log Out",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();

                  // 🧹 Clear user data
                  await prefs.remove("userID");

                  // 🚪 Sign out from Google if logged in
                  try {
                    final googleSignIn = GoogleSignIn();
                    await googleSignIn.signOut();
                  } catch (e) {
                    debugPrint("Google sign out failed: $e");
                  }

                  // 🔄 Navigate back to login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }
}

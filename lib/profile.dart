import 'dart:io';
import 'package:io_mom/confinement_center.dart';

import 'admin_page_bottom.dart';
import 'admin_page_drawer.dart';
import 'admin_report_page.dart';
import 'cc_page_bottom.dart';
import 'cc_page_drawer.dart';
import 'cc_profile_page.dart';
import 'linked_account_page.dart';
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
import 'ultrasound_img_page.dart';
import 'user.dart';

class ProfilePage extends StatefulWidget {
  final String from;
  const ProfilePage({super.key, required this.from});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final dbService = DatabaseService();

  late Future<Users?> userFuture;
  late Future<ConfinementCenter?> centerFuture;

  late String userId = "";
  late String centerID = "";
  String centerName = "";
  int _selectedIndex = 3;

  // -------------------------
  // LOAD USER
  // -------------------------
  Future<Users?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.from == "Confinement Center") return null;

    String? uid = prefs.getString("userID");

    if (uid != null && uid.isNotEmpty) {
      userId = uid;
      return dbService.getUserByUID(uid);
    }
    return null;
  }

  // -------------------------
  // LOAD CONFINEMENT CENTER
  // -------------------------
  Future<ConfinementCenter?> getCenter() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.from != "Confinement Center") return null;

    String? cid = prefs.getString("CenterID");
    centerID = cid ?? "";

    if (cid != null && cid.isNotEmpty) {
      final center = await dbService.getConfinementByCenterID(cid);
      setState(() {
        centerName = center!.CenterName;
      });
      return center;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    userFuture = getUser();
    centerFuture = getCenter();
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1C2541)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      drawer: widget.from == 'Admin'
          ? AdminPageDrawer(userName: 'Admin')
          : widget.from == 'Confinement Center'
          ? CcPageDrawer(userName: centerName,)
          : CustomDrawer(),

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
          children: [
            const SizedBox(height: 10),

            // =====================================================
            //  PROFILE SECTION (USER vs CONFINEMENT CENTER)
            // =====================================================

            widget.from == "Confinement Center"
                ? _buildCenterProfile()
                : _buildUserProfile(),

            const SizedBox(height: 24),

            _buildGeneralSection(),
            const SizedBox(height: 24),

            widget.from == 'Admin'
                ?  const SizedBox() :
            widget.from == 'Confinement Center' ?
            const SizedBox()
                : _buildDeletePanel(),


            _buildLogoutPanel(),

            const SizedBox(height: 50),
          ],
        ),
      ),

      bottomNavigationBar: widget.from == 'Admin'
          ? AdminPageBottom(currentIndex: 3, onTap: _onItemTapped)
          : widget.from == 'Confinement Center'
          ? CCPageBottom(currentIndex: 3)
          : CustomBottomNav(selectedIndex: 3),
    );
  }

  // --------------------------------------------------
  // USER PROFILE DISPLAY
  // --------------------------------------------------
  Widget _buildUserProfile() {
    return FutureBuilder<Users?>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData) {
          return _defaultProfile("");
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // CENTER PROFILE DISPLAY
  // --------------------------------------------------
  Widget _buildCenterProfile() {
    return FutureBuilder<ConfinementCenter?>(
      future: centerFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snap.hasData) {
          return _defaultProfile("Confinement Center");
        }

        final center = snap.data!;

        return Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: center.centerImgPath != null &&
                  center.centerImgPath!.isNotEmpty
                  ? (center.centerImgPath!.startsWith('assets/')
                  ? AssetImage(center.centerImgPath!) as ImageProvider
                  : FileImage(File(center.centerImgPath!)))
                  : const AssetImage('assets/images/profile/profile.png'),
            ),
            const SizedBox(height: 12),
            Text(
              center.CenterName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        );
      },
    );
  }

  Widget _defaultProfile(String name) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundImage: AssetImage('assets/images/profile/profile.png'),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  // --------------------------------------------------
  // GENERAL SECTION
  // --------------------------------------------------
  Widget _buildGeneralSection() {
    return Container(
      width: double.infinity,
      decoration: _boxDecoration(),
      child: Column(
        children: [
          _sectionHeader("General"),
          const Divider(height: 1),

          //-- Account Info
          _buildListTile(
            icon: Icons.person_outline,
            title: "Account information",
            subtitle: "Change your Account information",
            onTap: () async {
              var updated;

              if (widget.from == 'Admin') {
                updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      userID: userId,
                      from: 'Admin',
                    ),
                  ),
                );
              } else if (widget.from == 'Confinement Center') {
                updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CcProfilePage(
                      centerID: centerID,
                      from: '',
                    ),
                  ),
                );
              } else {
                updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditProfilePage(userID: userId, from: 'User'),
                  ),
                );
              }

              if (updated == true) {
                setState(() {
                  userFuture = getUser();
                  centerFuture = getCenter();
                });
              }
            },
          ),

          //-- Password
          _buildListTile(
            icon: Icons.lock_outline,
            title: "Password",
            subtitle: "Change your Password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChangePasswordPage()),
              );
            },
          ),

          //-- Linked (not Admin)
          if (widget.from != 'Admin' && widget.from != 'Confinement Center')
            _buildListTile(
              icon: Icons.account_tree_outlined,
              title: "Linked Account",
              subtitle: "Add linked account and set access",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          LinkedAccountPage(currentUserID: userId)),
                );
              },
            ),
          if (widget.from == 'Admin')
          _buildListTile(
            icon: Icons.account_tree_outlined,
            title: "Admin Report",
            subtitle: "Generate the report now.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminReportPage()),
              );
            },
          ),

          //-- Ultrasound (not admin/center)
          if (widget.from != 'Admin' && widget.from != 'Confinement Center')
            _buildListTile(
              icon: Icons.image_outlined,
              title: "Dairy Images",
              subtitle: "Upload your dairy image",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UltrasoundImgPage()),
                );
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DELETE ACCOUNT
  // --------------------------------------------------
  Widget _buildDeletePanel() {
    return Container(
      decoration: _boxDecoration(),
      child: ListTile(
        title: const Text("Delete Account",
            style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------
  Widget _buildLogoutPanel() {
    return Container(
      decoration: _boxDecoration(),
      child: ListTile(
        title: const Text("Log Out",
            style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("userID");
          await prefs.remove("CenterID");
          await prefs.remove("loginType");

          try {
            await GoogleSignIn().signOut();
          } catch (_) {}

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF7B7B8B)),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

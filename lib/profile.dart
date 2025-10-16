import 'package:flutter/material.dart';
import 'custom_bottom.dart';
import 'custom_drawer.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFE91E63)),
            onPressed: () {
              // TODO: Navigate to edit profile page
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // --- Profile Image + Name ---
            Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage('assets/profile_sample.png'),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Kelly Yu Wen Wen",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.lock_outline,
                    title: "Password",
                    subtitle: "Change your Password",
                    onTap: () {},
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
                onTap: () {
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

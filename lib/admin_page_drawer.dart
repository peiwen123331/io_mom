import 'package:flutter/material.dart';
import 'package:io_mom/admin_home_page.dart';

import 'admin_collaboration_request_page.dart';
import 'admin_user_page.dart';
import 'profile.dart';

class AdminPageDrawer extends StatelessWidget {
  final String userName;

  const AdminPageDrawer({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
            ),
            child: Text(
              'Hello, $userName',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_)=> AdminHomePage())),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('User Management'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_)=> AdminUserPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Confinement Center Management'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_)=>  AdminCollaborationRequestPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(
                from: 'Admin',
              )));
            },
          ),
        ],
      ),
    );
  }
}

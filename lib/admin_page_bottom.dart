import 'package:flutter/material.dart';
import 'admin_collaboration_request_page.dart';
import 'admin_home_page.dart';
import 'admin_user_page.dart';
import 'profile.dart';

class AdminPageBottom extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminPageBottom({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
      if (index == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminHomePage()));
      } else if (index == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserPage()));
      } else if (index == 2) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCollaborationRequestPage()));
      } else if (index == 3) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(
          from: 'Admin',
        )));
      }
    },
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}

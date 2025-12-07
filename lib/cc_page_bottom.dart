import 'package:flutter/material.dart';

import 'cc_booking_page.dart';
import 'cc_package_page.dart';
import 'confinement_center_home_page.dart';
import 'profile.dart';

class CCPageBottom extends StatelessWidget {
  final int currentIndex;

  const CCPageBottom({
    super.key,
    required this.currentIndex,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return; // Already on this page

    Widget page;

    switch (index) {
      case 0:
        page = ConfinementCenterHomePage();
        break;
      case 1:
        page = CcBookingPage();
        break;
      case 2:
        page = CcPackagePage();
        break;
      case 3:
        page = ProfilePage(from: 'Confinement Center',);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _handleNavigation(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
      ],
    );
  }
}

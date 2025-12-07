import 'package:flutter/material.dart';

import 'cc_booking_page.dart';
import 'cc_package_page.dart';
import 'confinement_center_home_page.dart';
import 'profile.dart';

class CcPageDrawer extends StatefulWidget {
  final String userName;
  const CcPageDrawer({
    super.key,
    required this.userName,
  });

  @override
  State<CcPageDrawer> createState() => _CcPageDrawerState();
}

class _CcPageDrawerState extends State<CcPageDrawer> {

    @override
    Widget build(BuildContext context) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.home, color: Colors.pinkAccent, size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Hi, ${widget.userName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.pink),
              title: const Text('Home'),
              onTap: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (_)=> ConfinementCenterHomePage()
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.pink),
              title: const Text('Bookings Management'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_)=> CcBookingPage()
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.pink),
              title: const Text('Packages Management'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_)=> CcPackagePage()
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.pink),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_)=> ProfilePage(from: 'Confinement Center',)
                ));
              },
            ),
          ],
        ),
      );
    }
}





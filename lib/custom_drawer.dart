import 'package:flutter/material.dart';
import 'package:io_mom/calendar_page.dart';
import 'package:io_mom/confinement_center_page.dart';
import 'article_page.dart';
import 'chat_room_list.dart';
import 'chatbot.dart';
import 'health_trend.dart';
import 'profile.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.pink),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety),
            title: const Text('Health Trend'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HealthTrendPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_alarm),
            title: const Text('Reminder'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarPage(isFrom: '')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.adb),
            title: const Text('Gemini Chatbot'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GeminiChatbotPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Article'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticlesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Confinement Center'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfinementCenterPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat Room'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage(
                  from: 'User',
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'article_page.dart';
import 'ble_health_monitor_page.dart';
import 'calendar_page.dart';
import 'chat_room_list.dart';
import 'chatbot.dart';
import 'confinement_center_page.dart';
import 'custom_bottom.dart';
import 'profile.dart';
import 'custom_drawer.dart';
import 'user.dart';
import 'database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dbService = DatabaseService();

  // ✅ Fetch user data once using shared preferences
  Future<Users?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString("userID");
    if (uid != null && uid.isNotEmpty) {
      return dbService.getUserByUID(uid);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // ✅ FutureBuilder for profile avatar
          FutureBuilder<Users?>(
            future: getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 16,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                // no user data yet
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage(
                          from: 'User',
                        )),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.pink,
                      radius: 16,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
                );
              }

              final user = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage(
                        from: 'User',
                      )),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: user.profileImgPath != null &&
                        user.profileImgPath!.isNotEmpty
                        ? (user.profileImgPath!.startsWith('assets/')
                        ? AssetImage(user.profileImgPath!)
                    as ImageProvider
                        : FileImage(File(user.profileImgPath!)))
                        : const AssetImage('assets/images/profile/profile.png'),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ✅ Entire body uses FutureBuilder so you can show username
      body: FutureBuilder<Users?>(
        future: getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final username = user?.userName ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $username 👋",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                const Text(
                  "16th Week of Pregnancy",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // --- Pregnancy Summary Card ---
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              backgroundColor: Color(0xFFFDE2E2),
                              child: Icon(Icons.favorite, color: Colors.pink),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your baby is the size of a pear",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _StatColumn(title: "Baby Height", value: "17 cm"),
                            _StatColumn(title: "Baby Weight", value: "110 gr"),
                            _StatColumn(title: "Days Left", value: "168 days"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Feature Grid ---
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _FeatureCard(
                      icon: Icons.chat,
                      title: "Chat Room",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatListPage()),
                        );
                      },
                    ),
                    _FeatureCard(
                      icon: Icons.alarm,
                      title: "Reminder",
                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CalendarPage(isFrom: '',)),
                        );

                        /*Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BleHealthMonitor()),
                        );*/
                      },
                    ),
                    _FeatureCard(
                      icon: Icons.mood,
                      title: "Mood",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CalendarPage(
                            isFrom: 'Mood'
                          )),
                        );
                      },
                    ),
                    _FeatureCard(
                      icon: Icons.smart_toy,
                      title: "AI Chatbot",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GeminiChatbotPage()),
                        );
                      },
                    ),
                    _FeatureCard(
                      icon: Icons.article,
                      title: "Articles",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ArticlesPage()),
                        );
                      },
                    ),
                    _FeatureCard(
                      icon: Icons.local_hospital,
                      title: "Confinement\n     Center",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConfinementCenterPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;
  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.pink, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}


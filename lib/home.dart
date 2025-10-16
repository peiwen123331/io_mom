import 'package:flutter/material.dart';
import 'custom_bottom.dart';
import 'profile.dart';
import 'custom_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: const CircleAvatar(
                backgroundImage: AssetImage("assets/profile.jpg"), // replace with user avatar
                radius: 16,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hello Kelly",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
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
              children: const [
                _FeatureCard(icon: Icons.chat, title: "Chat Room"),
                _FeatureCard(icon: Icons.alarm, title: "Reminder"),
                _FeatureCard(icon: Icons.mood, title: "Mood"),
                _FeatureCard(icon: Icons.smart_toy, title: "AI Chatbot"),
                _FeatureCard(icon: Icons.article, title: "Articles"),
                _FeatureCard(icon: Icons.local_hospital, title: "Confinement Center"),
              ],
            ),
          ],
        ),
      ),

      // ✅ Reusable bottom navigation
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
  const _FeatureCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: navigate to feature page
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.pink, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

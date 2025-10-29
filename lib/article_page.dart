import 'package:flutter/material.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  // Sample data — you can replace with Firestore or API later
  final List<Map<String, String>> articles = [
    {
      "title": "Pregnancy yoga",
      "description":
      "Pregnancy Yoga helps alleviate the effect of common symptoms such as morning sickness, painful leg cramps, swollen ankles, and constipation.",
      "image":
      "https://images.pexels.com/photos/3961331/pexels-photo-3961331.jpeg"
    },
    {
      "title": "Healthy eating during pregnancy",
      "description":
      "Maintaining a balanced diet ensures your baby gets the right nutrients for growth and development throughout pregnancy.",
      "image":
      "https://images.pexels.com/photos/3872373/pexels-photo-3872373.jpeg"
    },
    {
      "title": "Safe exercises for expecting mothers",
      "description":
      "Gentle exercises like walking, swimming, and stretching can help improve circulation and reduce discomfort during pregnancy.",
      "image":
      "https://images.pexels.com/photos/618923/pexels-photo-618923.jpeg"
    },
  ];

  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
    // TODO: Navigate to other pages based on index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Articles",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      article["image"]!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(article["title"]!,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          article["description"]!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "SAVE FOR LATER",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black54,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.pregnant_woman), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: ""),
        ],
      ),
    );
  }
}

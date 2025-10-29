import 'package:flutter/material.dart';

class ConfinementCenterPage extends StatefulWidget {
  const ConfinementCenterPage({Key? key}) : super(key: key);

  @override
  State<ConfinementCenterPage> createState() => _ConfinementCenterPageState();
}

class _ConfinementCenterPageState extends State<ConfinementCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';

  final List<Map<String, String>> centers = [
    {
      'name': 'Gloria Confinement Centre',
      'address': '133, Jln Macalister, 10400 George Town, Pulau Pinang',
      'image': 'assets/images/gloria.jpg',
    },
    {
      'name': 'Codrington Postnatal Retreat',
      'address': '26P, Lebuh Codrington, Pulau Tikus, 10350 George Town, Pulau Pinang',
      'image': 'assets/images/codrington.jpg',
    },
    {
      'name': 'Spink Confinement & Baby Care',
      'address': '68, Lebuhraya Codrington, Pulau Tikus, 10350 George Town, Pulau Pinang',
      'image': 'assets/images/spink.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCenters = centers
        .where((center) =>
        center['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Confinement Center",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              margin: const EdgeInsets.only(bottom: 12, top: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),

            // 📋 List of Centers
            Expanded(
              child: ListView.builder(
                itemCount: filteredCenters.length,
                itemBuilder: (context, index) {
                  final center = filteredCenters[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap: () {
                        // navigate to details page if needed
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // 🖼 Background Image
                            Image.asset(
                              center['image']!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),

                            // 🖋 Overlay (Text)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      center['name']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      center['address']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

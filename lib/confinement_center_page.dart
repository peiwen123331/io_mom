import 'dart:io';

import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'booking_history.dart';
import 'confinement_center.dart';
import 'package_detail_page.dart';
import 'home.dart';

class ConfinementCenterPage extends StatefulWidget {
  const ConfinementCenterPage({super.key});

  @override
  State<ConfinementCenterPage> createState() => _ConfinementCenterPageState();
}

class _ConfinementCenterPageState extends State<ConfinementCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  final dbService = DatabaseService();

  List<ConfinementCenter> centers = [];
  List<ConfinementCenter> filteredCenters = [];
  bool isLoading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final data = await dbService.getAllCenter();
      setState(() {
        centers = data!;
        filteredCenters = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading centers: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchCenters(String value) {
    setState(() {
      query = value;
      filteredCenters = centers
          .where((center) =>
          center.CenterName!.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_)=>HomePage())),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            tooltip: 'View Booking History',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_)=> BookingHistoryPage()
              ));
            },
          ),
        ],
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
                onChanged: _searchCenters,
              ),
            ),

            // 📋 Loading or List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                  : filteredCenters.isEmpty
                  ? const Center(child: Text("No centers found."))
                  : ListView.builder(
                itemCount: filteredCenters.length,
                itemBuilder: (context, index) {
                  final center = filteredCenters[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageDetailPage(
                              CenterID: center.CenterID!,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            buildCenterImage(center.centerImgPath),
                            // 🖋 Overlay Text
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      center.CenterName ?? "Unnamed Center",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      center.location ?? "Location not available",
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

  Widget buildCenterImage(String? path) {
    if (path == null || path.isEmpty) {
      return Image.asset(
        "assets/images/confinement_center/CC0001.jpg",
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
      );
    }

    // Asset image (like assets/images/xxx)
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            "assets/images/confinement_center/CC0001.jpg",
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          );
        },
      );
    }

    // File image
    final file = File(path);
    if (!file.existsSync()) {
      return Image.asset(
        "assets/images/confinement_center/CC0001.jpg",
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      file,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          "assets/images/confinement_center/CC0001.jpg",
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
        );
      },
    );
  }

}

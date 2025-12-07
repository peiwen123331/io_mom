import 'dart:io';

import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/package.dart';
import 'package:io_mom/smtp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cc_package_detail_page.dart';
import 'cc_page_bottom.dart';
import 'cc_page_drawer.dart';
import 'package_images.dart';

class CcPackagePage extends StatefulWidget {
  const CcPackagePage({super.key});

  @override
  State<CcPackagePage> createState() => _CcPackagePageState();
}

class _CcPackagePageState extends State<CcPackagePage> {
  int _selectedIndex = 2;

  late Future<List<Package>?> _packageFuture;
  String centerID = "";
  String centerName = "";

  // Search state
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Package> allPackages = [];
  final dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    loadCenterID();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
  }

  Future<void> loadCenterID() async {
    final prefs = await SharedPreferences.getInstance();
    centerID = prefs.getString("CenterID") ?? "";
    final center = await dbService.getConfinementByCenterID(centerID);
    setState(() {
      centerName = center!.CenterName;
    });
    if (centerID.isNotEmpty) {
      setState(() {
        _packageFuture = _loadPackages();
      });
    }
  }

  Future<List<Package>?> _loadPackages() async {
    final packages = await dbService.getPackageByCenterID(centerID);
    setState(() {
      allPackages = packages ?? [];
    });
    return packages;
  }

  List<Package> getFilteredPackages() {
    if (searchQuery.isEmpty) {
      return allPackages;
    }

    return allPackages.where((pkg) {
      final packageName = pkg.packageName.toLowerCase();
      final price = pkg.price.toString();

      return packageName.contains(searchQuery) || price.contains(searchQuery);
    }).toList();
  }

  /// Load image list for each PackageID separately
  Future<String?> _loadImageForPackage(String packageID) async {
    final images = await dbService.getPackageImagesByPackageID(packageID);

    if (images != null && images.isNotEmpty) {
      return images.first.packageImgPath; // first image only
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CcPageDrawer(userName: centerName),
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Package Management",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CCPackageDetailPage(
                    packageID: "",
                    from: "Add",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: centerID.isEmpty
          ? const Center(
        child: Text("CenterID not found"),
      )
          : FutureBuilder(
        future: _packageFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          final packages = snapshot.data as List<Package>?;

          if (packages == null || packages.isEmpty) {
            return const Center(
              child: Text(
                "No package found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final filteredPackages = getFilteredPackages();

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by package name or price',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.pink),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.pink, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Package List
              Expanded(
                child: filteredPackages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No packages found matching '$searchQuery'",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Search'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = filteredPackages[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CCPackageDetailPage(
                              packageID: pkg.PackageID,
                              from: 'Edit',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Load package image for each item
                              FutureBuilder(
                                future: _loadImageForPackage(pkg.PackageID),
                                builder: (context, snapshot) {
                                  String? imgPath = snapshot.data;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: 200,
                                    child: imgPath != null
                                        ? imgPath.contains('assets/images')
                                        ? Image.asset(
                                      imgPath,
                                      fit: BoxFit.cover,
                                    )
                                        : File(imgPath).existsSync()
                                        ? Image.file(
                                      File(imgPath),
                                      fit: BoxFit.cover,
                                    )
                                        : Image.asset(
                                      "assets/images/confinement_center/CC0002.jpg",
                                      fit: BoxFit.cover,
                                    )
                                        : Image.asset(
                                      "assets/images/confinement_center/CC0002.jpg",
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),

                              // black gradient overlay
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.black.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),

                              // Availability Badge
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: pkg.availability == 0
                                        ? Colors.red
                                        : pkg.availability <= 5
                                        ? Colors.orange
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        pkg.availability == 0
                                            ? Icons.warning_amber
                                            : pkg.availability <= 5
                                            ? Icons.info_outline
                                            : Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        pkg.availability == 0
                                            ? 'Out of Stock'
                                            : pkg.availability <= 5
                                            ? 'Low Stock'
                                            : 'Available',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // package info
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  width: 260,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pkg.packageName,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "RM ${pkg.price.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  "Availability: ${pkg.availability}",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: pkg.availability == 0
                                                        ? Colors.red
                                                        : pkg.availability <= 5
                                                        ? Colors.orange
                                                        : Colors.black87,
                                                    fontWeight:
                                                    pkg.availability <= 5
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // edit icon
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CCPackageDetailPage(
                                                    packageID: pkg.PackageID,
                                                    from: 'Edit',
                                                  ),
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.pink,
                                          size: 22,
                                        ),
                                      )
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
          );
        },
      ),
      bottomNavigationBar: CCPageBottom(
        currentIndex: _selectedIndex,
      ),
    );
  }
}
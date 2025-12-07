import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/confinement_booking.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/package.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import
import 'package:geocoding/geocoding.dart';

class PackageDetailPage extends StatefulWidget {
  final String CenterID;

  const PackageDetailPage({super.key, required this.CenterID});

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  final dbService = DatabaseService();

  int currentIndex = 0;
  String selectedPackage = "Normal";
  DateTime? selectedDate;

  bool isLoading = true;
  List<Package> packages = [];
  List<String> images = [];
  List<String> packageList = [];

  // Add these variables to store center location
  String? centerAddress;
  double? centerLatitude;
  double? centerLongitude;


  @override
  void initState() {
    super.initState();
    _loadPackages();
    _loadCenterLocation(); // Load center location
  }

  Future<void> _loadCenterLocation() async {
    final center = await dbService.getConfinementByCenterID(widget.CenterID);

    if (center == null) {
      print("Center not found.");
      return;
    }

    String address = center.location;
    print("Center address:                $address");

    double? lat;
    double? lng;
    String fullAddress = "${center.location}, Malaysia"; // append country
    print("Center address:               $fullAddress");
    try {
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        lat = locations.first.latitude;
        lng = locations.first.longitude;
        print("Geocoded lat: $lat, lng: $lng");
      } else {
        print("No coordinates returned.");
      }
    } catch (e) {
      print("Geocoding failed: $e");
    }


    setState(() {
      centerAddress = address;
      centerLatitude = lat;
      centerLongitude = lng;
    });
  }
  void _openGoogleMaps(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print("Could not open Google Maps URL.");
    }
  }



  // Open navigation app
  Future<void> _openNavigation() async {
    if (centerLatitude == null || centerLongitude == null) {
      _showAlert("Navigation Error", "Location coordinates not available.");
      return;
    }

    _openGoogleMaps(centerLatitude!, centerLongitude!);
    // Try Google Maps first, then Apple Maps (iOS), then browser
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$centerLatitude,$centerLongitude');

    final appleMapsUrl = Uri.parse(
        'https://maps.apple.com/?daddr=$centerLatitude,$centerLongitude');

    try {
      // Try Google Maps app first
      final gmapsAppUrl = Uri.parse(
          'comgooglemaps://?daddr=$centerLatitude,$centerLongitude&directionsmode=driving');

      if (await canLaunchUrl(gmapsAppUrl)) {
        await launchUrl(gmapsAppUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        _showAlert("Error", "Could not open maps application.");
      }
    } catch (e) {
      _showAlert("Error", "Failed to open navigation: $e");
    }
  }

  // Load packages by CenterID
  Future<void> _loadPackages() async {
    final pkgResult = await dbService.getPackageByCenterID(widget.CenterID);

    if (pkgResult == null || pkgResult.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    packages = pkgResult;
    packageList.clear();

    for (var p in packages) {
      packageList.add(p.packageName);
    }

    if (packageList.isNotEmpty) {
      selectedPackage = packageList.first;
    }

    await _loadImagesForSelectedPackage();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadImagesForSelectedPackage() async {
    final selected = packages.firstWhere(
          (p) => p.packageName.toLowerCase() == selectedPackage.toLowerCase(),
      orElse: () => Package.empty(),
    );

    if (selected.PackageID.isEmpty) {
      images = [];
      return;
    }

    final imgList =
    await dbService.getPackageImagesByPackageID(selected.PackageID);

    if (imgList != null) {
      images = imgList.map((e) => e.packageImgPath).toList();
    } else {
      images = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = packages.firstWhere(
          (p) => p.packageName.toLowerCase() == selectedPackage.toLowerCase(),
      orElse: () => packages.isNotEmpty ? packages.first : Package.empty(),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Package",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // Add navigation button to app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.pinkAccent),
            onPressed: _openNavigation,
            tooltip: "Navigate to Center",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent))
          : packages.isEmpty
          ? const Center(child: Text("No packages found."))
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: images.isEmpty ? 1 : images.length,
                    onPageChanged: (index) =>
                        setState(() => currentIndex = index),
                    itemBuilder: (context, index) {
                      final img = images.isNotEmpty
                          ? images[index]
                          : "https://via.placeholder.com/500x300?text=No+Image";

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: images[index].startsWith("assets/")
                            ? Image.asset(
                          images[index],
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                            : Image.file(File(images[index])),
                      );
                    },
                  ),
                  if (images.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      child: Row(
                        children: List.generate(
                          images.length,
                              (index) => Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: currentIndex == index ? 10 : 6,
                            height: currentIndex == index ? 10 : 6,
                            decoration: BoxDecoration(
                              color: currentIndex == index
                                  ? Colors.pinkAccent
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address with Navigation Button
            if (centerAddress != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.pinkAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.pinkAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        centerAddress!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.directions,
                          color: Colors.pinkAccent),
                      onPressed: _openNavigation,
                      tooltip: "Get Directions",
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            Text(
              "Package: ${selected.duration} Days",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Package Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: packageList.map((type) {
                final pkg = packages.firstWhere(
                      (p) =>
                  p.packageName.toLowerCase() ==
                      type.toLowerCase(),
                  orElse: () => Package.empty(),
                );

                final isSelected = selectedPackage == type;
                final isAvailable = pkg.availability != 0;

                return Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.pinkAccent.withOpacity(0.1)
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.pinkAccent
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isAvailable
                          ? () async {
                        setState(() {
                          selectedPackage = type;
                          isLoading = true;
                        });

                        await _loadImagesForSelectedPackage();

                        setState(() => isLoading = false);
                      }
                          : null,
                      child: Column(
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 11,
                              color: isAvailable
                                  ? (isSelected
                                  ? Colors.pinkAccent
                                  : Colors.black)
                                  : Colors.grey,
                            ),
                          ),
                          if (!isAvailable)
                            const Text(
                              "Unavailable",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Date Picker
            const Text("Check In Date:",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),

            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );

                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate != null
                          ? DateFormat('EEEE, d MMMM yyyy')
                          .format(selectedDate!)
                          : "Select a date",
                    ),
                    const Icon(Icons.calendar_month,
                        color: Colors.pinkAccent),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Package Name & Price
            Text(
              selected.packageName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "RM ${selected.price.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),

            const SizedBox(height: 20),

            // Description
            const Text("Package Details",
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),

            Text(
              selected.description,
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),

            const SizedBox(height: 30),

            // Booking Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (selectedDate == null) {
                    _showDateAlert();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        checkInDate: selectedDate,
                        PackageID: selected.PackageID,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select a Date"),
        content:
        const Text("Please choose your check-in date before continuing."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("OK", style: TextStyle(color: Colors.pinkAccent)),
          )
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("OK", style: TextStyle(color: Colors.pinkAccent)),
          )
        ],
      ),
    );
  }
}
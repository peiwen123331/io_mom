import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  LatLng? userLocation;
  List<Map<String, dynamic>> hospitals = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location service disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<Map<String, dynamic>>> getNearbyHospitals(
      double lat, double lon) async {
    const radius = 10000; //10km radius

    // List of Overpass API servers to try
    final servers = [
      "https://overpass.kumi.systems/api/interpreter",
      "https://overpass-api.de/api/interpreter",
      "https://overpass.openstreetmap.ru/api/interpreter",
    ];

    final query = """
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:$radius,$lat,$lon);
  way["amenity"="hospital"](around:$radius,$lat,$lon);
  relation["amenity"="hospital"](around:$radius,$lat,$lon);
);
out center tags;
""";

    // Try each server with retries
    for (int serverIndex = 0; serverIndex < servers.length; serverIndex++) {
      final server = servers[serverIndex];
      debugPrint("🔍 Trying server ${serverIndex + 1}/${servers.length}: $server");

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http.post(
            Uri.parse(server),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'data': query},
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception("Request timeout after 30 seconds");
            },
          );

          debugPrint("Response status: ${response.statusCode} (Server $serverIndex, Attempt $attempt)");

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List elements = data["elements"] ?? [];

            if (elements.isEmpty) {
              debugPrint("⚠️ No hospitals found within $radius meters");
              return [];
            }

            debugPrint("✅ Found ${elements.length} hospitals");

            return elements.map((e) {
              final center = e["center"] ?? {"lat": e["lat"], "lon": e["lon"]};
              final tags = e["tags"] ?? {};

              // Build address from available tags
              String address = _buildAddress(tags);

              return {
                "name": tags["name"] ?? "Unnamed Hospital",
                "lat": center["lat"] ?? 0.0,
                "lon": center["lon"] ?? 0.0,
                "address": address,
                "phone": tags["phone"] ?? tags["contact:phone"] ?? "",
              };
            }).toList();
          } else if (response.statusCode == 504 || response.statusCode == 429) {
            debugPrint("⚠️ Server busy (${response.statusCode}), trying next...");
            await Future.delayed(Duration(seconds: attempt));
            continue;
          } else {
            debugPrint("❌ API Error: ${response.statusCode}");
            throw Exception("API returned ${response.statusCode}");
          }
        } catch (e) {
          debugPrint("❌ Attempt $attempt failed: $e");
          if (attempt == 2 && serverIndex == servers.length - 1) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    throw Exception("All servers failed to respond");
  }

  String _buildAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];

    if (tags["addr:housenumber"] != null) {
      addressParts.add(tags["addr:housenumber"]);
    }
    if (tags["addr:street"] != null) {
      addressParts.add(tags["addr:street"]);
    }
    if (tags["addr:city"] != null) {
      addressParts.add(tags["addr:city"]);
    }
    if (tags["addr:postcode"] != null) {
      addressParts.add(tags["addr:postcode"]);
    }
    if (tags["addr:state"] != null) {
      addressParts.add(tags["addr:state"]);
    }

    return addressParts.isNotEmpty ? addressParts.join(", ") : "Address not available";
  }

  // Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  // Estimate travel time (assuming average speed of 40 km/h in city)
  int estimateTravelTime(double distanceKm) {
    const averageSpeed = 40.0; // km/h
    return ((distanceKm / averageSpeed) * 60).round(); // Convert to minutes
  }

  // Open navigation in Google Maps
  Future<void> openNavigation(double destLat, double destLng) async {
    if (userLocation == null) return;

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${userLocation!.latitude},${userLocation!.longitude}&destination=$destLat,$destLng&travelmode=driving'
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      debugPrint("❌ Navigation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open navigation")),
        );
      }
    }
  }

  // Make phone call
  Future<void> makePhoneCall(String phoneNumber) async {
    // Clean phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final url = Uri.parse('tel:$cleanNumber');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      debugPrint("❌ Phone call error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open phone dialer")),
        );
      }
    }
  }

  // Copy phone number to clipboard
  void copyPhoneNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Phone number copied: $phoneNumber"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Show hospital details dialog
  void showHospitalDialog(Map<String, dynamic> hospital) {
    if (userLocation == null) return;

    final distance = calculateDistance(
      userLocation!.latitude,
      userLocation!.longitude,
      hospital["lat"],
      hospital["lon"],
    );

    final travelTime = estimateTravelTime(distance);
    final hasPhone = hospital["phone"].toString().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hospital["name"],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                  Icons.location_on,
                  "Distance",
                  "${distance.toStringAsFixed(2)} km"
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.access_time,
                  "Est. Time",
                  "$travelTime minutes"
              ),
              const SizedBox(height: 12),
              _buildInfoSection(
                  Icons.home,
                  "Address",
                  hospital["address"]
              ),
              if (hasPhone) ...[
                const SizedBox(height: 12),
                _buildPhoneSection(hospital["phone"]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          if (hasPhone)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                makePhoneCall(hospital["phone"]);
              },
              icon: const Icon(Icons.phone),
              label: const Text("Call"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              openNavigation(hospital["lat"], hospital["lon"]);
            },
            icon: const Icon(Icons.navigation),
            label: const Text("Navigate"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            value,
            style: TextStyle(
              color: value.contains("not available") ? Colors.orange : Colors.grey[700],
              fontStyle: value.contains("not available") ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection(String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              "Phone:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  phone,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy, size: 18),
                onPressed: () => copyPhoneNumber(phone),
                tooltip: "Copy phone number",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> loadData() async {
    try {
      final pos = await getUserLocation();
      final result = await getNearbyHospitals(pos.latitude, pos.longitude);

      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
        hospitals = result;
      });
    } catch (e) {
      debugPrint("❌ Failed to load data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load hospitals: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Nearest Hospitals"),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text("Loading hospitals nearby..."),
              const SizedBox(height: 10),
              Text(
                "This may take a moment",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearest Hospitals"),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userLocation!,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "my.edu.tarumt.io_mom",
              ),

              /// User location marker
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: userLocation!,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),
                ],
              ),

              /// Hospital markers
              MarkerLayer(
                markers: hospitals.map((h) {
                  return Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(h["lat"], h["lon"]),
                    child: GestureDetector(
                      onTap: () => showHospitalDialog(h),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.red,
                        size: 35,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Hospital count badge
          if (hospitals.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    const Icon(Icons.local_hospital, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "${hospitals.length} ${hospitals.length == 1 ? 'Hospital' : 'Hospitals'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
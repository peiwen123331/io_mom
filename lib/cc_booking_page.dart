import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking.dart';
import 'cc_booking_detail_page.dart';
import 'database.dart';
import 'cc_page_bottom.dart';
import 'cc_page_drawer.dart';
import 'package.dart';
import 'user.dart';

class CcBookingPage extends StatefulWidget {
  const CcBookingPage({super.key});

  @override
  State<CcBookingPage> createState() => _CcBookingPageState();
}

class _CcBookingPageState extends State<CcBookingPage> {
  late Future<List<Map<String, dynamic>>> bookingDataFuture = Future.value([]);
  final dbService = DatabaseService();
  String centerName = '';

  // Filter state
  String selectedFilter = 'all'; // 'all', 'upcoming', 'ongoing', 'completed'
  List<Map<String, dynamic>> allBookings = [];

  // Search state
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    bookingDataFuture = loadBookingData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> loadBookingData() async {
    List<Map<String, dynamic>> result = [];
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('CenterID');
    final center = await dbService.getConfinementByCenterID(cid!);
    final bookings = await dbService.getBookingsByCenterID(cid);

    setState(() {
      centerName = center!.CenterName;
    });

    for (var booking in bookings) {
      Users? user = await dbService.getUserByUID(booking.userID);
      Package? package = await dbService.getPackageByPackageID(booking.PackageID);
      var images = await dbService.getPackageImagesByPackageID(booking.PackageID);

      String imagePath = (images != null && images.isNotEmpty)
          ? images.first.packageImgPath
          : "assets/images/confinement_center/CC0002.png";

      // Determine booking status
      String status = getBookingStatus(booking);

      result.add({
        "title": package?.packageName ?? "No Package Name",
        "bookingId": booking.BookingID,
        "name": user?.userName ?? user?.userEmail,
        "price": "RM ${calculateCenterAmount(booking.payAmount).toStringAsFixed(2)}",
        "image": imagePath,
        "status": status,
        "checkInDate": booking.checkInDate,
        "checkOutStatus": booking.checkOutStatus,
      });
    }

    setState(() {
      allBookings = result;
    });

    return result;
  }

  String getBookingStatus(Booking booking) {
    final today = DateTime.now();
    final checkInDate = booking.checkInDate;

    if (booking.checkOutStatus == 'T') {
      return 'completed';
    } else if (booking.checkOutStatus == 'F' && checkInDate.isBefore(today)) {
      return 'ongoing';
    } else {
      return 'upcoming';
    }
  }

  List<Map<String, dynamic>> getFilteredBookings() {
    List<Map<String, dynamic>> filtered = allBookings;

    // Apply status filter
    if (selectedFilter != 'all') {
      filtered = filtered.where((b) => b['status'] == selectedFilter).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final packageName = b['title'].toString().toLowerCase();
        final bookingId = b['bookingId'].toString().toLowerCase();
        final userName = b['name'].toString().toLowerCase();

        return packageName.contains(searchQuery) ||
            bookingId.contains(searchQuery) ||
            userName.contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  int getStatusCount(String status) {
    if (status == 'all') return allBookings.length;
    return allBookings.where((b) => b['status'] == status).length;
  }

  double calculateCenterAmount(double payAmount) {
    return payAmount / 1.06;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CcPageDrawer(userName: centerName),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Booking Management",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: bookingDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allBookings.isEmpty) {
            return const Center(child: Text("No booking records found"));
          }

          final filteredBookings = getFilteredBookings();

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by package name, booking ID, or user name',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.pink),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          searchQuery = '';
                        });
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

              // Filter Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton(
                        'All',
                        'all',
                        Icons.list,
                        getStatusCount('all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        'Upcoming',
                        'upcoming',
                        Icons.schedule,
                        getStatusCount('upcoming'),
                        showAlert: getStatusCount('upcoming') > 0,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        'Ongoing',
                        'ongoing',
                        Icons.home,
                        getStatusCount('ongoing'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        'Completed',
                        'completed',
                        Icons.check_circle,
                        getStatusCount('completed'),
                      ),
                    ],
                  ),
                ),
              ),

              // Booking List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty
                            ? "No bookings found matching '$searchQuery'"
                            : "No ${selectedFilter == 'all' ? '' : selectedFilter} bookings",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Search'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.pink,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final b = filteredBookings[index];
                    return _buildBookingCard(b);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CCPageBottom(currentIndex: 1),
    );
  }

  Widget _buildFilterButton(
      String label,
      String filterValue,
      IconData icon,
      int count, {
        bool showAlert = false,
      }) {
    final isSelected = selectedFilter == filterValue;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedFilter = filterValue;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.pink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.pink : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showAlert)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    String statusLabel = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    switch (b['status']) {
      case 'upcoming':
        statusLabel = 'Upcoming - Prepare Room!';
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
        break;
      case 'ongoing':
        statusLabel = 'Guest Checked In';
        statusColor = Colors.green;
        statusIcon = Icons.home;
        break;
      case 'completed':
        statusLabel = 'Completed';
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CcBookingDetailPage(bookingID: b['bookingId']),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              loadImage(b["image"]),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // Status Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
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
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
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

              Positioned(
                left: 15,
                bottom: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["title"],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "#${b["bookingId"]}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        b["name"],
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Paid ${b["price"]}",
                        style: const TextStyle(fontSize: 13),
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
  }

  Widget loadImage(String path) {
    bool isAsset = path.startsWith("assets/");
    bool isLocalFile = path.contains("/storage/") ||
        path.contains("/data/user/") ||
        File(path).existsSync();

    if (isAsset) {
      return Image.asset(
        path,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/images/confinement_center/CC0001.png",
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    if (isLocalFile) {
      return Image.file(
        File(path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/images/confinement_center/CC0002.png",
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      "assets/images/confinement_center/CC0002.png",
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
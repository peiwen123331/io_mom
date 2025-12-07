import 'package:flutter/material.dart';
import 'package:io_mom/confinement_center.dart';
import 'package:io_mom/database.dart';
import 'admin_request_history.dart';
import 'cc_profile_page.dart';
import 'collaboration_request.dart';
import 'admin_page_bottom.dart';
import 'admin_page_drawer.dart';
import 'admin_collaboration_details_page.dart';

class AdminCollaborationRequestPage extends StatefulWidget {
  const AdminCollaborationRequestPage({super.key});

  @override
  State<AdminCollaborationRequestPage> createState() =>
      _AdminCollaborationRequestPageState();
}

class _AdminCollaborationRequestPageState extends State<AdminCollaborationRequestPage> {
  String selectedTab = "Center";
  final TextEditingController _searchController = TextEditingController();

  final dbService = DatabaseService();

  List<ConfinementCenter> allCenters = [];
  List<ConfinementCenter> filteredCenters = [];

  List<CollaborationRequest> allRequests = [];
  List<CollaborationRequest> filteredRequests = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllCenterAndRequest();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getAllCenterAndRequest() async {
    setState(() => isLoading = true);

    try {
      var centers = await dbService.getAllCenter();
      var requests = await dbService.getAllRequest();

      setState(() {
        allCenters = centers;
        filteredCenters = centers;
        allRequests = requests;
        filteredRequests = requests;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading data: $e');
    }
  }

  void _filterData() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        // Reset to all data
        filteredCenters = allCenters;
        filteredRequests = allRequests;
      } else {
        if (selectedTab == "Center") {
          // Filter centers by: centerID, centerName, centerEmail
          filteredCenters = allCenters.where((center) {
            String id = (center.CenterID ?? '').toLowerCase();
            String name = (center.CenterName ?? '').toLowerCase();
            String email = (center.centerEmail ?? '').toLowerCase();

            return id.contains(query) ||
                name.contains(query) ||
                email.contains(query);
          }).toList();
        } else {
          // Filter requests by: requestID, centerEmail
          filteredRequests = allRequests.where((request) {
            String id = (request.RequestID ?? '').toLowerCase();
            String email = (request.centerEmail ?? '').toLowerCase();

            return id.contains(query) || email.contains(query);
          }).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminPageDrawer(userName: 'Admin'),
      appBar: AppBar(
        title: const Text("Confinement Center"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            tooltip: 'View Request History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminRequestHistory()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // TAB BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Center"),
              const SizedBox(width: 10),
              _buildTabButton("Request"),
            ],
          ),

          const SizedBox(height: 15),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: selectedTab == "Center"
                    ? 'Search by ID, name, or email'
                    : 'Search by request ID or email',
                prefixIcon: const Icon(Icons.search, color: Colors.pink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedTab == "Center"
                ? _buildApprovedCenters()
                : _buildRequestList(),
          ),
        ],
      ),
      bottomNavigationBar: AdminPageBottom(currentIndex: 2, onTap: (_) {}),
    );
  }

  // ---------------------
  // TAB BUTTON
  // ---------------------
  Widget _buildTabButton(String title) {
    bool isSelected = selectedTab == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
          _searchController.clear(); // Clear search when switching tabs
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------------------
  // APPROVED CENTER LIST
  // ---------------------
  Widget _buildApprovedCenters() {
    if (filteredCenters.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "No centers data found"
              : "No centers match your search",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCenters.length,
      itemBuilder: (context, i) {
        final c = filteredCenters[i];
        return _buildCenterTile(
          title: c.CenterName,
          address: c.location,
          requestID: c.CenterID,
          email: c.centerEmail,
          from: 'Center',
        );
      },
    );
  }

  // ---------------------
  // COLLABORATION REQUEST LIST
  // ---------------------
  Widget _buildRequestList() {
    if (filteredRequests.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "No collaboration requests found"
              : "No requests match your search",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, i) {
        final r = filteredRequests[i];
        return _buildCenterTile(
          title: r.centerName,
          address: r.location,
          requestID: r.RequestID,
          email: r.centerEmail,
          from: 'Request',
        );
      },
    );
  }

  // ---------------------
  // DISPLAY TILE
  // ---------------------
  Widget _buildCenterTile({
    required String title,
    required String address,
    required String requestID,
    String? email,
    required String from,
  }) {
    return GestureDetector(
      onTap: () {
        if (from == 'Center') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CcProfilePage(
                centerID: requestID,
                from: 'Admin',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminCollaborationDetailsPage(requestID: requestID),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.home_repair_service, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    address,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  if (email != null && email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 18),
          ],
        ),
      ),
    );
  }
}
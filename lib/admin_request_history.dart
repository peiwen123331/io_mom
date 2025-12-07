import 'package:flutter/material.dart';

import 'admin_collaboration_details_page.dart';
import 'admin_collaboration_request_page.dart';
import 'collaboration_request.dart';
import 'database.dart';

class AdminRequestHistory extends StatefulWidget {
  const AdminRequestHistory({super.key});

  @override
  State<AdminRequestHistory> createState() => _AdminRequestHistoryState();
}

class _AdminRequestHistoryState extends State<AdminRequestHistory> {
  String selectedTab = "Approved";

  final dbService = DatabaseService();

  late Future<List<CollaborationRequest>> futureRejectRequest;
  late Future<List<CollaborationRequest>> futureApproveRequest;

  @override
  void initState() {
    super.initState();
    _getAllCenterAndRequest();
  }

  void _getAllCenterAndRequest() async {
    var reject = dbService.getAllRejectRequest();
    var approve = dbService.getAllApproveRequest();
    setState(() {
      futureRejectRequest = reject;
      futureApproveRequest = approve;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_)=>AdminCollaborationRequestPage())),
        ),
        title: const Text("Request History"),

      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // TAB BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Approved"),
              const SizedBox(width: 10),
              _buildTabButton("Rejected"),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: selectedTab == "Approved"
                ? _buildApprovedCenters()
                : _buildRequestList(),
          ),
        ],
      ),
    );
  }

  // ---------------------
  // TAB BUTTON
  // ---------------------
  Widget _buildTabButton(String title) {
    bool isSelected = selectedTab == title;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
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
    return FutureBuilder<List<CollaborationRequest>>(
      future: futureApproveRequest,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final centers = snapshot.data!;

        if (centers.isEmpty) {
          return const Center(child: Text("No approved collaboration request found"));
        }

        return ListView.builder(
          itemCount: centers.length,
          itemBuilder: (context, i) {
            final c = centers[i];
            return _buildCenterTile(
              title: c.centerName,
              address: c.location,
              requestID: c.RequestID, // 🔥 Use center ID
            );
          },
        );
      },
    );
  }

  // ---------------------
  // COLLABORATION REQUEST LIST
  // ---------------------
  Widget _buildRequestList() {
    return FutureBuilder<List<CollaborationRequest>>(
      future: futureRejectRequest,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return const Center(child: Text("No rejected collaboration requests found"));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final r = requests[i];
            return _buildCenterTile(
              title: r.centerName,
              address: r.location,
              requestID: r.RequestID, // 🔥 Use request ID
            );
          },
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
    required String requestID, // 🔥 Needed for navigation
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminCollaborationDetailsPage(requestID: requestID), // 🔥 Navigate
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child:
              const Icon(Icons.home_repair_service, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(address,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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

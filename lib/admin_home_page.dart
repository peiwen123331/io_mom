import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:io_mom/booking.dart';
import 'package:io_mom/database.dart';
import 'admin_collaboration_request_page.dart';
import 'admin_income_page.dart';
import 'admin_page_bottom.dart';
import 'admin_page_drawer.dart';
import 'admin_resources_page.dart';
import 'admin_user_page.dart';
import 'user.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  String _selectedQuarter = 'Overall';
  final dbService = DatabaseService();
  // Dynamic data variables
  int activeUser = 0;
  int inactiveUser = 0;
  int totalUsers = 0;
  int userOnchange = 0;
  int collaborationRequests = 0;
  int totalResources = 0;
  int confinementCenters = 0;
  double totalIncome = 0.0;
  List<Booking> bookings = [];
  bool isLoading = true;
  Users admin = Users.empty();

  final List<String> quarters = [
    'Overall' ,
    'Quarter 1',
    'Quarter 2',
    'Quarter 3',
    'Quarter 4',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Method to load dashboard data
  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var _activePregnantWomen = await dbService.getAllActivePregnantWomen();
      var _activeFamilyCaregiver = await dbService.getAllActiveFamilyCaregiver();
      var _activeCenter = await dbService.getAllActiveCenter();
      var totalActive = _activePregnantWomen.length + _activeFamilyCaregiver.length + _activeCenter.length;


      var _inactivePregnantWomen = await dbService.getAllInactivePregnantWomen();
      var _inactiveFamilyCaregiver = await dbService.getAllInactiveFamilyCaregiver();
      var _inactiveCenter = await dbService.getAllInactiveCenter();
      var totalInactive = _inactivePregnantWomen.length + _inactiveFamilyCaregiver.length + _inactiveCenter.length;

      if(_selectedQuarter == 'Overall'){
        setState(() {
          activeUser = _activePregnantWomen.length;
          inactiveUser = _activeFamilyCaregiver.length;
          userOnchange = _activeFamilyCaregiver.length + _activePregnantWomen.length;
        });
      }else if(_selectedQuarter == 'Quarter 1'){
        var ac = await dbService.getAllUserByRoleAndDate('P', '2025-01-01', '2025-03-31');
        var afc = await dbService.getAllUserByRoleAndDate('FC', '2025-01-01', '2025-03-31');
        var acc = await dbService.getAllUserByRoleAndDate('C', '2025-01-01', '2025-03-31');
        var ic = await dbService.getAllInactiveUserByRoleAndDate('P', '2025-01-01', '2025-03-31');
        var ifc = await dbService.getAllInactiveUserByRoleAndDate('FC', '2025-01-01', '2025-03-31');
        var icc = await dbService.getAllInactiveUserByRoleAndDate('C', '2025-01-01', '2025-03-31');
        var totalActiveQ1 = ac.length + afc.length + acc.length;
        var totalInactiveQ1 = ic.length + ifc.length + icc.length;

        setState(() {
          activeUser = ac.length;
          inactiveUser = afc.length;
          userOnchange = totalInactiveQ1 + totalActiveQ1;
        });
      }else if(_selectedQuarter == 'Quarter 2'){

        var ac = await dbService.getAllUserByRoleAndDate('P', '2025-04-01', '2025-06-30');
        var afc = await dbService.getAllUserByRoleAndDate('FC', '2025-04-01', '2025-06-30');
        var acc = await dbService.getAllUserByRoleAndDate('C', '2025-04-01', '2025-06-30');
        var ic = await dbService.getAllInactiveUserByRoleAndDate('P', '2025-04-01', '2025-06-30');
        var ifc = await dbService.getAllInactiveUserByRoleAndDate('FC', '2025-04-01', '2025-06-30');
        var icc = await dbService.getAllInactiveUserByRoleAndDate('C', '2025-04-01', '2025-06-30');
        var totalActiveQ2 = ac.length + afc.length + acc.length;
        var totalInactiveQ2 = ic.length + ifc.length + icc.length;

        setState(() {
          activeUser = ac.length;
          inactiveUser = afc.length;
          userOnchange = totalInactiveQ2 + totalActiveQ2;
        });

      }else if(_selectedQuarter == 'Quarter 3'){
        var ac = await dbService.getAllUserByRoleAndDate('P', '2025-07-01', '2025-09-30');
        var afc = await dbService.getAllUserByRoleAndDate('FC', '2025-07-01', '2025-09-30');
        var acc = await dbService.getAllUserByRoleAndDate('C', '2025-07-01', '2025-09-30');
        var ic = await dbService.getAllInactiveUserByRoleAndDate('P', '2025-07-01', '2025-09-30');
        var ifc = await dbService.getAllInactiveUserByRoleAndDate('FC', '2025-07-01', '2025-09-30');
        var icc = await dbService.getAllInactiveUserByRoleAndDate('C', '2025-07-01', '2025-09-30');
        var totalActiveQ3 = ac.length + afc.length + acc.length;
        var totalInactiveQ3 = ic.length + ifc.length + icc.length;

        setState(() {
          activeUser = ac.length;
          inactiveUser = afc.length;
          userOnchange = totalInactiveQ3 + totalActiveQ3;
        });
      }else if(_selectedQuarter == 'Quarter 4'){
        var ac = await dbService.getAllUserByRoleAndDate('P', '2025-10-01', '2025-12-31');
        var afc = await dbService.getAllUserByRoleAndDate('FC', '2025-10-01', '2025-12-31');
        var acc = await dbService.getAllUserByRoleAndDate('C', '2025-10-01', '2025-12-31');
        var ic = await dbService.getAllInactiveUserByRoleAndDate('P', '2025-10-01', '2025-12-31');
        var ifc = await dbService.getAllInactiveUserByRoleAndDate('FC', '2025-10-01', '2025-12-31');
        var icc = await dbService.getAllInactiveUserByRoleAndDate('C', '2025-10-01', '2025-12-31');
        var totalActiveQ4 = ac.length + afc.length + acc.length;
        var totalInactiveQ4 = ic.length + ifc.length + icc.length;

        setState(() {
          activeUser = ac.length;
          inactiveUser = afc.length;
          userOnchange = totalInactiveQ4 + totalActiveQ4;
        });
      }
      var colRequest = await dbService.getAllCollaborationRequest();
      var resources = await dbService.getAllResources();
      var center = await dbService.getAllCenter();
      var booking = await dbService.getAllBooking();
      setState(() {
        bookings = booking;
      });
      var user = await dbService.getUserByUID(currentUser.uid);

      await Future.delayed(const Duration(seconds: 1));


      setState(() {
        admin = user!;
        totalUsers = totalActive + totalInactive;
        collaborationRequests = colRequest.length;
        totalResources = resources.length;
        confinementCenters = center.length;
        totalIncome = totalPlatformIncome;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dashboard data')),
        );
      }
    }
  }

  double calculatePlatformTax(double payAmount) {
    return payAmount - (payAmount / 1.06);
  }

  double get totalPlatformIncome {
    return bookings
        .where((b) => b.paymentStatus == 'P' || b.paymentStatus == 'R')
        .fold(0.0, (sum, b) => sum + calculatePlatformTax(b.payAmount));
  }

  // Method to handle quarter selection
  void _onQuarterChanged(String? newQuarter) {
    if (newQuarter != null) {
      setState(() {
        _selectedQuarter = newQuarter;
      });
      _loadDashboardData(); // Reload data for selected quarter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminPageDrawer(userName: "Admin"),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Home",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: admin.profileImgPath != null &&
                  admin.profileImgPath!.isNotEmpty
                  ? (admin.profileImgPath!.startsWith('assets/')
                  ?  AssetImage(admin.profileImgPath!) as ImageProvider
                  :  FileImage(File(admin.profileImgPath!)))
                  : const AssetImage('assets/images/profile/profile.png'),
              radius: 16,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hello, Admin",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),

            // Donut chart container with dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Quarter dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("User Statistics",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.pinkAccent.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedQuarter,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            items: quarters.map((String quarter) {
                              return DropdownMenuItem<String>(
                                value: quarter,
                                child: Text(quarter),
                              );
                            }).toList(),
                            onChanged: _onQuarterChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                color: Colors.greenAccent,
                                value: activeUser.toDouble(),
                                title: '',
                                radius: 20,
                              ),
                              PieChartSectionData(
                                color: Colors.pinkAccent,
                                value: inactiveUser.toDouble(),
                                title: '',
                                radius: 20,
                              ),
                            ],
                          ),
                        ),
                        Text('$userOnchange',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _LegendDot(color: Colors.greenAccent, label: 'Pregnant Women'),
                      SizedBox(width: 10),
                      _LegendDot(color: Colors.pinkAccent, label: 'Family Member'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary cards grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _DashboardCard(
                  title: "Total User",
                  value: "$totalUsers",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminUserPage()));
                  },
                ),
                _DashboardCard(
                  title: "Collaboration Request",
                  value: "$collaborationRequests",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AdminCollaborationRequestPage()));
                  },
                ),
                _DashboardCard(
                  title: "Total Resources",
                  value: "$totalResources",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminResourcesPage()));
                  },
                ),
                _DashboardCard(
                  title: "Confinement Center",
                  value: "$confinementCenters",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminCollaborationRequestPage()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Income card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1)
                ],
              ),
              child: GestureDetector(
                child: Column(
                  children: [
                    Text("RM${totalIncome.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent)),
                    const SizedBox(height: 4),
                    const Text("Total Income",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdminIncomePage()));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
      AdminPageBottom(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

// Reusable dashboard card with tap functionality
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 28)),
            const SizedBox(height: 5),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Simple legend widget
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
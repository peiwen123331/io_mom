import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:io_mom/confinement_center.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'cc_booking_page.dart';
import 'cc_package_page.dart';
import 'cc_page_bottom.dart';
import 'cc_page_drawer.dart';
import 'database.dart';
import 'booking.dart';
import 'package.dart' as pkg;

class ConfinementCenterHomePage extends StatefulWidget {
  const ConfinementCenterHomePage({super.key});

  @override
  State<ConfinementCenterHomePage> createState() =>
      _ConfinementCenterHomePageState();
}

class _ConfinementCenterHomePageState extends State<ConfinementCenterHomePage> {
  int _selectedIndex = 0;
  late String centerID;
  late ConfinementCenter center = ConfinementCenter.empty();
  final dbService = DatabaseService();

  // Data variables
  bool isLoading = true;
  int totalBookings = 0;
  int totalPackages = 0;
  double totalIncome = 0.0;
  Map<String, int> packageBookingCounts = {};
  List<Booking> allBookings = [];
  List<pkg.Package> allPackages = [];
  int overallTotalBookings = 0;
  double overallTotalIncome = 0.0;

  // Filter variables
  String _selectedMonth = 'Overall';
  final List<String> months = [
    'Overall',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<Color> colorList = [
    Colors.greenAccent,
    Colors.amber,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getUser();
    await _loadDashboardData();
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('CenterID');
    final currentCenter = await dbService.getConfinementByCenterID(cid!);
    setState(() {
      centerID = cid;
      center = currentCenter!;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch all bookings and packages for this center
      allBookings = await dbService.getBookingsByCenterID(centerID);
      allPackages = await dbService.getPackageByCenterID(centerID);

      // ===== CALCULATE OVERALL STATS (for the entire year) =====
      String year = DateTime.now().year.toString();
      String yearStartDate = '$year-01-01T00:00:00.000000';
      String yearEndDate = '$year-12-31T23:59:59.999999';

      List<Booking> yearBookings = await dbService.getBookingsByCenterIDAndDate(
          centerID,
          yearStartDate,
          yearEndDate
      );

      int yearBookingCount = 0;
      double yearIncome = 0.0;

      for (var booking in yearBookings) {
        String status = booking.paymentStatus.trim().toUpperCase();
        if (status == 'P' || status == 'C' || status == 'R') {
          yearBookingCount++;
          yearIncome += calculateCenterAmount(booking.payAmount);
        }
      }

      // ===== CALCULATE FILTERED STATS (for pie chart based on selected month) =====
      List<Booking> filteredBookings = await _filterBookingsByMonth(allBookings);

      // Calculate package distribution for pie chart
      Map<String, int> packageCounts = {};
      int validBookingCount = 0;

      for (var booking in filteredBookings) {
        String status = booking.paymentStatus.trim().toUpperCase();

        if (status == 'P' || status == 'C' || status == 'R') {
          validBookingCount++;

          // Find package name
          var package = allPackages.firstWhere(
                  (p) => p.PackageID == booking.PackageID,
              orElse: () => pkg.Package(
                PackageID: "",
                packageName: "Unknown",
                duration: 0,
                description: "",
                price: 0,
                availability: 0,
                status: "Unavailable",
                CenterID: "",
              )
          );

          String packageName = package.packageName;
          packageCounts[packageName] = (packageCounts[packageName] ?? 0) + 1;
        }
      }

      setState(() {
        // Stats for pie chart (changes with month selection)
        packageBookingCounts = packageCounts;

        // Stats for bottom cards (always shows year overall)
        overallTotalBookings = yearBookingCount;
        overallTotalIncome = yearIncome;
        totalPackages = allPackages.length;

        isLoading = false;
      });

      print("📊 Chart Stats ($_selectedMonth) - Bookings: $validBookingCount");
      print("📊 Overall Stats (Year $year) - Bookings: $overallTotalBookings, Income: RM${overallTotalIncome.toStringAsFixed(2)}");

    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dashboard data')),
        );
      }
    }
  }


  Future<List<Booking>> _filterBookingsByMonth(List<Booking> bookings) async {
    String year = DateTime.now().year.toString();

    if (_selectedMonth == 'Overall') {

      String startDate = '$year-01-01T00:00:00.000000';
      String endDate = '$year-12-31T23:59:59.999999';

      print('Overall - Start: $startDate');
      print('Overall - End: $endDate');

      var centersBooking = await dbService.getBookingsByCenterIDAndDate(
          centerID,
          startDate,
          endDate
      );
      print("Center bookings found for year $year: ${centersBooking.length}");
      return centersBooking;
    }

    // For specific month
    int monthIndex = months.indexOf(_selectedMonth);
    String startDate = '$year-${monthIndex.toString().padLeft(2, '0')}-01T00:00:00.000000';

    DateTime lastDay = DateTime(int.parse(year), monthIndex + 1, 0);
    String endDate = '${DateFormat('yyyy-MM-dd').format(lastDay)}T23:59:59.999999';

    print('$_selectedMonth - Start: $startDate');
    print('$_selectedMonth - End: $endDate');

    var centersBooking = await dbService.getBookingsByCenterIDAndDate(
        centerID,
        startDate,
        endDate
    );
    print("Center bookings found for $_selectedMonth: ${centersBooking.length}");
    return centersBooking;
  }
  double calculateCenterAmount(double payAmount) {
    return payAmount / 1.06;
  }


  void _onMonthChanged(String? newMonth) {
    if (newMonth != null) {
      setState(() {
        _selectedMonth = newMonth;
      });
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalChartBookings = packageBookingCounts.values.fold<int>(
        0,
            (sum, value) => sum + value
    );


    return Scaffold(
      drawer: CcPageDrawer(userName: center!.CenterName),
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: center!.centerImgPath != null &&
                  center!.centerImgPath!.isNotEmpty
                  ? (center!.centerImgPath!.startsWith('assets/')
                  ? AssetImage(center!.centerImgPath!) as ImageProvider
                  : FileImage(File(center!.centerImgPath!)))
                  : const AssetImage('assets/images/profile/profile.png'),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hello, ${center!.CenterName}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 15),

            // ---- Chart Section ----
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Month Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Booking Statistics",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pinkAccent.shade100,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.pinkAccent,
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              items: months.map((String month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                              onChanged: _onMonthChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Chart or Empty State
                    packageBookingCounts.isEmpty
                        ? Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No bookings for this period',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 60,
                              borderData: FlBorderData(show: false),
                              sections: List.generate(
                                packageBookingCounts.length,
                                    (i) {
                                  final key = packageBookingCounts
                                      .keys
                                      .elementAt(i);
                                  final value =
                                  packageBookingCounts[key]!;

                                  return PieChartSectionData(
                                    color: colorList[
                                    i % colorList.length],
                                    value: value.toDouble(),
                                    title: '',
                                    radius: 40,
                                  );
                                },
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalChartBookings.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Total Bookings',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Legend
                    if (packageBookingCounts.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          packageBookingCounts.length,
                              (i) {
                            final key =
                            packageBookingCounts.keys.elementAt(i);
                            final value = packageBookingCounts[key]!;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colorList[i % colorList.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$value $key',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---- Stat Cards ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Total Booking",
                    value: "$overallTotalBookings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CcBookingPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    title: "Total Package",
                    value: "$totalPackages",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CcPackagePage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _StatCard(
              title: "Total Income",
              value: "RM${overallTotalIncome.toStringAsFixed(2)}",
              highlight: true,
              onTap: () {
                // Navigate to income details if needed
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CCPageBottom(
        currentIndex: _selectedIndex,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: highlight ? Colors.pinkAccent : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
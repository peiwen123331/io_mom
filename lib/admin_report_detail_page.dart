import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'booking.dart';
import 'collaboration_request.dart';
import 'milestone_reminder.dart';
import 'user.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminReportDetailPage extends StatefulWidget {
  final String startDate;
  final String endDate;
  final String reportType;

  const AdminReportDetailPage({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.reportType,
  });

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  bool _isLoading = true;
  final dbService = DatabaseService();
  // User Management Data
  List<Users> _activePregnantWomen = [];
  List<Users> _inactivePregnantWomen = [];
  List<Users> _activeFamilyCaregiver = [];
  List<Users> _inactiveFamilyCaregiver = [];
  List<Users> _activeCenter = [];
  List<Users> _inactiveCenter = [];
  List<MilestoneReminder> _milestoneReminders = [];
  double _usersWithHealthData = 0.0;
  double _percentageLinkedAccounts = 0.0;
  List<Booking> bookings = [];
  List<CollaborationRequest> _pendingRequests = [];
  List<CollaborationRequest> _approvedRequests = [];
  List<CollaborationRequest> _rejectedRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.reportType == "User Management Summary Report") {
        // Load user management data individually to handle errors better
        _activePregnantWomen = await dbService.getAllActivePregnantWomen();
        _inactivePregnantWomen = await dbService.getAllInactivePregnantWomen();
        _activeFamilyCaregiver = await dbService.getAllActiveFamilyCaregiver();
        _inactiveFamilyCaregiver = await dbService.getAllInactiveFamilyCaregiver();
        _activeCenter = await dbService.getAllActiveCenter();
        _inactiveCenter = await dbService.getAllInactiveCenter();

        final milReminders = await dbService.getAllMilReminder(widget.startDate, widget.endDate);
        _milestoneReminders = milReminders ?? [];

        _usersWithHealthData = await dbService.getUserWithHealthData(widget.startDate, widget.endDate);
        _percentageLinkedAccounts = await dbService.getPercentageUsersWithLinkedAccounts(widget.startDate, widget.endDate);

        setState(() {});
      } else {
        // Load confinement center data
        _activeCenter = await dbService.getAllActiveCenter();
        _inactiveCenter = await dbService.getAllInactiveCenter();

        await setBooking();
        // ADD THESE LINES to fetch collaboration requests
        _pendingRequests = await dbService.getAllRequest();
        _approvedRequests = await dbService.getAllApproveRequest();
        _rejectedRequests = await dbService.getAllRejectRequest();

        setState(() {});
      }
    } catch (e, stackTrace) {
      print("Error loading report data: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading report: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> setBooking()async{
  var retrieveBookings = await dbService.getAllBooking();
  setState(() {
    bookings = retrieveBookings!;
  });
}

double calculatePlatformTax(double payAmount) {
  return payAmount - (payAmount / 1.06);
}

double get totalPlatformIncome {
  return bookings
      .where((b) => b.paymentStatus == 'P' || b.paymentStatus == 'R')
      .fold(0.0, (sum, b) => sum + calculatePlatformTax(b.payAmount));
}

double calculateCenterAmount(double payAmount) {
  return payAmount / 1.06;
}


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary Report"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: widget.reportType == "User Management Summary Report"
            ? _buildUserManagementReport()
            : _buildConfinementCenterReport(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.pink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : _downloadReport,
          child: const Text(
            "Download",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }


  // Generate User Management Report PDF
  Future<void> _generateUserManagementPDF(pw.Document pdf) async {
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter users by registration date within range
    final pregnantInRange = [..._activePregnantWomen, ..._inactivePregnantWomen]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final familyInRange = [..._activeFamilyCaregiver, ..._inactiveFamilyCaregiver]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final centerInRange = [..._activeCenter, ..._inactiveCenter]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final totalPregnantInRange = pregnantInRange.length;
    final totalFamilyInRange = familyInRange.length;
    final totalCenterInRange = centerInRange.length;

    final usersWithReminders = _milestoneReminders.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title
            pw.Text(
              "User Management Summary Report",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Reporting Period: ${_formatDateRange()}"),
            pw.Text("Start Date: ${formatDate(widget.startDate)}"),
            pw.Text("End Date: ${formatDate(widget.endDate)}"),
            pw.SizedBox(height: 20),

            // User Overview Section
            pw.Text(
              "User Overview",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Metric Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildPdfMetricCard("Pregnant Women", "$totalPregnantInRange", PdfColors.pink)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildPdfMetricCard("Family Members", "$totalFamilyInRange", PdfColors.blue)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildPdfMetricCard("Confinement Centers", "$totalCenterInRange", PdfColors.green)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Bar Chart Section
            pw.Text(
              "User Registration Overview",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfUserBarChart(totalPregnantInRange, totalFamilyInRange, totalCenterInRange),
            pw.SizedBox(height: 20),

            // User Registration Activity
            pw.Text(
              "User Registration Activity",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfUserRegistrationTable(),
            pw.SizedBox(height: 20),

            // User Engagement
            pw.Text(
              "User Engagement",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Users with Upcoming Milestones/Medications: $usersWithReminders"),
            pw.Text("Percentage with Health Data: ${_usersWithHealthData.toStringAsFixed(2)}%"),
            pw.Text("Percentage with Linked Accounts: ${_percentageLinkedAccounts.toStringAsFixed(2)}%"),
          ];
        },
      ),
    );
  }

  pw.Widget _buildPdfMetricCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1), // Light version of the color
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfUserBarChart(int pregnant, int family, int center) {
    final maxValue = [pregnant, family, center].reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 200,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildPdfBar("Pregnant\nWomen", pregnant, maxValue, PdfColors.pink),
          _buildPdfBar("Family\nMembers", family, maxValue, PdfColors.blue),
          _buildPdfBar("Confinement\nCenters", center, maxValue, PdfColors.green),
        ],
      ),
    );
  }

  pw.Widget _buildPdfBar(String label, int value, int maxValue, PdfColor color) {
    final height = maxValue > 0 ? (value / maxValue * 150) : 0.0;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          value.toString(),
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          width: 60,
          height: height,
          color: color,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildPdfUserRegistrationTable() {
    // Parse date range from widget parameters
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter users by date range - get ALL user types
    final usersInRange = [
      ..._activePregnantWomen,
      ..._inactivePregnantWomen,
      ..._activeFamilyCaregiver,
      ..._inactiveFamilyCaregiver,
      ..._activeCenter,
      ..._inactiveCenter
    ].where((user) {
      return user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          user.userRegDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    Map<String, Map<String, int>> monthlyData = {};

    // Generate all months between startDate and endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      final month = "${current.year}-${current.month.toString().padLeft(2, '0')}";
      monthlyData[month] = {'new': 0};
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Fill in actual registration data for users in the date range
    for (var user in usersInRange) {
      final month = "${user.userRegDate.year}-${user.userRegDate.month.toString().padLeft(2, '0')}";
      if (monthlyData.containsKey(month)) {
        monthlyData[month]!['new'] = (monthlyData[month]!['new'] ?? 0) + 1;
      }
    }

    // Calculate cumulative totals
    var sortedMonths = monthlyData.keys.toList()..sort();
    int cumulative = 0;

    // Build table rows
    List<pw.TableRow> rows = [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildPdfTableCell("Period", isHeader: true),
          _buildPdfTableCell("New Registered", isHeader: true),
          _buildPdfTableCell("Total Active", isHeader: true),
        ],
      ),
    ];

    // Add data rows
    for (var month in sortedMonths) {
      cumulative += monthlyData[month]!['new']!;
      final date = DateTime.parse("$month-01");
      final monthName = _getMonthName(date.month);

      rows.add(
        pw.TableRow(
          children: [
            _buildPdfTableCell("$monthName ${date.year}"),
            _buildPdfTableCell("${monthlyData[month]!['new']}"),
            _buildPdfTableCell("$cumulative"),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  pw.TableRow _buildPdfTableRow(String userType, int active, int inactive) {
    return pw.TableRow(
      children: [
        _buildPdfTableCell(userType),
        _buildPdfTableCell(active.toString()),
        _buildPdfTableCell(inactive.toString()),
        _buildPdfTableCell((active + inactive).toString()),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _generateConfinementCenterPDF(pw.Document pdf) async {
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter centers by registration date within range
    final centersInRange = [..._activeCenter, ..._inactiveCenter]
        .where((center) =>
    center.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        center.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final totalActive = _activeCenter.length;
    final totalInactive = _inactiveCenter.length;
    final totalCenters = totalActive + totalInactive;
    final newRegistrations = centersInRange.length;

    // Booking metrics
    final completedBookings = bookings.where((b) {
      final isCompleted = b.paymentStatus == 'P' || b.paymentStatus == 'R';
      final isInRange = b.bookingDate.isAfter(startDate) && b.bookingDate.isBefore(endDate.add(const Duration(days: 1)));
      return isCompleted && isInRange;
    }).toList();

    final totalBookings = completedBookings.length;
    final totalRevenueBefore = completedBookings.fold<double>(0.0, (sum, b) => sum + b.payAmount);
    var totalTaxCollected = 0.0;
    if (completedBookings.isNotEmpty) {
      for (var b in completedBookings) {
        totalTaxCollected += calculatePlatformTax(b.payAmount);
      }
    }
    final totalRevenueAfter = completedBookings.fold<double>(0.0, (sum, b) => sum + calculateCenterAmount(b.payAmount));

    // Collaboration requests
    final pendingInRange = _pendingRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final approvedInRange = _approvedRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final rejectedInRange = _rejectedRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalRequests = pendingInRange.length + approvedInRange.length + rejectedInRange.length;

    // Calculate average processing duration
    Duration avgDuration = Duration();
    final allProcessedRequests = [...approvedInRange, ...rejectedInRange];

    if (allProcessedRequests.isNotEmpty) {
      final totalSeconds = allProcessedRequests.fold<int>(0, (sum, req) {
        if (req.approveDate != null && req.approveDate!.isNotEmpty) {
          try {
            final approveDateTime = DateTime.parse(req.approveDate!);
            return sum + approveDateTime.difference(req.requestDate).inSeconds;
          } catch (e) {
            return sum;
          }
        }
        return sum;
      });

      if (totalSeconds > 0) {
        final avgSeconds = totalSeconds / allProcessedRequests.length;
        avgDuration = Duration(seconds: avgSeconds.round());
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title
            pw.Text(
              "Confinement Center Summary Report",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Reporting Period: ${_formatDateRange()}"),
            pw.Text("Start Date: ${formatDate(widget.startDate)}"),
            pw.Text("End Date: ${formatDate(widget.endDate)}"),
            pw.SizedBox(height: 20),

            // Key Metrics Overview
            pw.Text(
              "Key Metrics Overview",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Metric Cards Row 1
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildPdfMetricCard("Total Bookings", "$totalBookings", PdfColors.blue)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildPdfMetricCard("Platform Tax", "RM ${totalTaxCollected.toStringAsFixed(2)}", PdfColors.green)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Revenue Bar Chart
            pw.Text(
              "Revenue Breakdown",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfRevenueBarChart(totalRevenueBefore, totalRevenueAfter, totalTaxCollected),
            pw.SizedBox(height: 20),

            // Monthly Registration Table
            pw.Text(
              "Monthly Registration Activity",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfCenterMonthlyRegistrationTable(centersInRange),
            pw.SizedBox(height: 20),

            // Collaboration Requests
            pw.Text(
              "Collaboration Request Summary",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Request Metric Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildPdfMetricCard("Total Requests", "$totalRequests", PdfColors.blue)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildPdfMetricCard("Pending", "${pendingInRange.length}", PdfColors.orange)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildPdfMetricCard("Approved", "${approvedInRange.length}", PdfColors.green)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildPdfMetricCard("Rejected", "${rejectedInRange.length}", PdfColors.red)),
              ],
            ),
            pw.SizedBox(height: 10),
            // Processing Duration
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue.shade(0.1),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    "Average Processing Duration: ",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    avgDuration.inSeconds > 0
                        ? "${avgDuration.inHours} hours ${avgDuration.inMinutes.remainder(60)} minutes"
                        : "N/A",
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue),
                  ),
                ],
              ),
            ),

            // Pending Requests Details
            if (pendingInRange.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                "Pending Requests Details",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPdfPendingRequestsTable(pendingInRange),
            ],
          ];
        },
      ),
    );
  }
  pw.Widget _buildPdfRevenueBarChart(double totalRevenue, double releaseAmount, double platformTax) {
    final maxValue = [totalRevenue, releaseAmount, platformTax].reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 200,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildPdfBar("Total\nRevenue", totalRevenue.toInt(), maxValue.toInt(), PdfColors.blue),
          _buildPdfBar("Release\nAmount", releaseAmount.toInt(), maxValue.toInt(), PdfColors.green),
          _buildPdfBar("Platform\nTax (6%)", platformTax.toInt(), maxValue.toInt(), PdfColors.orange),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCenterStatusBarChart(int active, int inactive, int newReg) {
    final maxValue = [active, inactive, newReg].reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 200,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildPdfBar("Active\nCenters", active, maxValue, PdfColors.green),
          _buildPdfBar("Inactive\nCenters", inactive, maxValue, PdfColors.orange),
          _buildPdfBar("New in\nPeriod", newReg, maxValue, PdfColors.blue),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRequestStatusBarChart(int pending, int approved, int rejected) {
    final maxValue = [pending, approved, rejected].reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 200,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildPdfBar("Pending", pending, maxValue, PdfColors.orange),
          _buildPdfBar("Approved", approved, maxValue, PdfColors.green),
          _buildPdfBar("Rejected", rejected, maxValue, PdfColors.red),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCenterMonthlyRegistrationTable(List<Users> centersInRange) {
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    Map<String, Map<String, int>> monthlyData = {};

    // Generate all months between startDate and endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      final month = "${current.year}-${current.month.toString().padLeft(2, '0')}";
      monthlyData[month] = {'new': 0};
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Fill in actual registration data
    for (var center in centersInRange) {
      final month = "${center.userRegDate.year}-${center.userRegDate.month.toString().padLeft(2, '0')}";
      if (monthlyData.containsKey(month)) {
        monthlyData[month]!['new'] = (monthlyData[month]!['new'] ?? 0) + 1;
      }
    }

    var sortedMonths = monthlyData.keys.toList()..sort();
    int cumulative = 0;

    List<pw.TableRow> rows = [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildPdfTableCell("Period", isHeader: true),
          _buildPdfTableCell("New Registered", isHeader: true),
          _buildPdfTableCell("Total Active", isHeader: true),
        ],
      ),
    ];

    // Add data rows
    for (var month in sortedMonths) {
      cumulative += monthlyData[month]!['new']!;
      final date = DateTime.parse("$month-01");
      final monthName = _getMonthName(date.month);

      rows.add(
        pw.TableRow(
          children: [
            _buildPdfTableCell("$monthName ${date.year}"),
            _buildPdfTableCell("${monthlyData[month]!['new']}"),
            _buildPdfTableCell("$cumulative"),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  pw.Widget _buildPdfPendingRequestsTable(List<CollaborationRequest> requests) {
    List<pw.TableRow> rows = [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildPdfTableCell("Center Name", isHeader: true),
          _buildPdfTableCell("Request Date", isHeader: true),
          _buildPdfTableCell("Days Pending", isHeader: true),
        ],
      ),
    ];

    // Add data rows
    for (var req in requests) {
      final daysPending = DateTime.now().difference(req.requestDate).inDays;
      final formattedDate = "${req.requestDate.day.toString().padLeft(2, '0')}-${req.requestDate.month.toString().padLeft(2, '0')}-${req.requestDate.year}";

      rows.add(
        pw.TableRow(
          children: [
            _buildPdfTableCell(req.centerName),
            _buildPdfTableCell(formattedDate),
            _buildPdfTableCell("$daysPending days"),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }



  Future<void> _downloadReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 16),
                Text(
                  "Generating PDF Report...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Please wait",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create PDF document
      final pdf = pw.Document();

      // Generate appropriate report based on type
      if (widget.reportType == "User Management Summary Report") {
        await _generateUserManagementPDF(pdf);
      } else {
        await _generateConfinementCenterPDF(pdf);
      }

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final reportTypeName = widget.reportType == "User Management Summary Report"
          ? "UserManagement"
          : "ConfinementCenter";
      final filename = '${reportTypeName}_Report_$timestamp.pdf';

      // Show print/save dialog with custom name
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: filename,
        format: PdfPageFormat.a4,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Report generated successfully!",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Log error for debugging
      print("Error generating report: $e");
      print("Stack trace: $stackTrace");

      // Show detailed error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text("Error Generating Report"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Failed to generate the PDF report. Please try again.",
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Error: ${e.toString()}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _downloadReport(); // Retry
                },
                child: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
  String formatDate(String dateString) {
    try {
      // Parse the string to DateTime
      DateTime date = DateTime.parse(dateString);
      // Format to dd-MM-yyyy
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      // Return original string if parsing fails
      return dateString;
    }
  }


  // ---------------------------------------------------------------------------
  // 1. USER MANAGEMENT SUMMARY REPORT
  // ---------------------------------------------------------------------------
  Widget _buildUserManagementReport() {
    final totalPregnant = _activePregnantWomen.length + _inactivePregnantWomen.length;
    final totalFamily = _activeFamilyCaregiver.length + _inactiveFamilyCaregiver.length;
    final totalCenter = _activeCenter.length + _inactiveCenter.length;
    final totalActive = _activePregnantWomen.length + _activeFamilyCaregiver.length + _activeCenter.length;

    // Calculate percentage with health data
    final percentageHealthData = 0.0;


    // Count users with milestones/medications
    final usersWithReminders = _milestoneReminders.length;

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("User Management Summary Report"),
          _subTitle("Reporting Period: ${_formatDateRange()}"),
          _subTitle("Start Date : ${formatDate(widget.startDate)}"),
          _subTitle("End Date : ${formatDate(widget.endDate)}"),

          const SizedBox(height: 20),
          _sectionTitle("User Overview"),
          _tableUserOverview(
            totalPregnant, _activePregnantWomen.length, _inactivePregnantWomen.length,
            totalFamily, _activeFamilyCaregiver.length, _inactiveFamilyCaregiver.length,
            totalCenter, _activeCenter.length, _inactiveCenter.length,
          ),

          const SizedBox(height: 20),
          _sectionTitle("User Registration Activity"),
          _tableUserRegistration(),

          const SizedBox(height: 20),
          _sectionTitle("User Engagement"),
          _tableUserEngagement(usersWithReminders, _usersWithHealthData.toStringAsFixed(2)),
        ],
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // 2. CONFINEMENT CENTER SUMMARY REPORT
  // ---------------------------------------------------------------------------
  Widget _buildConfinementCenterReport() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Confinement Center Summary Report"),
          _subTitle("Reporting Period: ${_formatDateRange()}"),
          _subTitle("Start Date : ${formatDate(widget.startDate)}"),
          _subTitle("End Date : ${formatDate(widget.endDate)}"),

          const SizedBox(height: 20),
          _sectionTitle("Key Metrics Overview"),
          _tableKeyMetrics(),

          const SizedBox(height: 20),
          _sectionTitle("Confinement Center Registration Activity"),
          _tableCenterRegistration(),

          const SizedBox(height: 20),
          _sectionTitle("Collaboration Request Pending"),
          _tablePendingRequests(),
        ],
      ),
    );
  }

  String _formatDateRange() {
    try {
      final start = DateTime.parse(widget.startDate);
      final end = DateTime.parse(widget.endDate);

      if (start.year == end.year) {
        return "Q${((start.month - 1) ~/ 3) + 1} ${start.year}";
      }
      return "${start.year} - ${end.year}";
    } catch (e) {
      return "Custom Period";
    }
  }

  // ---------------------------------------------------------------------------
  // WIDGET HELPERS
  // ---------------------------------------------------------------------------

  Widget _cardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );

  Widget _subTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, color: Colors.black87),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );

  // ---------------------------------------------------------------------------
  // DATA TABLES FOR USER REPORT
  // ---------------------------------------------------------------------------
  Widget _tableUserOverview(
      int totalPregnant, int activePregnant, int inactivePregnant,
      int totalFamily, int activeFamily, int inactiveFamily,
      int totalCenter, int activeCenter, int inactiveCenter,
      ) {
    // Parse date range
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter users by registration date within range
    final pregnantInRange = [..._activePregnantWomen, ..._inactivePregnantWomen]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final familyInRange = [..._activeFamilyCaregiver, ..._inactiveFamilyCaregiver]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final centerInRange = [..._activeCenter, ..._inactiveCenter]
        .where((user) =>
    user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        user.userRegDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final totalPregnantInRange = pregnantInRange.length;
    final totalFamilyInRange = familyInRange.length;
    final totalCenterInRange = centerInRange.length;

    // Find max value for Y-axis scaling
    final maxValue = [totalPregnantInRange, totalFamilyInRange, totalCenterInRange]
        .reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxValue * 1.3).clamp(5, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildUserMetricCard(
                "Pregnant Women",
                "$totalPregnantInRange",
                Icons.pregnant_woman,
                Colors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUserMetricCard(
                "Family Members",
                "$totalFamilyInRange",
                Icons.family_restroom,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUserMetricCard(
                "Confinement Centers",
                "$totalCenterInRange",
                Icons.business,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bar Chart
        const Text(
          "User Registration Overview",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: yAxisMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final labels = ['Pregnant Women', 'Family Members', 'Confinement\nCenters'];
                    return BarTooltipItem(
                      "${labels[group.x.toInt()]}\n${rod.toY.toInt()} users",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = ['Pregnant\nWomen', 'Family\nMembers', 'Centers'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          labels[value.toInt()],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue > 0 ? (yAxisMax / 6) : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[300],
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: totalPregnantInRange.toDouble(),
                      width: 45,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF48FB1), Color(0xFFE91E63)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: totalFamilyInRange.toDouble(),
                      width: 45,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: totalCenterInRange.toDouble(),
                      width: 45,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFF43A047)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tableUserRegistration() {
    // Parse date range from widget parameters
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter users by date range
    final usersInRange = [..._activePregnantWomen, ..._activeFamilyCaregiver, ..._activeCenter]
        .where((user) {
      return user.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          user.userRegDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    Map<String, Map<String, int>> monthlyData = {};

    // Generate all months between startDate and endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      final month = "${current.year}-${current.month.toString().padLeft(2, '0')}";
      monthlyData[month] = {'new': 0};
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Fill in actual registration data for users in the date range
    for (var user in usersInRange) {
      final month = "${user.userRegDate.year}-${user.userRegDate.month.toString().padLeft(2, '0')}";
      if (monthlyData.containsKey(month)) {
        monthlyData[month]!['new'] = (monthlyData[month]!['new'] ?? 0) + 1;
      }
    }

    // Calculate cumulative totals
    var sortedMonths = monthlyData.keys.toList()..sort();
    int cumulative = 0;

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: const [
            _TableCell(text: "Period", isHeader: true),
            _TableCell(text: "New Registered", isHeader: true),
            _TableCell(text: "Total Active", isHeader: true),
          ],
        ),
        ...sortedMonths.map((month) {
          cumulative += monthlyData[month]!['new']!;
          final date = DateTime.parse("$month-01");
          final monthName = _getMonthName(date.month);

          return TableRow(
            children: [
              _TableCell(text: "$monthName ${date.year}"),
              _TableCell(text: "${monthlyData[month]!['new']}"),
              _TableCell(text: "$cumulative"),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _tableUserEngagement(int usersWithReminders, String percentageHealthData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("Users with Upcoming Milestones/Medications: $usersWithReminders",
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text("Percentage with Health Data: $percentageHealthData%",
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text("Percentage with Linked Accounts: ${_percentageLinkedAccounts > 0.0 ? _percentageLinkedAccounts.toStringAsFixed(2): 0.00.toStringAsFixed(2)}%",
            style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DATA TABLES FOR CC REPORT
  // ---------------------------------------------------------------------------
  Widget _tableKeyMetrics() {

    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate).add(const Duration(days: 1));

    // Calculate metrics from bookings
    final completedBookings = bookings.where((b) {
      final isCompleted = b.paymentStatus == 'P' || b.paymentStatus == 'R';
      final isInRange = b.bookingDate.isAfter(startDate) && b.bookingDate.isBefore(endDate);

      return isCompleted && isInRange;
    }).toList();



    final totalBookings = completedBookings.length;

    // Total amount paid by customers (includes platform fee/tax)
    final totalRevenueBefore = completedBookings.fold<double>(
        0.0,
            (sum, b) => sum + b.payAmount
    );

    // Platform tax/fee collected (6% of the amount before tax)
    var totalTaxCollected = 0.0;
    if(completedBookings.length > 0){
      for(var b in completedBookings){
        totalTaxCollected += calculatePlatformTax(b.payAmount);
      }
    }

    // Revenue after deducting platform fee (amount transferred to centers)
    final totalRevenueAfter = completedBookings.fold<double>(
        0.0,
            (sum, b) => sum + calculateCenterAmount(b.payAmount)
    );

    // Platform service fee (same as tax collected in your formula)
    final platformServiceFee = totalTaxCollected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                "Total Bookings",
                "$totalBookings",
                Icons.book_online,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                "Total Platform Tax",
                "RM ${totalTaxCollected.toStringAsFixed(2)}",
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bar Chart for Revenue Breakdown
        const Text(
          "Revenue Breakdown",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: (totalRevenueBefore * 1.3).clamp(1000, double.infinity),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final labels = ['Total Revenue', 'Release Amount', 'Platform Tax'];
                    return BarTooltipItem(
                      "${labels[group.x.toInt()]}\nRM ${rod.toY.toStringAsFixed(2)}",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = [
                        'Total\nRevenue',
                        'Release\nAmount',
                        'Service\nFee (6%)'
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          labels[value.toInt()],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "RM ${(value / 1000).toStringAsFixed(0)}k",
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: totalRevenueBefore > 0
                    ? (totalRevenueBefore / 6)
                    : 100,  // default interval when no revenue
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[300],
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: totalRevenueBefore,
                      width: 36,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: totalRevenueAfter,
                      width: 36,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFF43A047)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: platformServiceFee,
                      width: 36,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ],
            ),
          )
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCenterRegistration() {
    // Parse date range from widget parameters
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate);

    // Filter centers by date range
    final centersInRange = _activeCenter.where((center) {
      return center.userRegDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          center.userRegDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    Map<String, Map<String, int>> monthlyData = {};

    // Generate all months between startDate and endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      final month = "${current.year}-${current.month.toString().padLeft(2, '0')}";
      monthlyData[month] = {'new': 0};
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Fill in actual registration data for centers in the date range
    for (var center in centersInRange) {
      final month = "${center.userRegDate.year}-${center.userRegDate.month.toString().padLeft(2, '0')}";
      if (monthlyData.containsKey(month)) {
        monthlyData[month]!['new'] = (monthlyData[month]!['new'] ?? 0) + 1;
      }
    }

    var sortedMonths = monthlyData.keys.toList()..sort();
    int cumulative = 0;

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: const [
            _TableCell(text: "Period", isHeader: true),
            _TableCell(text: "New Registered", isHeader: true),
            _TableCell(text: "Total Active", isHeader: true),
          ],
        ),
        ...sortedMonths.map((month) {
          cumulative += monthlyData[month]!['new']!;
          final date = DateTime.parse("$month-01");
          final monthName = _getMonthName(date.month);

          return TableRow(
            children: [
              _TableCell(text: "$monthName ${date.year}"),
              _TableCell(text: "${monthlyData[month]!['new']}"),
              _TableCell(text: "$cumulative"),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _tablePendingRequests() {
    var avgDuration = Duration();

    // Parse date range
    final startDate = DateTime.parse(widget.startDate);
    final endDate = DateTime.parse(widget.endDate).add(const Duration(days: 1));

    // Filter requests by date range
    final pendingInRange = _pendingRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate);
    }).toList();

    final approvedInRange = _approvedRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate);
    }).toList();

    final rejectedInRange = _rejectedRequests.where((req) {
      return req.requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          req.requestDate.isBefore(endDate);
    }).toList();

    final allRequests = [...approvedInRange, ...rejectedInRange];

    if (allRequests.isNotEmpty) {
      final totalSeconds = allRequests.fold<int>(0, (sum, req) {
        final approveDateTime = DateTime.parse(req.approveDate!);
        return sum + approveDateTime.difference(req.requestDate).inSeconds;
      });

      final avgSeconds = totalSeconds / allRequests.length;
      avgDuration = Duration(seconds: avgSeconds.round());

      print('Average: ${avgDuration.inHours}h ${avgDuration.inMinutes.remainder(60)}m');
    }

    final totalRequests = pendingInRange.length + approvedInRange.length + rejectedInRange.length;
    final totalPending = pendingInRange.length;

    // Calculate average pending duration for currently pending requests
    double avgCurrentPendingDuration = 0.0;
    if (pendingInRange.isNotEmpty) {
      final now = DateTime.now();
      final totalDays = pendingInRange.fold<int>(0, (sum, req) {
        return sum + now.difference(req.requestDate).inDays;
      });
      avgCurrentPendingDuration = totalDays / pendingInRange.length;
    }

    // Calculate average processing duration for approved requests
    double avgApprovedDuration = 0.0;
    if (approvedInRange.isNotEmpty) {
      int totalApprovedDays = 0;
      int validApprovedCount = 0;

      for (var req in approvedInRange) {
        if (req.approveDate != null && req.approveDate!.isNotEmpty) {
          try {
            final approveDateTime = DateTime.parse(req.approveDate!);
            final duration = approveDateTime.difference(req.requestDate).inDays;
            totalApprovedDays += duration;
            validApprovedCount++;
          } catch (e) {
            print("Error parsing approve date: ${req.approveDate}");
          }
        }
      }

      if (validApprovedCount > 0) {
        avgApprovedDuration = totalApprovedDays / validApprovedCount;
      }
    }

    // Calculate overall average (combining approved and current pending)
    double overallAvgDuration = 0.0;
    int totalWithDuration = 0;
    double totalDurationSum = 0.0;

    // Add approved durations
    for (var req in approvedInRange) {
      if (req.approveDate != null && req.approveDate!.isNotEmpty) {
        try {
          final approveDateTime = DateTime.parse(req.approveDate!);
          final duration = approveDateTime.difference(req.requestDate).inDays;
          totalDurationSum += duration;
          totalWithDuration++;
        } catch (e) {
          print("Error parsing approve date: ${req.approveDate}");
        }
      }
    }

    // Add current pending durations
    final now = DateTime.now();
    for (var req in pendingInRange) {
      final duration = now.difference(req.requestDate).inDays;
      totalDurationSum += duration;
      totalWithDuration++;
    }

    if (totalWithDuration > 0) {
      overallAvgDuration = totalDurationSum / totalWithDuration;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildMetricRow("Total Requests Received:", "$totalRequests"),
        const SizedBox(height: 4),
        _buildMetricRow("Total Approved:", "${approvedInRange.length}"),
        const SizedBox(height: 4),
        _buildMetricRow("Total Rejected:", "${rejectedInRange.length}"),
        const SizedBox(height: 4),
        _buildMetricRow("Total Pending Requests:", "$totalPending"),
        const SizedBox(height: 4),
        _buildMetricRow(
            "Average Processing Duration (Approved / Reject):",
            avgDuration.inSeconds > 0
                ? "${avgDuration.inHours} hours"
                : "N/A"
        ),

        // Show pending requests details if any exist
        if (pendingInRange.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            "Pending Requests Details:",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildPendingRequestsTable(pendingInRange),
        ],
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.pink
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }


  Widget _buildPendingRequestsTable(List<CollaborationRequest> requests) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: const [
            _TableCell(text: "Center Name", isHeader: true),
            _TableCell(text: "Request Date", isHeader: true),
            _TableCell(text: "Days Pending", isHeader: true),
          ],
        ),
        ...requests.map((req) {
          final daysPending = DateTime.now().difference(req.requestDate).inDays;
          final formattedDate = "${req.requestDate.day}/${req.requestDate.month}/${req.requestDate.year}";

          return TableRow(
            children: [
              _TableCell(text: req.centerName),
              _TableCell(text: formattedDate),
              _TableCell(text: "$daysPending days"),
            ],
          );
        }).toList(),
      ],
    );
  }
}

// Helper widget for table cells
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TableCell({
    required this.text,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
      ),
    );
  }
}
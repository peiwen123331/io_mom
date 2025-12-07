import 'package:flutter/material.dart';
import 'admin_report_detail_page.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final List<String> reportTypes = [
    "User Management Summary Report",
    "Confinement Center Summary Report",
  ];

  final List<String> reportTimes = ["Q1", "Q2", "Q3", "Q4"];

  String? selectedReportType;
  String? selectedReportTime;

  // Convert quarter to start and end ISO date string
  Map<String, String> getQuarterDateRange(String quarter) {
    final year = DateTime.now().year; // you can change to selected year later

    switch (quarter) {
      case "Q1":
        return {
          "start": "$year-01-01T00:00:00.000000",
          "end": "$year-03-31T23:59:59.999999"
        };
      case "Q2":
        return {
          "start": "$year-04-01T00:00:00.000000",
          "end": "$year-06-30T23:59:59.999999"
        };
      case "Q3":
        return {
          "start": "$year-07-01T00:00:00.000000",
          "end": "$year-09-30T23:59:59.999999"
        };
      case "Q4":
        return {
          "start": "$year-10-01T00:00:00.000000",
          "end": "$year-12-31T23:59:59.999999"
        };
      default:
        return {"start": "", "end": ""};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report Type",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedReportType,
              hint: const Text("Select Report Type"),
              isExpanded: true, // This is the key fix!
              items: reportTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    overflow: TextOverflow.ellipsis, // Truncate if still too long
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReportType = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Report Time",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedReportTime,
              hint: const Text("Select Quarter"),
              isExpanded: true, // Add this for consistency
              items: reportTimes.map((quarter) {
                return DropdownMenuItem(
                  value: quarter,
                  child: Text(quarter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReportTime = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedReportType == null ||
                      selectedReportTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select all fields")),
                    );
                    return;
                  }

                  // Convert quarter → startDate & endDate
                  final range = getQuarterDateRange(selectedReportTime!);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailPage(
                        startDate: range["start"]!,
                        endDate: range["end"]!,
                        reportType: selectedReportType!,
                      ),
                    ),
                  );
                },
                child: const Text("Generate Report"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
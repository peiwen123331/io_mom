import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:io_mom/booking.dart';
import 'package:io_mom/package.dart';
import 'confinement_center.dart';
import 'confinement_center_page.dart';
import 'database.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final dbService = DatabaseService();
  List<Booking> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = await prefs.getString('userID');
      if (uid == null) return;
      final userBookings = await dbService.getBookingByUserID(uid);
      setState(() {
        bookings = userBookings!;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching bookings: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Booking History",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=> ConfinementCenterPage()
          )),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      )
          : bookings.isEmpty
          ? Center(
        child: Text(
          "No bookings found.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return FutureBuilder(
            future: _getBookingDetails(booking),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Colors.pinkAccent)),
                );
              }

              final details = snapshot.data!;
              final package = details['package'] as Package;
              final center = details['center'] as ConfinementCenter;

              return _buildBookingCard(booking, package, center);
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getBookingDetails(Booking booking) async {
    final package =
    await dbService.getPackageByPackageID(booking.PackageID);
    final center =
    await dbService.getConfinementByCenterID(package!.CenterID);
    return {'package': package, 'center': center};
  }

  Widget _buildBookingCard(
      Booking booking, Package package, ConfinementCenter center) {
    final formatter = DateFormat('dd MMM yyyy');
    final checkOut = booking.checkInDate.add(Duration(days: package.duration));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              center.CenterName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.packageName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 20),
            _infoRow("Booking ID", booking.BookingID),
            _infoRow("Check-In", formatter.format(booking.checkInDate)),
            _infoRow("Check-Out", formatter.format(checkOut)),
            _infoRow(
                "Amount", "RM ${booking.payAmount.toStringAsFixed(2)}"),
           _infoRow("Payment", 'Paid'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Booked on ${formatter.format(booking.bookingDate)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text("$title:",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: Colors.grey[800]))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(color: Colors.black))),
        ],
      ),
    );
  }
}

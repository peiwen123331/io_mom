import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/smtp_service.dart';
import 'booking.dart';
import 'package.dart';
import 'package_images.dart';
import 'user.dart';

class CcBookingDetailPage extends StatefulWidget {
  final String bookingID;

  const CcBookingDetailPage({super.key, required this.bookingID});

  @override
  _CcBookingDetailPageState createState() => _CcBookingDetailPageState();
}

class _CcBookingDetailPageState extends State<CcBookingDetailPage> {
  Users? user;
  Package? package;
  List<PackageImages>? imgList;
  Booking? booking;
  bool loading = true;

  final DatabaseService db = DatabaseService();
  final df = DateFormat("dd MMM yyyy");

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final currentBooking = await dbService.getBookingByBookingID(widget.bookingID);
    final userData = await db.getUserByUID(currentBooking!.userID);
    final packageData = await db.getPackageByPackageID(currentBooking.PackageID);
    final images = await db.getPackageImagesByPackageID(currentBooking.PackageID);

    setState(() {
      booking = currentBooking;
      user = userData;
      package = packageData;
      imgList = images;
      loading = false;
    });
  }

  /// IMAGE LOADER
  Widget loadImage() {
    // 1. Use image from Firestore (phone storage path)
    if (imgList != null && imgList!.isNotEmpty) {
      String path = imgList!.first.packageImgPath;

      // network
      if (path.startsWith("http")) {
        return Image.network(path,
            height: 200, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackImage());
      }

      // local file
      if (File(path).existsSync()) {
        return Image.file(File(path),
            height: 200, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackImage());
      }else{
        return Image.asset(path,
            height: 200, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackImage());
      }
    }

    // 2. Default image
    return fallbackImage();
  }

  Widget fallbackImage() {
    return Image.asset(
      "assets/images/confinement_center/CC0002.png",
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  /// CHECK OUT FUNCTION
  Future<void> _checkOut() async {
    if (package == null) return;

    int updatedAvail = package!.availability + 1;

    Package updated = Package(
      PackageID: package!.PackageID,
      CenterID: package!.CenterID,
      packageName: package!.packageName,
      availability: updatedAvail,
      description: package!.description,
      price: package!.price,
      status: package!.status,
      duration: package!.duration,
    );

    Booking editBooking = Booking(
        BookingID: booking!.BookingID,
        bookingDate: booking!.bookingDate,
        checkInDate: booking!.checkInDate,
        payAmount: booking!.payAmount,
        paymentStatus: booking!.paymentStatus,
        userID: booking!.userID,
        PackageID: booking!.PackageID,
        checkOutStatus: 'T',
    );
    await db.editBooking(editBooking);
    await db.editPackage(updated);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Check Out complete. Availability updated."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final checkIn = booking!.checkInDate;
    final checkOut = checkIn.add(Duration(days: package!.duration));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Detail"),
        backgroundColor: Colors.pinkAccent,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== IMAGE =====
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: loadImage(),
            ),

            const SizedBox(height: 20),

            // ===== PACKAGE DETAILS =====
            Text("Package Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),

            const SizedBox(height: 10),
            buildRow("Package Name", package?.packageName),
            buildRow("Price", "RM ${package?.price.toStringAsFixed(2)}"),
            buildRow("Duration", "${package?.duration} days"),

            const SizedBox(height: 20),

            // ===== CUSTOMER DETAILS =====
            Text("Customer Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),

            const SizedBox(height: 10),
            buildRow("Mother Name", user?.userName),
            buildRow("Email", user?.userEmail),
            buildRow("Phone", user?.phoneNo),

            const SizedBox(height: 20),

            // ===== BOOKING DETAILS =====
            Text("Booking",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),

            const SizedBox(height: 10),
            buildRow("Booking ID", booking!.BookingID),
            buildRow("Check In", df.format(checkIn)),
            buildRow("Check Out", df.format(checkOut)),
            booking!.paymentStatus == 'P' ? buildRow("Payment Status", "Paid")
            : buildRow("Payment Status", "Release"),

            const SizedBox(height: 40),

            // ===== CHECK OUT BUTTON =====
            SizedBox(
              width: double.infinity,
              child: booking!.checkOutStatus == 'F' ? ElevatedButton(
                onPressed: _checkOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Check Out",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ) ,
              ) : ElevatedButton(
                  onPressed: (){},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Completed',
                    style: TextStyle(color: Colors.white, fontSize: 16),)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 6, child: Text(value ?? "-")),
        ],
      ),
    );
  }
}

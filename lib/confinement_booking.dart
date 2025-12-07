import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:io_mom/booking.dart';
import 'package:io_mom/smtp_service.dart';
import 'package:pay/pay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booking_history.dart';
import 'package.dart';
import 'user.dart';

class BookingPage extends StatefulWidget {
  final DateTime? checkInDate;
  final String  PackageID;

  const BookingPage({
    super.key,
    required this.checkInDate,
    required this.PackageID,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Users? user;
  Package? package;
  final double taxRate = 0.06;

  bool isPaying = false; // Track progress

  @override
  void initState() {
    super.initState();
    initUserPackage();

  }

  Future<void> initUserPackage() async{
    final prefs = await SharedPreferences.getInstance();
    final uid = await prefs.getString('userID');
    print("user ID: $uid");
    final currentUser = await dbService.getUserByUID(uid!);
    final currentPackage = await dbService.getPackageByPackageID(widget.PackageID);
    setState(() {
      user = currentUser;
      package = currentPackage;
    });
  }

  Future<PaymentConfiguration> _loadDynamicGPayConfig(double totalAmount) async {
    final String configString =
    await rootBundle.loadString('assets/payment_config/gpay.json');
    final Map<String, dynamic> configMap = jsonDecode(configString);

    configMap['data']['transactionInfo'] = {
      "totalPriceStatus": "FINAL",
      "totalPrice": totalAmount.toStringAsFixed(2),
      "currencyCode": "MYR",
      "countryCode": "MY"
    };

    return PaymentConfiguration.fromJsonString(jsonEncode(configMap));
  }

  @override
  Widget build(BuildContext context) {
    // 🩷 Prevent crash while loading data
    if (package == null || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }
    double totalAmount = (package!.price * taxRate) + package!.price;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Postpartum Journey,\nOur Expert Care",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Customer Info
                Text(
                  "Customer Info",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow("Name", user!.userName),
                _infoRow("Contact", user!.phoneNo),
                _infoRow("Email", user!.userEmail),
                const Divider(height: 30, color: Colors.grey),

                // Centre info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        "assets/images/confinement_center/CC0001.jpg",
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gloria Confinement Centre",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Package: 28 Day Plus",
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const Divider(height: 30, color: Colors.grey),

                // Booking Payment Details
                Text(
                  "Booking Payment Details",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                _infoRow("Booking Date", "${DateTime.now()}"),
                _infoRow("Check In Date", "${widget.checkInDate}"),
                _infoRow("Check Out Date", "${widget.checkInDate?.add(Duration(days: package!.duration))}"),
                const Divider(height: 30, color: Colors.grey),

                // Payment summary
                _priceRow("Order Amounts",
                    "RM ${package!.price.toStringAsFixed(2)}", Colors.pinkAccent),
                _priceRow("Tax Amount (10%)",
                    "RM ${(package!.price * taxRate).toStringAsFixed(2)}", Colors.pinkAccent),
                const SizedBox(height: 5),
                _priceRow("Order Total",
                    "RM ${totalAmount.toStringAsFixed(2)}", Colors.black,
                    bold: true),
                const SizedBox(height: 70),

                // Google Pay button (no internal spinner)
                FutureBuilder<PaymentConfiguration>(
                  future: _loadDynamicGPayConfig(totalAmount),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Still loading
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Center(
                          child: Text(
                            "Loading Google Pay...",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      // Handle file load or JSON error
                      return Text(
                        "Failed to load Google Pay config",
                        style: GoogleFonts.poppins(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData) {
                      // Just in case
                      return Text(
                        "No configuration available",
                        style: GoogleFonts.poppins(color: Colors.red),
                      );
                    }

                    // ✅ Safe to use snapshot.data! here
                    return Opacity(
                      opacity: isPaying ? 0.5 : 1.0,
                      child: AbsorbPointer(
                        absorbing: isPaying,
                        child: Center(
                          child: Container(
                            width: double.infinity, // same width as payment button
                            decoration: BoxDecoration(
                              color: Colors.white, // white background
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: GooglePayButton(
                              paymentConfiguration: snapshot.data!,
                              paymentItems: [
                                PaymentItem(
                                  label: 'Total',
                                  amount: totalAmount.toStringAsFixed(2),
                                  status: PaymentItemStatus.final_price,
                                ),
                              ],
                              type: GooglePayButtonType.pay,
                              width: double.infinity, // stretch inside container
                              margin: EdgeInsets.zero, // remove inner margin
                              onPaymentResult: (result) async {

                                setState(() => isPaying = true);
                                debugPrint('Payment Result: $result');

                                await Future.delayed(const Duration(seconds: 2));
                                final bookID = await dbService.generateBookingID();

                                final booking = Booking(
                                    BookingID: bookID,
                                    bookingDate: DateTime.now(),
                                    checkInDate: widget.checkInDate!,
                                    payAmount: totalAmount,
                                    paymentStatus: 'P',
                                    userID: user!.userID,
                                    PackageID: widget.PackageID,
                                    checkOutStatus: 'F',
                                );
                                await dbService.insertBooking(booking);
                                await sendBookingConfirmationEmail(booking);
                                package!.availability  -= 1;
                                await dbService.editPackage(package!);
                                setState(() => isPaying = false);
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookingHistoryPage()),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Manual Pay button
                /*SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Manual payment process started')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Payment",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),*/
              ],
            ),
          ),

          // Custom overlay loader
          if (isPaying)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.pinkAccent,
                  strokeWidth: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text("$title :",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Expanded(
              child: Text(value?? 'Unknown',
                  style: GoogleFonts.poppins(color: Colors.pinkAccent))),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

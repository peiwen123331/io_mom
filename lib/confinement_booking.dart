import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
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
            _infoRow("Name", "Kelly Yu Wen Wen"),
            _infoRow("Contact", "+60 12 345 6789"),
            _infoRow("Email", "kelly@gmail.com"),
            const Divider(height: 30, color: Colors.grey),

            // Centre info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/room.jpg", // Replace with your image asset
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
            _infoRow("Booking Date", "01 January 2025"),
            _infoRow("Check In Date", "02 January 2025"),
            _infoRow("Check Out Date", "30 January 2025"),
            const Divider(height: 30, color: Colors.grey),

            // Payment summary
            _priceRow("Order Amounts", "RM 6,500.00", Colors.pinkAccent),
            _priceRow("Tax Amount (10%)", "RM 70.00", Colors.pinkAccent),
            const SizedBox(height: 5),
            _priceRow("Order Total", "RM 6,570.00", Colors.black, bold: true),
            const SizedBox(height: 20),

            // Google Pay section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Image.asset("assets/google_pay.png", width: 35), // your GPay icon
                  const SizedBox(width: 10),
                  Text(
                    "Google Pay",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    "Proceed to Payment",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
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
          SizedBox(width: 100, child: Text("$title :", style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(color: Colors.pinkAccent))),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, Color color, {bool bold = false}) {
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

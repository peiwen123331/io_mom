import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageDetailPage extends StatefulWidget {
  const PackageDetailPage({Key? key}) : super(key: key);

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  int currentIndex = 0;
  String selectedPackage = "Plus";
  DateTime? selectedDate;

  final List<String> images = [
    'assets/images/gloria1.jpg',
    'assets/images/gloria2.jpg',
    'assets/images/gloria3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Package",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Carousel
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentIndex == index ? 10 : 6,
                          height: currentIndex == index ? 10 : 6,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? Colors.pinkAccent
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📦 Package Duration
            const Text(
              "Package: 28 Days",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 💖 Package Selection Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["Normal", "Plus", "Premium"].map((type) {
                final isSelected = selectedPackage == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.pinkAccent.withOpacity(0.1)
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.pinkAccent
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setState(() => selectedPackage = type),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.pinkAccent : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 📅 Check-In Date Picker
            const Text(
              "Check In Date:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2025, 1, 1),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate != null
                          ? DateFormat('EEEE, d MMMM yyyy')
                          .format(selectedDate!)
                          : "Wednesday, 1 January 2025",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.pinkAccent, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🏠 Center Name & Price
            const Text(
              "Gloria Confinement Centre",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Text(
                  "RM 7000.00",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  "RM 6500.00",
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📋 Package Details
            const Text(
              "Package Details",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Mother Care\n",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text:
                    "- Daily traditional postnatal massage (7 sessions)\n- Herbal bath & feminine wash\n- Balanced confinement meals (5 meals/day)\n\n",
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  TextSpan(
                    text: "Newborn Care\n",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextSpan(
                    text:
                    "- 24/7 care by trained nurses\n- Daily baby bath, diapering, and swaddling\n- Regular temperature and health monitoring\n",
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🩷 Booking Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Handle booking logic here
                },
                child: const Text(
                  "Booking",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

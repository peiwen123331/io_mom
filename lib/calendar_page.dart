import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'custom_bottom.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime(2020, 11, 12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Calendar",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.pink),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 💖 Month + Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.arrow_back_ios, size: 18),
                Text(
                  "12 Nov 2020",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink),
                ),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            const SizedBox(height: 10),

            // 🗓️ Week Labels
            Table(
              children: const [
                TableRow(
                  children: [
                    Center(child: Text("M")),
                    Center(child: Text("T")),
                    Center(child: Text("W")),
                    Center(child: Text("T")),
                    Center(child: Text("F")),
                    Center(child: Text("S")),
                    Center(child: Text("S")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 📆 Calendar Days (Static Example)
            Expanded(
              child: Table(
                children: [
                  for (int i = 0; i < 4; i++)
                    TableRow(
                      children: [
                        for (int j = 0; j < 7; j++)
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(12),
                              decoration: (i == 2 && j == 2)
                                  ? const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              )
                                  : null,
                              child: Center(
                                child: Text(
                                  "${(i * 7) + j + 1}",
                                  style: TextStyle(
                                    color: (i == 2 && j == 2)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // 📝 Reminder Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.grey.shade300,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reminder",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildReminder("10:00 am - Vitamin B (Dosage: 1)", true),
                  _buildReminder("14:00 pm - Pregnancy Check-up", false),
                  _buildReminder("16:00 pm - Relaxation Activity", false),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildReminder(String text, bool taken) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(radius: 5, backgroundColor: Colors.pink),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          if (taken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Taken",
                style: TextStyle(fontSize: 12, color: Colors.pink),
              ),
            ),
        ],
      ),
    );
  }
}

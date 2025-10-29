// calendar_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';


// import your models and database service
import 'mood.dart';
import 'medication_reminder.dart';
import 'milestone_reminder.dart';
import 'database.dart'; // adjust path
import 'custom_drawer.dart';
import 'custom_bottom.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime today = DateTime.now();
  final dbService = DatabaseService(); // wrap your DB methods in this (or adapt)
  List<Appointment> _appointments = [];
  late MeetingDataSource _events;
  bool _loading = true;

  // local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _events = MeetingDataSource(_appointments);
    _initializeNotifications();
    _loadAllReminders();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Called when notification tapped (optional)
  void _onNotificationTap(NotificationResponse response) {
    // You can navigate to app or show details — left simple for now
    // payload could include type:id to open detail
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _loadAllReminders() async {
    setState(() => _loading = true);
    _appointments.clear();

    final prefs = await SharedPreferences.getInstance();
    final String? currentUserId = prefs.getString("userID");

    // 1) Load moods
    final moods = await dbService.getMoodByUserID(currentUserId!) ?? [];
    for (final m in moods) {
      final appt = Appointment(
        startTime: DateTime(m.MoodDate.year, m.MoodDate.month, m.MoodDate.day),
        endTime: DateTime(m.MoodDate.year, m.MoodDate.month, m.MoodDate.day).add(const Duration(hours: 1)),
        subject: 'Mood: ${m.MoodStatus}',
        notes: m.MoodDesc,
        color: Colors.pink,
        id: 'mood_${m.MoodID}',
        isAllDay: false,
      );
      _appointments.add(appt);
    }

    // 2) Load milestone reminders
    final milestones = await dbService.getMilReminderByUserID(currentUserId) ?? [];
    for (final ms in milestones) {
      final appt = Appointment(
        startTime: ms.startDate,
        endTime: ms.endDate ?? ms.startDate.add(const Duration(hours: 1)),
        subject: 'Milestone: ${ms.mileStoneName}',
        notes: ms.description,
        color: Colors.orange,
        id: 'mil_${ms.milReminderID}',
        isAllDay: true,
      );
      _appointments.add(appt);

      // schedule 1-day-before notification
      _scheduleMilestoneReminder(ms);
    }

    // 3) Load medication reminders
    final meds = await dbService.getMedReminderByUserID(currentUserId) ?? [];
    for (final med in meds) {
      // show a single appointment at startTime (you could expand to multiple per frequency)
      final appt = Appointment(
        startTime: med.startTime,
        endTime: med.startTime.add(const Duration(minutes: 30)),
        subject: 'Med: ${med.medicationName}',
        notes: 'Dosage: ${med.dosage} — frequency: ${med.frequency}/day',
        color: Colors.green,
        id: 'med_${med.medReminderID}',
        isAllDay: false,
      );
      _appointments.add(appt);
      _scheduleMedicationReminders(med);
    }

    setState(() {
      _events = MeetingDataSource(_appointments);
      _loading = false;
    });
  }

  // Schedules a milestone reminder 1 day before startDate at 9:00 AM (example)
  Future<void> _scheduleMilestoneReminder(MilestoneReminder ms) async {
    final notifyTime = ms.startDate.subtract(const Duration(days: 1)).subtract(Duration(
        hours: ms.startDate.hour - 9)); // attempt to schedule at 9AM previous day
    if (notifyTime.isAfter(DateTime.now())) {
      final id = _generateNotificationId('mil', ms.milReminderID);
      await _showNotificationAt(
          id,
          'Upcoming milestone: ${ms.mileStoneName}',
          'Reminder: ${ms.mileStoneName} happens on ${DateFormat.yMMMd().format(ms.startDate)}',
          notifyTime,
          payload: 'mil:${ms.milReminderID}');
    }
  }

  // Schedule medication notifications according to frequency and repeatDuration type
  Future<void> _scheduleMedicationReminders(MedicationReminder med) async {
    // If repeatDuration -> we expect 0=daily,1=weekly or adjust based on your model
    // Here: repeatDuration: 1 => daily, 7 => weekly (we'll treat as days)
    // For clarity: we'll create notifications for the next 14 occurrences (simple approach)

    final int occurrences = 14;
    final Duration repeatInterval = med.repeatDuration == 1
        ? const Duration(days: 1)
        : const Duration(days: 7); // daily or weekly
    final start = med.startTime;

    // For each day/week, schedule notification multiple times per frequency
    for (int i = 0; i < occurrences; i++) {
      final occurrenceBase = start.add(repeatInterval * i);

      // spread frequency times across the day starting at start.hour
      // e.g., if frequency=2, notifications at start.hour and start.hour + (12 hours)
      for (int j = 0; j < med.frequency; j++) {
        final hourOffset = (24 / med.frequency) * j;
        final scheduled = DateTime(
            occurrenceBase.year,
            occurrenceBase.month,
            occurrenceBase.day,
            start.hour,
            start.minute)
            .add(Duration(hours: hourOffset.round()));

        if (scheduled.isAfter(DateTime.now())) {
          final nid = _generateNotificationId('med', med.medReminderID, suffix: '${i}_$j');
          await _showNotificationAt(
              nid,
              'Medication: ${med.medicationName}',
              'Time to take ${med.medicationName} (${med.dosage})',
              scheduled,
              payload: 'med:${med.medReminderID}');
        }
      }
    }
  }

  // helper to generate numeric notification ids (flutter_local_notifications needs int id)
  int _generateNotificationId(String prefix, String id, {String? suffix}) {
    final composite = '$prefix-$id${suffix != null ? '-$suffix' : ''}';
    // simple hash to int (not cryptographic)
    return composite.hashCode & 0x7fffffff;
  }

  Future<void> _showNotificationAt(
      int id,
      String title,
      String body,
      DateTime dt, {
        String? payload,
      }) async {
    // Make sure timezone package is initialized before using tz
    tz.initializeTimeZones();

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Reminder notifications for milestones and medications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // notification ID
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );
  }


  // Add, Edit and Delete flows
  Future<void> _showCreateChoice(DateTime date) async {
    // simple bottom sheet to let user choose which type to add (Mood/Milestone/Medication)
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Add Mood'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditMood(date: date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Add Milestone'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditMilestone(date: date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.medication),
                title: const Text('Add Medication Reminder'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditMedication(date: date);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEditMood({Mood? mood, DateTime? date}) async {
    final TextEditingController descC = TextEditingController(text: mood?.MoodDesc ?? '');
    final TextEditingController statusC = TextEditingController(text: mood?.MoodStatus ?? '');
    DateTime selectedDate = mood?.MoodDate ?? (date ?? DateTime.now());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mood == null ? 'Add Mood' : 'Edit Mood'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: statusC, decoration: const InputDecoration(labelText: 'Status')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextButton(
                child: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => selectedDate = d);
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = mood?.MoodID ?? const Uuid().v4();
              final newMood = Mood(
                MoodID: id,
                MoodDesc: descC.text,
                MoodDate: selectedDate,
                MoodStatus: statusC.text,
                userID: 'demo_user', // replace
                MoodTypeID: 'default',
              );
              if (mood == null) {
                await dbService.insertMood(newMood);
              } else {
                await dbService.editMood(newMood);
              }
              await _loadAllReminders();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _showAddEditMilestone({MilestoneReminder? milestone, DateTime? date}) async {
    final TextEditingController titleC = TextEditingController(text: milestone?.mileStoneName ?? '');
    final TextEditingController descC = TextEditingController(text: milestone?.description ?? '');
    DateTime startDate = milestone?.startDate ?? (date ?? DateTime.now());
    DateTime endDate = milestone?.endDate ?? (date ?? DateTime.now()).add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(milestone == null ? 'Add Milestone' : 'Edit Milestone'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) setState(() => startDate = d);
                  },
                  child: Text('Start: ${DateFormat.yMMMd().format(startDate)}')),
              TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) setState(() => endDate = d);
                  },
                  child: Text('End: ${DateFormat.yMMMd().format(endDate)}')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = milestone?.milReminderID ?? const Uuid().v4();
              final newMil = MilestoneReminder(
                milReminderID: id,
                mileStoneName: titleC.text,
                description: descC.text,
                startDate: startDate,
                endDate: endDate,
                userID: 'demo_user',
              );
              if (milestone == null) {
                await dbService.insertMilReminder(newMil);
              } else {
                await dbService.editMilReminder(newMil);
              }
              await _loadAllReminders();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _showAddEditMedication({MedicationReminder? medication, DateTime? date}) async {
    final TextEditingController nameC = TextEditingController(text: medication?.medicationName ?? '');
    final TextEditingController dosageC = TextEditingController(text: medication?.dosage.toString() ?? '');
    final TextEditingController freqC = TextEditingController(text: medication?.frequency.toString() ?? '1');
    int repeatType = medication?.repeatDuration ?? 1; // 1=daily,7=weekly in our code, adjust as needed
    DateTime start = medication?.startTime ?? (date ?? DateTime.now());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(medication == null ? 'Add Medication' : 'Edit Medication'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: dosageC, decoration: const InputDecoration(labelText: 'Dosage (e.g., 0.5)'), keyboardType: TextInputType.number),
              TextField(controller: freqC, decoration: const InputDecoration(labelText: 'Frequency per day'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: repeatType,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Daily')),
                  DropdownMenuItem(value: 7, child: Text('Weekly')),
                ],
                onChanged: (v) => setState(() => repeatType = v ?? 1),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setState(() => start = d);
                },
                child: Text('Start: ${DateFormat.yMMMd().format(start)}'),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = medication?.medReminderID ?? const Uuid().v4();
              final newMed = MedicationReminder(
                medReminderID: id,
                medicationName: nameC.text,
                dosage: double.tryParse(dosageC.text) ?? 0.0,
                frequency: int.tryParse(freqC.text) ?? 1,
                repeatDuration: repeatType,
                startTime: start,
                lastConfirmedDate: medication?.lastConfirmedDate,
                userID: 'demo_user',
              );
              if (medication == null) {
                await dbService.insertMedReminder(newMed);
              } else {
                await dbService.editMedReminder(newMed);
              }
              await _loadAllReminders();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // handle tapping appointment or empty cell
  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      // empty day cell tapped
      final DateTime date = details.date ?? DateTime.now();
      _showCreateChoice(date);
    } else if (details.targetElement == CalendarElement.appointment && details.appointments != null && details.appointments!.isNotEmpty) {
      final Appointment appt = details.appointments!.first;
      _showAppointmentDetails(appt);
    }
  }

  Future<void> _showAppointmentDetails(Appointment appt) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(title: Text(appt.subject ?? 'No title'), subtitle: Text(appt.notes ?? '')),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _editAppointment(appt);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteAppointment(appt);
                },
              ),
              if ((appt.id as String).startsWith('med_'))
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Confirm dose taken'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _confirmMedicationDose(appt);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editAppointment(Appointment appt) async {
    final String id = (appt.id ?? '').toString();
    if (id.startsWith('mood_')) {
      final moodId = id.replaceFirst('mood_', '');
      // retrieve mood object: you may need to adapt to your DB design to get specific mood
      // fallback: open add dialog with date filled
      await _showAddEditMood(date: appt.startTime);
    } else if (id.startsWith('mil_')) {
      await _showAddEditMilestone(date: appt.startTime);
    } else if (id.startsWith('med_')) {
      await _showAddEditMedication(date: appt.startTime);
    }
  }

  Future<void> _deleteAppointment(Appointment appt) async {
    final String id = (appt.id ?? '').toString();
    if (id.startsWith('MD')) {
      final moodId = id.replaceFirst('MD', '');
      // call your DB to delete mood. You don't have a delete method in posted DB; implement one.
      await dbService.deleteMoodById(moodId);
    } else if (id.startsWith('MIL')) {
      final milId = id.replaceFirst('MIL', '');
      await dbService.deleteMilReminderById(milId);
    } else if (id.startsWith('MED')) {
      final medId = id.replaceFirst('MED', '');
      await dbService.deleteMedReminderById(medId);
      // optionally cancel notifications for that med id
      // We used hashed ids; can't cancel all of them easily without tracking; you may want to store scheduled notification ids in Firestore
    }
    await _loadAllReminders();
  }

  Future<void> _confirmMedicationDose(Appointment appt) async {
    final medId = (appt.id ?? '').toString().replaceFirst('MED', '');
    final medReminder = await dbService.getMedReminderByMedReminderID(medId);
    medReminder!.lastConfirmedDate = DateTime.now();
    // update lastConfirmedDate in firestore for that med record
    await dbService.editMedReminder(medReminder!);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dose confirmed')));
    await _loadAllReminders();
  }

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
            onPressed: () => _showCreateChoice(DateTime.now()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
        view: CalendarView.month,
        initialSelectedDate: DateTime.now(),
        dataSource: _events,
        onTap: _onCalendarTap,
        monthViewSettings: MonthViewSettings(showAgenda: true),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }
}

// DataSource for Syncfusion calendar
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:io_mom/linked_account.dart';
import 'package:io_mom/mood_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import 'linked_account_page.dart';
import 'mood.dart';
import 'medication_reminder.dart';
import 'milestone_reminder.dart';
import 'database.dart';
import 'custom_drawer.dart';
import 'custom_bottom.dart';
import 'user.dart';

class CalendarPage extends StatefulWidget {
  final String isFrom;

  const CalendarPage({super.key, required this.isFrom});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final dbService = DatabaseService();
  List<Appointment> _appointments = [];
  late MeetingDataSource _events;
  bool _loading = true;
  Users? user;
  List<MoodType>? moodEmoji;

  // ✅ Variables for FC data access control
  LinkedAccount? linkedAccount;
  bool canViewMoodData = true; // Default true for regular users
  String targetUserID = ''; // The user whose data we're viewing
  bool isFCUser = false; // Track if current user is FC
  bool isLinkedToMainUser = false; // ✅ Track if FC has linked account
  static bool _tzInitialized = false;

  // Notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initUser();
    await _checkDataAccessPermissions();
    await initMoodType();
    await _initializeNotifications();

    // ✅ Only load reminders if user is linked (for FC) or is a regular user
    if (!isFCUser || isLinkedToMainUser) {
      await _loadAllReminders();
    }

    setState(() {
      _events = MeetingDataSource(_appointments);
      _loading = false;
    });
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString("userID");
    if (userID == null) return;
    final users = await dbService.getUserByUID(userID);

    setState(() {
      user = users;
      targetUserID = userID; // Default to own user ID
      isFCUser = users?.userRole == 'FC'; // ✅ Track FC status
    });
  }

  // ✅ UPDATED: Check all data access permissions for FC users
  Future<void> _checkDataAccessPermissions() async {
    if (user == null) return;

    // Check if user is a Family Caregiver
    if (isFCUser) {
      final linkedAccounts = await dbService.getLinkedAccountByLinkedUserID(
        user!.userID,
      );

      if (linkedAccounts != null && linkedAccounts.isNotEmpty) {
        linkedAccount = linkedAccounts.first;

        setState(() {
          // Check mood data visibility permission
          canViewMoodData = linkedAccount!.moodDataVisibility == 'T';

          // ✅ FC users view main user's data
          targetUserID = linkedAccount!.MainUserID;
          isLinkedToMainUser = true;
        });

        debugPrint(
          "✅ FC User - Target: ${linkedAccount!.MainUserID}, Mood Visibility: ${linkedAccount!.moodDataVisibility}",
        );
      } else {
        // ✅ FC user has no linked account
        setState(() {
          isLinkedToMainUser = false;
          canViewMoodData = false;
        });
        debugPrint("⚠️ FC User has no linked account");
      }
    } else {
      // Regular user (P) - can always view their own data
      setState(() {
        canViewMoodData = true;
        targetUserID = user!.userID;
        isLinkedToMainUser = true; // Not applicable but set to true for logic
      });
    }
  }

  Future<void> initMoodType() async {
    final moodType = await dbService.getAllMoodType();
    if (moodType == null) return;
    setState(() {
      moodEmoji = moodType;
    });
  }



  Future<void> _debugPendingNotifications() async {
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();

      debugPrint('📋 PENDING NOTIFICATIONS: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        debugPrint('  ID: ${notification.id}');
        debugPrint('  Title: ${notification.title}');
        debugPrint('  Body: ${notification.body}');
        debugPrint('  Payload: ${notification.payload}');
        debugPrint('  ---');
      }

      if (pendingNotifications.isEmpty) {
        debugPrint('⚠️ NO PENDING NOTIFICATIONS FOUND!');
      }
    } catch (e) {
      debugPrint('❌ Error checking pending notifications: $e');
    }
  }
// REPLACE your _initializeNotifications method with this improved version
  Future<void> _initializeNotifications() async {
    debugPrint('🔔 Starting notification initialization...');

    // 1. Initialize timezone FIRST
    if (!_tzInitialized) {
      try {
        tzData.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
        _tzInitialized = true;
        debugPrint('✅ Timezone initialized: ${tz.local.name}');
      } catch (e) {
        debugPrint('❌ Timezone initialization failed: $e');
        return;
      }
    }

    // 2. Initialize plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    final initialized = await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    debugPrint('Plugin initialized: $initialized');

    // 3. Create notification channel
    const channel = AndroidNotificationChannel(
      'reminder_channel_id',
      'Reminders',
      description: 'Notifications for milestones and medications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created');
      } else {
        debugPrint('❌ Android plugin is null');
      }
    } catch (e) {
      debugPrint('❌ Failed to create notification channel: $e');
    }

    // 4. Check notification permission
    final notifStatus = await Permission.notification.status;
    debugPrint('📱 Notification permission: $notifStatus');

    if (notifStatus.isDenied) {
      final result = await Permission.notification.request();
      debugPrint('📱 Permission request result: $result');

      if (!result.isGranted) {
        debugPrint('❌ Notification permission denied!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification permission is required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }

    // 5. Check exact alarm permission
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    debugPrint('⏰ Exact alarm permission: $alarmStatus');

    if (!alarmStatus.isGranted) {
      if (mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'This app needs permission to schedule exact alarms for reminders.\n\n'
                  'Please enable "Alarms & reminders" in the next screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          await openAppSettings();
        }
      }
    }

    // 6. Device time debug info
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    debugPrint('🕐 Device DateTime.now(): $now');
    debugPrint('🕐 TZ DateTime.now(): $tzNow');
    debugPrint('🕐 Timezone offset: ${now.timeZoneOffset}');

    debugPrint('✅ Notification initialization complete');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can navigate or handle payload here if needed
  }

  bool validateMoodDate(DateTime selectedDate) {
    final today = DateTime.now();

    // Remove time portion to compare only dates
    final nowDate = DateTime(today.year, today.month, today.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selected.isBefore(nowDate)) {
      return false; // Invalid
    }
    return true;
  }

  bool validateMilestoneDates(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);

    if (s.isBefore(today)) {
      return false; // Start < today
    }
    if (e.isBefore(s)) {
      return false; // End < Start
    }

    return true;
  }

  bool validateMedicationDateTime(
      DateTime selectedDate,
      TimeOfDay selectedTime,
      ) {
    final now = DateTime.now();

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    return !selectedDateTime.isBefore(now);
  }

  Future<void> _loadAllReminders() async {
    setState(() => _loading = true);
    _appointments.clear();

    // ✅ MOOD DATA: Only load if user has permission
    if (canViewMoodData) {
      final moods = await dbService.getMoodByUserID(targetUserID) ?? [];
      for (final m in moods) {
        var MoodName = '';
        for (var moodType in moodEmoji!) {
          if (moodType.MoodTypeID == m.MoodTypeID) {
            MoodName = moodType.MoodTypeName;
          }
        }
        _appointments.add(
          Appointment(
            startTime: m.MoodDate,
            endTime: m.MoodDate,
            subject: 'Mood: $MoodName',
            notes: m.MoodDesc,
            color: Colors.pink,
            isAllDay: true,
            id: 'mood_${m.MoodID}',
          ),
        );
      }
    } else {
      debugPrint("⚠️ Mood data hidden - moodDataVisibility is 'F'");
    }

    // ✅ MILESTONE DATA: Load for all users
    final milestones =
        await dbService.getMilReminderByUserID(targetUserID) ?? [];
    debugPrint(
      "📍 Loading ${milestones.length} milestones for user: $targetUserID",
    );
    for (final ms in milestones) {
      _appointments.add(
        Appointment(
          startTime: ms.startDate,
          endTime: ms.endDate,
          subject: 'Milestone: ${ms.mileStoneName}',
          notes: ms.description,
          color: Colors.orange,
          id: 'milestone_${ms.milReminderID}',
        ),
      );
      _scheduleMilestoneReminder(ms);
    }

    // ✅ MEDICATION DATA: Load for all users
    final meds = await dbService.getMedReminderByUserID(targetUserID) ?? [];
    debugPrint("💊 Loading ${meds.length} medications for user: $targetUserID");
    for (final med in meds) {
      if (med.repeatDuration > 1) {
        for (int i = 0; i < med.repeatDuration; i++) {
          var newStartDate = med.startTime.add(Duration(days: i));
          _appointments.add(
            Appointment(
              startTime: newStartDate,
              endTime: newStartDate.add(const Duration(minutes: 30)),
              subject: 'Medication: ${med.medicationName}',
              notes: 'Dosage: ${med.dosage.toStringAsPrecision(2)}',
              color: Colors.green,
              id: 'med_${med.medReminderID}_$i',
            ),
          );
        }
      } else {
        _appointments.add(
          Appointment(
            startTime: med.startTime,
            endTime: med.startTime.add(const Duration(minutes: 30)),
            subject: 'Medication: ${med.medicationName}',
            notes: 'Dosage: ${med.dosage.toStringAsPrecision(2)}',
            color: Colors.green,
            id: 'med_${med.medReminderID}',
          ),
        );
      }

      _scheduleMedicationReminders(med);
    }

    setState(() {
      _events = MeetingDataSource(_appointments);
      _loading = false;
    });
  }

  Future<void> _scheduleMilestoneReminder(MilestoneReminder ms) async {
    final notifyTime = ms.startDate.subtract(const Duration(hours: 1));
    if (notifyTime.isAfter(DateTime.now())) {
      final id = _generateNotificationId('mil', ms.milReminderID);
      final ok = await _showNotificationAt(
        id,
        'Upcoming milestone: ${ms.mileStoneName}',
        'Happens on ${DateFormat.yMMMd().format(ms.startDate)}',
        notifyTime,
        payload: 'mil:${ms.milReminderID}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Milestone reminder scheduled'
                  : 'Failed to schedule milestone reminder',
            ),
            backgroundColor: ok ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Schedule medication reminders (one-off + future occurrences)
  Future<void> _scheduleMedicationReminders(MedicationReminder med) async {
    debugPrint('\n💊 ========== SCHEDULING MEDICATION ==========');
    debugPrint('Medication: ${med.medicationName}');
    debugPrint('Start time: ${med.startTime}');
    debugPrint('Repeat duration: ${med.repeatDuration}');

    final firstTime = med.startTime;
    final repeatType = med.repeatDuration;

    // Schedule first notification
    if (firstTime.isAfter(DateTime.now())) {
      final id = _generateNotificationId('med', med.medReminderID);
      debugPrint('Scheduling first dose (ID: $id)...');

      final ok = await _showNotificationAt(
        id,
        'Medication Reminder',
        'Time to take ${med.medicationName} (${med.dosage})',
        firstTime,
        payload: 'med:${med.medReminderID}',
      );

      // Verify it was scheduled
      final isPending = await _isNotificationPending(id);
      debugPrint('First dose scheduled: $ok, Pending: $isPending');

      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled "${med.medicationName}" at ${DateFormat.yMMMd().add_jm().format(firstTime)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      debugPrint('⚠️ First dose time is in the past, skipping');
    }

    if (repeatType == 0) {
      debugPrint('No repeats configured');
      debugPrint('==========================================\n');
      return;
    }

    // Calculate repeat schedule
    int intervalDays;
    int occurrences;

    if (repeatType == 1) {
      intervalDays = 1;
      occurrences = 30;
    } else if (repeatType == 7) {
      intervalDays = 7;
      occurrences = 12;
    } else if (repeatType == 30) {
      intervalDays = 30;
      occurrences = 12;
    } else if (repeatType == 365) {
      intervalDays = 365;
      occurrences = 3;
    } else if (repeatType > 1) {
      intervalDays = repeatType;
      occurrences = 12;
    } else {
      intervalDays = 1;
      occurrences = 30;
    }

    occurrences = occurrences.clamp(0, 90);
    debugPrint('Scheduling $occurrences repeats, every $intervalDays days');

    int successCount = 0;
    for (int i = 1; i <= occurrences; i++) {
      final next = firstTime.add(Duration(days: intervalDays * i));
      if (next.isAfter(DateTime.now())) {
        final id = _generateNotificationId('med', med.medReminderID, suffix: '$i');
        final ok = await _showNotificationAt(
          id,
          'Medication Reminder',
          'Time to take ${med.medicationName} (${med.dosage})',
          next,
          payload: 'med:${med.medReminderID}',
        );
        if (ok) successCount++;

        // Don't spam logs for every occurrence
        if (i <= 3 || i == occurrences) {
          debugPrint('Repeat $i/${occurrences}: ${ok ? "✅" : "❌"} (${DateFormat.yMMMd().add_jm().format(next)})');
        }
      }
    }


  }


  int _generateNotificationId(String prefix, String id, {String? suffix}) {
    final composite = '$prefix-$id${suffix != null ? '-$suffix' : ''}';
    return composite.hashCode & 0x7fffffff;
  }



  Future<bool> _showNotificationAt(
      int id,
      String title,
      String body,
      DateTime dt, {
        String? payload,
      }) async {
    try {
      debugPrint('\n🔔 ========== SCHEDULING NOTIFICATION ==========');
      debugPrint('ID: $id');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Payload: $payload');

      // Re-initialize timezone if needed
      if (!_tzInitialized || tz.local.name == 'UTC') {
        debugPrint('⚠️ Re-initializing timezone...');
        tzData.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
        _tzInitialized = true;
      }

      // Construct TZDateTime properly
      final scheduledDate = tz.TZDateTime(
        tz.local,
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
      );

      final now = tz.TZDateTime.now(tz.local);
      final difference = scheduledDate.difference(now);

      debugPrint('Current time: $now');
      debugPrint('Scheduled time: $scheduledDate');
      debugPrint('Time until notification: ${difference.inSeconds} seconds (${difference.inMinutes} minutes)');

      // Check if scheduled date is in the past
      if (scheduledDate.isBefore(now)) {
        debugPrint('❌ ERROR: Scheduled time is in the PAST!');
        debugPrint('   Scheduled: $scheduledDate');
        debugPrint('   Current: $now');
        debugPrint('   Difference: ${difference.inSeconds} seconds');
        return false;
      }

      // Check if scheduled time is too far in the future (> 1 year)
      if (difference.inDays > 365) {
        debugPrint('⚠️ WARNING: Notification scheduled more than 1 year in future');
      }

      final androidDetails = AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminders',
        channelDescription: 'Notifications for milestones and medications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(android: androidDetails);

      debugPrint('📤 Calling zonedSchedule...');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint('✅ Notification scheduled successfully!');
      debugPrint('========================================\n');

      // Verify it was scheduled
      await Future.delayed(const Duration(milliseconds: 500));
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final found = pending.any((n) => n.id == id);
      debugPrint('Verification: Notification ID $id ${found ? "FOUND" : "NOT FOUND"} in pending list');

      return true;
    } catch (e, st) {
      debugPrint('❌ ========== NOTIFICATION SCHEDULING FAILED ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $st');
      debugPrint('====================================================\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule notification: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }
  }
  Future<bool> _isNotificationPending(int id) async {
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pending.any((n) => n.id == id);
  }

  Future<void> _testNotificationSystem() async {
    debugPrint('\n🧪 ========== TESTING NOTIFICATION SYSTEM ==========');

    // Test 1: Immediate notification
    debugPrint('Test 1: Sending immediate notification...');
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminders',
        channelDescription: 'Test notification',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      await flutterLocalNotificationsPlugin.show(
        99999,
        'Test: Immediate Notification',
        'If you see this, immediate notifications work!',
        const NotificationDetails(android: androidDetails),
      );
      debugPrint('✅ Immediate notification sent');
    } catch (e) {
      debugPrint('❌ Immediate notification failed: $e');
    }

    // Test 2: Scheduled notification (10 seconds from now)
    debugPrint('Test 2: Scheduling notification for 10 seconds from now...');
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    final success = await _showNotificationAt(
      99998,
      'Test: Scheduled Notification',
      'If you see this, scheduled notifications work!',
      testTime,
      payload: 'test',
    );
    debugPrint('Scheduled notification result: $success');

    // Test 3: Check pending notifications
    await _debugPendingNotifications();

    debugPrint('================================================\n');
  }

  Future<void> _showAddEditMedication({
    MedicationReminder? medication,
    DateTime? date,
  }) async {
    final TextEditingController nameC = TextEditingController(
      text: medication?.medicationName ?? '',
    );
    final TextEditingController dosageC = TextEditingController(
      text: medication?.dosage.toString() ?? '',
    );
    int repeatType = medication?.repeatDuration ?? 0;
    DateTime start = medication?.startTime ?? (date ?? DateTime.now());

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            medication == null
                ? 'Add Medication Reminder'
                : 'Edit Medication Reminder',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                  ),
                ),
                TextField(
                  controller: dosageC,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: repeatType,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Does not repeat')),
                    DropdownMenuItem(value: 1, child: Text('One Day')),
                    DropdownMenuItem(value: 7, child: Text('A Week')),
                    DropdownMenuItem(value: 30, child: Text('A Month')),
                    DropdownMenuItem(value: 365, child: Text('A Year')),
                  ],
                  onChanged: (v) => setDialogState(() => repeatType = v ?? 0),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(start),
                      );
                      if (pickedTime != null) {
                        setDialogState(() {
                          start = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text(
                    'Start: ${DateFormat.yMMMd().add_jm().format(start)}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            /*TextButton(
              onPressed: _testNotificationSystem,
              child: const Text('🧪 Run System Test'),
            ),*/
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a medication name.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final id =
                    medication?.medReminderID ??
                        await dbService.generateMedReminderID();
                // Use targetUserID (MainUserID for FC, own ID for P users)
                final newMed = MedicationReminder(
                  medReminderID: id,
                  medicationName: nameC.text.trim(),
                  dosage: double.tryParse(dosageC.text) ?? 0.0,
                  repeatDuration: repeatType,
                  startTime: start,
                  lastConfirmedDate: medication?.lastConfirmedDate,
                  userID: targetUserID,
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
            ),
          ],
        ),
      ),
    );
  }


  void _onCalendarTap(CalendarTapDetails details) {
    // Block interaction if FC user hasn't linked
    if (isFCUser && !isLinkedToMainUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please link your account to a main user first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (details.targetElement == CalendarElement.calendarCell) {
      _showCreateChoice(details.date!);
    } else if (details.appointments != null &&
        details.appointments!.isNotEmpty) {
      _showAppointmentDetails(details.appointments!.first);
    }
  }

  Future<void> _showCreateChoice(DateTime date) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            // ✅ Only show "Add Mood" for P users (not FC)
            if (!isFCUser)
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Add Mood'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditMood(date: date);
                },
              ),
            // ✅ All users can add milestones
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Add Milestone'),
              onTap: () {
                Navigator.pop(context);
                _showAddEditMilestone(date: date);
              },
            ),
            // ✅ All users can add medications
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
      ),
    );
  }

  // Mood form - P users only
  Future<void> _showAddEditMood({Mood? mood, DateTime? date}) async {
    // ✅ Block FC users completely from mood data
    if (isFCUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family Caregivers cannot add or edit mood data.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController descC = TextEditingController(
      text: mood?.MoodDesc ?? '',
    );
    DateTime selectedDate = mood?.MoodDate ?? (date ?? DateTime.now());
    String? selectedMoodTypeID = mood?.MoodTypeID;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(mood == null ? 'Add Mood' : 'Edit Mood'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Select Mood',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: moodEmoji?.length ?? 0,
                        itemBuilder: (context, index) {
                          final m = moodEmoji![index];
                          final isSelected = selectedMoodTypeID == m.MoodTypeID;

                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedMoodTypeID = m.MoodTypeID;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        m.MoodTypeImg,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    m.MoodTypeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: descC,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setStateDialog(() {
                            selectedDate = d;
                          });
                        }
                      },
                      child: Text(
                        'Date: ${DateFormat.yMMMd().format(selectedDate)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedMoodTypeID == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a mood emoji.'),
                      ),
                    );
                    return;
                  }

                  final id = mood?.MoodID ?? await dbService.generateMoodID();
                  final newMood = Mood(
                    MoodID: id,
                    MoodDesc: descC.text,
                    MoodDate: selectedDate,
                    MoodStatus: 'A',
                    userID: targetUserID,
                    MoodTypeID: selectedMoodTypeID!,
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
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Milestone form - All users can add/edit
  Future<void> _showAddEditMilestone({
    MilestoneReminder? milestone,
    DateTime? date,
  }) async {
    final TextEditingController titleC = TextEditingController(
      text: milestone?.mileStoneName ?? '',
    );
    final TextEditingController descC = TextEditingController(
      text: milestone?.description ?? '',
    );
    DateTime startDate = milestone?.startDate ?? (date ?? DateTime.now());
    DateTime endDate =
        milestone?.endDate ?? startDate.add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(milestone == null ? 'Add Milestone' : 'Edit Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descC,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startDate),
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        startDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(
                  'Start: ${DateFormat.yMMMd().add_jm().format(startDate)}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endDate),
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        endDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(
                  'End: ${DateFormat.yMMMd().add_jm().format(endDate)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'End time cannot be earlier than start time.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (titleC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a milestone title.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final id =
                    milestone?.milReminderID ??
                    await dbService.generateMilReminderID();
                final newMil = MilestoneReminder(
                  milReminderID: id,
                  mileStoneName: titleC.text.trim(),
                  description: descC.text.trim(),
                  startDate: startDate,
                  endDate: endDate,
                  userID: targetUserID,
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAppointmentDetails(Appointment appt) async {
    // ✅ Block mood viewing if no permission
    if (appt.subject!.startsWith('Mood') && !canViewMoodData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to view mood data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: Text(
                  appt.subject ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(appt.notes ?? ''),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View / Edit'),
                onTap: () async {
                  Navigator.pop(ctx);

                  if (appt.subject!.startsWith('Mood')) {
                    final moods = await dbService.getMoodByUserID(targetUserID);
                    final moodId = appt.id.toString().replaceFirst('mood_', '');
                    final mood = moods?.firstWhere(
                      (m) => m.MoodID == moodId,
                      orElse: () => null as Mood,
                    );
                    if (mood != null) {
                      await _showAddEditMood(mood: mood);
                    }
                  } else if (appt.subject!.startsWith('Milestone')) {
                    final milestones = await dbService.getMilReminderByUserID(
                      targetUserID,
                    );
                    final milestoneId = appt.id.toString().replaceFirst(
                      'milestone_',
                      '',
                    );
                    final milestone = milestones?.firstWhere(
                      (ms) => ms.milReminderID == milestoneId,
                      orElse: () => null as MilestoneReminder,
                    );
                    if (milestone != null) {
                      await _showAddEditMilestone(milestone: milestone);
                    }
                  } else if (appt.subject!.startsWith('Medication')) {
                    final meds = await dbService.getMedReminderByUserID(
                      targetUserID,
                    );
                    // Extract base medication ID (remove suffix like _0, _1, etc.)
                    final medId = appt.id
                        .toString()
                        .replaceFirst('med_', '')
                        .split('_')
                        .first;
                    final med = meds?.firstWhere(
                      (m) => m.medReminderID == medId,
                      orElse: () => null as MedicationReminder,
                    );
                    if (med != null) {
                      await _showAddEditMedication(medication: med);
                    }
                  }
                },
              ),

              // ✅ P users can delete all their data
              // ✅ FC users can delete milestones and medications, but NOT moods
              if (!appt.subject!.startsWith('Mood') || !isFCUser)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.pop(ctx);

                    // Confirm deletion
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text(
                          'Are you sure you want to delete "${appt.subject}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (appt.subject!.startsWith('Mood')) {
                        final moodId = appt.id.toString().replaceFirst(
                          'mood_',
                          '',
                        );
                        await dbService.deleteMoodById(moodId);
                      } else if (appt.subject!.startsWith('Milestone')) {
                        final milestoneId = appt.id.toString().replaceFirst(
                          'milestone_',
                          '',
                        );
                        await dbService.deleteMilReminderById(milestoneId);
                      } else if (appt.subject!.startsWith('Medication')) {
                        final medId = appt.id
                            .toString()
                            .replaceFirst('med_', '')
                            .split('_')
                            .first;
                        await dbService.deleteMedReminderById(medId);
                      }

                      await _loadAllReminders();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Entry deleted successfully'),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: Text(
          isFCUser
              ? (isLinkedToMainUser ? 'Calendar (Main User)' : 'Calendar')
              : 'Calendar',
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Show Add button only if linked (for FC) or is P user
          if (isLinkedToMainUser)
            IconButton(
              icon: const Icon(Icons.add),
              color: Colors.pink,
              onPressed: () {
                _showCreateChoice(DateTime.now());
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Show "Link Account" banner for unlinked FC users
                if (isFCUser && !isLinkedToMainUser)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade100,
                    child: Column(
                      children: [
                        Icon(
                          Icons.link_off,
                          color: Colors.orange.shade800,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please link your account to a main user',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You need to connect with a main user to access and manage their calendar data.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_)=>LinkedAccountPage(currentUserID: user!.userID,)));
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Link Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show info banner for linked FC users
                if (isFCUser && isLinkedToMainUser)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            canViewMoodData
                                ? 'Managing main user\'s calendar (Mood data visible)'
                                : 'Managing main user\'s calendar (Mood data hidden)',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ✅ Show warning banner if mood data is hidden for FC
                if (isFCUser && isLinkedToMainUser && !canViewMoodData)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_off,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mood data is hidden. You can view and manage milestones and medications only.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SfCalendar(
                    view: CalendarView.month,
                    initialSelectedDate: DateTime.now(),
                    dataSource: _events,
                    onTap: _onCalendarTap,
                    monthViewSettings: const MonthViewSettings(
                      showAgenda: true,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/linked_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_health_monitor_page.dart';
import 'custom_drawer.dart';
import 'custom_bottom.dart';
import 'dart:async';
import 'emergency_page.dart';
import 'health_data.dart';
import 'user.dart';
import 'package:url_launcher/url_launcher.dart';


class HealthTrendPage extends StatefulWidget {
  const HealthTrendPage({super.key});

  @override
  State<HealthTrendPage> createState() => _HealthTrendPageState();
}

class _HealthTrendPageState extends State<HealthTrendPage> {
  OnnxRuntime? _ort;
  OrtSession? _session;
  String _riskLevel = "Loading...";
  bool _isModelReady = false;
  final dbService = DatabaseService();
  Timer? _backgroundTimer;
  String userID='';

  // Track if user is Family Caregiver
  bool isFamilyCaregiver = false;
  String mainUserID = ''; // Store the actual patient's ID

  // Counters for chart display
  int lowCount = 0;
  int moderateCount = 0;
  int highCount = 0;
  late HealthData currentHD;
  String userName= '';
  List<LinkedAccount>? linkedUser;
  bool isHealthData = false;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userID') ?? '';
    if (uid.isEmpty) {
      debugPrint("⚠️ No userID found in SharedPreferences.");
      return;
    }

    final Users? user = await dbService.getUserByUID(uid);

    if (user == null) {
      debugPrint("⚠️ No user found in database for uid: $uid");
      return;
    }
    List<LinkedAccount>? isLinkedUser;
    if(user.userRole == 'FC'){
      isLinkedUser = await dbService.getLinkedAccountByLinkedUserID(uid);
    }

    setState(() {
      userID = uid;
      userName = user.userName ?? 'User';
      linkedUser = isLinkedUser;
      isFamilyCaregiver = (user.userRole == 'FC');

      // Store main user's ID for operations
      if (isFamilyCaregiver && isLinkedUser != null && isLinkedUser.isNotEmpty) {
        mainUserID = isLinkedUser.first.MainUserID;
      } else {
        mainUserID = uid; // Regular user
      }
    });

    // ✅ Start background timer after determining user role
    _startBackgroundTimer();
  }

  /// ✅ NEW: Start appropriate background timer based on user role
  void _startBackgroundTimer() {
    // Cancel existing timer if any
    _backgroundTimer?.cancel();

    // Start new timer with appropriate function
    _backgroundTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!isFamilyCaregiver) {
        // P users: run prediction (add new health data)
        _runPrediction();
      } else {
        // FC users: refresh to get latest data
        _refreshHealthData();
      }
    });

    debugPrint("✅ Background timer started for ${isFamilyCaregiver ? 'FC' : 'P'} user");
  }

  /// ✅ NEW: Refresh health data for FC users
  Future<void> _refreshHealthData() async {
    // Allow refresh for FC users only
    if (!isFamilyCaregiver) return;

    try {
      debugPrint("🔄 Refreshing health data for FC user...");

      // Re-check linked account status and permissions
      await getUserID();

      // If no permission, just return
      if (!isHealthData) {
        debugPrint("⚠️ No permission to view health data");
        return;
      }

      // Reload counts
      await countHD(mainUserID);

      // Reload latest health data
      final chd = await dbService.getLastHealthData(mainUserID);

      if (chd != null) {
        setState(() {
          currentHD = chd;
          _riskLevel = chd.healthRisk;
          _isModelReady = true;
        });
        debugPrint("✅ Health data refreshed: HR=${chd.PulseRate}, SpO2=${chd.SpO2}, Temp=${chd.bodyTemp}, Risk=${chd.healthRisk}");
      } else {
        setState(() {
          _isModelReady = false;
        });
        debugPrint("⚠️ No health data available yet");
      }
    } catch (e) {
      debugPrint("❌ Error refreshing health data: $e");
    }
  }

  /// Initialize ONNX model
  Future<void> _initModel() async {
    try {
      await getUserID();

      // Check if user is a Family Caregiver (FC) with linked account
      if (linkedUser != null && linkedUser!.isNotEmpty) {
        // FC user - check visibility permission
        if (linkedUser!.first.healthDataVisibility == 'T') {
          setState(() {
            isHealthData = true;
          });
          await countHD(linkedUser!.first.MainUserID);
          final chd = await dbService.getLastHealthData(linkedUser!.first.MainUserID);

          if (chd != null) {
            setState(() {
              currentHD = chd;
              _riskLevel = chd.healthRisk;
            });

            _ort = OnnxRuntime();
            _session = await _ort!.createSessionFromAsset('assets/model/health_risk_xgboost.onnx');
            setState(() => _isModelReady = true);
            if (!isFamilyCaregiver) {
              await _runPrediction();
            }
          } else {
            setState(() {
              _isModelReady = false;
              isHealthData = true;
            });
          }
        } else {
          setState(() {
            isHealthData = false;
            _isModelReady = false;
          });
          debugPrint("⚠️ Health data visibility is disabled for this FC user.");
          return;
        }
      } else {
        // Regular user (not FC) - load their own health data
        await countHD(userID);
        final chd = await dbService.getLastHealthData(userID);

        if (chd != null) {
          setState(() {
            currentHD = chd;
            isHealthData = true;
            _riskLevel = chd.healthRisk;
          });

          _ort = OnnxRuntime();
          _session = await _ort!.createSessionFromAsset('assets/model/health_risk_xgboost.onnx');
          setState(() => _isModelReady = true);
          await _runPrediction();
        } else {
          setState(() {
            _isModelReady = false;
            isHealthData = true;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to load ONNX model: $e");
      setState(() {
        _isModelReady = false;
      });
    }
  }

  Future<void> countHD(String userID) async {
    if (userID.isEmpty) return;
    final hd = await dbService.getAllHealthDataByUserID(userID);
    if (hd == null) return;

    int low = 0, moderate = 0, high = 0;
    for (var healthRisk in hd) {
      if (healthRisk.healthRisk == "Low") low++;
      else if (healthRisk.healthRisk == "Moderate") moderate++;
      else if (healthRisk.healthRisk == "High") high++;
    }

    setState(() {
      lowCount = low;
      moderateCount = moderate;
      highCount = high;
    });
  }

  Future<void> _callFamilyMember(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("⚠️ Could not launch phone call");
    }
  }

  Future<void> _triggerSOSDialog() async {
    final linkedAccounts = await dbService.getLinkedAccountByMainUserID(mainUserID);

    String? linkedPhone;

    if (linkedAccounts != null && linkedAccounts.isNotEmpty) {
      final linkedUserID = linkedAccounts.first.LinkedUserID;
      final Users? linkedUser = await dbService.getUserByUID(linkedUserID);
      linkedPhone = linkedUser?.phoneNo;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Trigger SOS"),
        content: const Text("Do you want to trigger the SOS function?"),
        actions: [
          if (linkedPhone != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _callFamilyMember(linkedPhone!);
              },
              child: const Text("Call Family Member"),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyPage()),
              );
            },
            child: const Text("Nearest Hospital"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _alertHighRisk() async {
    final linkedAccounts = await dbService.getLinkedAccountByMainUserID(mainUserID);

    String? linkedPhone;

    if (linkedAccounts != null && linkedAccounts.isNotEmpty) {
      final linkedUserID = linkedAccounts.first.LinkedUserID;
      final Users? linkedUser = await dbService.getUserByUID(linkedUserID);

      linkedPhone = linkedUser?.phoneNo;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ High Health Risk Detected"),
        content: const Text(
            "Your latest reading indicates a HIGH risk.\n"
                "You may want to seek medical attention immediately."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyPage()),
              );
            },
            child: const Text("Nearest Hospital"),
          ),
          if (linkedPhone != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _callFamilyMember(linkedPhone!);
              },
              child: const Text("Call Family Member"),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  /// 🧪 NEW: Test prediction with custom health data
  Future<void> _testPrediction() async {
    if (_session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model not loaded yet")),
      );
      return;
    }

    // Show dialog to input test data
    double testHeartRate = 75.0;
    double testTemp = 37.0;
    double testSpO2 = 98.0;

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("🧪 Test Prediction"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Heart Rate (bpm)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => testHeartRate = double.tryParse(val) ?? 75.0,
                      controller: TextEditingController(text: testHeartRate.toString()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Body Temperature (°C)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => testTemp = double.tryParse(val) ?? 37.0,
                      controller: TextEditingController(text: testTemp.toString()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "SpO2 (%)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => testSpO2 = double.tryParse(val) ?? 98.0,
                      controller: TextEditingController(text: testSpO2.toString()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'heartRate': testHeartRate,
                      'temp': testTemp,
                      'spO2': testSpO2,
                    });
                  },
                  child: const Text("Run Test"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final inputName = _session!.inputNames.first;
      final inputData = [
        result['heartRate']!,
        result['temp']!,
        result['spO2']!,
      ];

      final inputValues = await OrtValue.fromList(inputData, [1, 3]);
      final inputs = {inputName: inputValues};

      final outputs = await _session!.run(inputs);
      const String probOutputName = 'probabilities';
      final OrtValue? probValue = outputs[probOutputName];

      if (probValue == null) {
        debugPrint("⚠️ Output tensor '$probOutputName' not found.");
        return;
      }

      final List<dynamic> rawProbs = await probValue.asList();
      if (rawProbs.isEmpty || rawProbs.first is! List) return;

      final List<double> probs = (rawProbs.first as List).cast<double>();

      final double maxProb = probs.reduce((a, b) => a > b ? a : b);
      final int classIndex = probs.indexOf(maxProb);

      const riskLevels = {0: 'Low', 1: 'Moderate', 2: 'High'};
      final risk = riskLevels[classIndex] ?? "Unknown";

      // Show result dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("🧪 Test Result"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Heart Rate: ${result['heartRate']} bpm"),
              Text("Temperature: ${result['temp']} °C"),
              Text("SpO2: ${result['spO2']} %"),
              const Divider(),
              Text(
                "Predicted Risk: $risk",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: risk == "High" ? Colors.red : risk == "Moderate" ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text("Probabilities:"),
              Text("  Low: ${(probs[0] * 100).toStringAsFixed(1)}%"),
              Text("  Moderate: ${(probs[1] * 100).toStringAsFixed(1)}%"),
              Text("  High: ${(probs[2] * 100).toStringAsFixed(1)}%"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );

      debugPrint("🧪 Test prediction: $risk (Probabilities: $probs)");
    } catch (e) {
      debugPrint("⚠️ Error during test prediction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Run model inference and update chart counters
  Future<void> _runPrediction() async {
    if (_session == null) return;

    // Block FC users from adding new health data
    if (isFamilyCaregiver) {
      debugPrint("⚠️ Family caregivers cannot add health data");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only view health data, not add new records'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final inputName = _session!.inputNames.first;
      final healthData = await dbService.getRTHealthData();

      if (healthData == null) return;

      final inputData = [
        healthData.PulseRate.toDouble(),
        healthData.bodyTemp.toDouble(),
        healthData.SpO2.toDouble()
      ];

      final inputValues = await OrtValue.fromList(inputData, [1, 3]);
      final inputs = {inputName: inputValues};

      final outputs = await _session!.run(inputs);
      const String probOutputName = 'probabilities';
      final OrtValue? probValue = outputs[probOutputName];

      if (probValue == null) {
        debugPrint("⚠️ Output tensor '$probOutputName' not found.");
        return;
      }

      final List<dynamic> rawProbs = await probValue.asList();
      if (rawProbs.isEmpty || rawProbs.first is! List) return;

      final List<double> probs = (rawProbs.first as List).cast<double>();

      final double maxProb = probs.reduce((a, b) => a > b ? a : b);
      final int classIndex = probs.indexOf(maxProb);

      const riskLevels = {0: 'Low', 1: 'Moderate', 2: 'High'};
      final risk = riskLevels[classIndex] ?? "Unknown";

      final hd = HealthData(
        healthDataID: await dbService.generateHealthDataID(),
        PulseRate: healthData.PulseRate,
        SpO2: healthData.SpO2,
        bodyTemp: healthData.bodyTemp,
        healthRisk: risk,
        date: DateTime.now(),
        userID: mainUserID,
      );
      await dbService.insertHealthData(hd);

      // Update counts
      setState(() {
        currentHD = hd;
        _riskLevel = risk;
        if (risk == "Low") lowCount++;
        else if (risk == "Moderate") moderateCount++;
        else if (risk == "High") highCount++;
      });

      if (risk == "High") {
        _alertHighRisk();
      }

      debugPrint("✅ Prediction result: $_riskLevel (Probabilities: $probs)");
    } catch (e) {
      debugPrint("⚠️ Error during prediction: $e");
    }
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _session = null;
    _ort = null;
    super.dispose();
  }

  /// ---------------- UI SECTION ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Health Trend",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (isFamilyCaregiver && isHealthData)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshHealthData,
              tooltip: 'Refresh health data',
            ),
        ],
      ),
      body: isFamilyCaregiver
          ? RefreshIndicator(
        onRefresh: _refreshHealthData,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildBody(),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildBody(),
      ),
      // 🧪 Stack two floating action buttons
      floatingActionButton: (_isModelReady && isHealthData)
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Test button (top)
          FloatingActionButton(
            heroTag: "test_btn",
            onPressed: _testPrediction,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.science, color: Colors.white),
            tooltip: 'Test Prediction',
          ),
          const SizedBox(height: 16),
          // SOS button (bottom)
          FloatingActionButton(
            heroTag: "sos_btn",
            onPressed: _triggerSOSDialog,
            backgroundColor: Colors.red,
            child: const Icon(Icons.warning, color: Colors.white),
            tooltip: 'SOS - Emergency Alert',
          ),
        ],
      )
          : null,
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
    );
  }

  Widget _buildBody() {
    if (!isHealthData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'You are not allowed to view the Pregnant Women Health Data',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              'Please contact the main user to enable health data visibility.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (!_isModelReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'No health record found',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            if (!isFamilyCaregiver)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BleHealthMonitor()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Connect IoT Device'),
              ),
            if (isFamilyCaregiver)
              ElevatedButton.icon(
                onPressed: _refreshHealthData,
                icon: const Icon(Icons.refresh),
                label: const Text('Check for Updates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          linkedUser != null && isHealthData ? Text(
            "Hi, $userName \nHere is the pregnant women health record",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ):
          Text(
            "Hi, $userName",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildWeeklyCard(),
          const SizedBox(height: 30),
          _buildSyncSection(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthCard(
                "Heart Rate",
                "${currentHD.PulseRate.toStringAsFixed(2)} bpm",
                Colors.pink.shade100,
              ),
              _buildHealthCard(
                "SpO2",
                "${currentHD.SpO2.toStringAsFixed(2)}  %",
                Colors.purple.shade100,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthCard(
                "Temperature",
                "${currentHD.bodyTemp.toStringAsFixed(2)} °C",
                Colors.blue.shade100,
              ),
              _buildHealthCard(
                "Risk",
                _riskLevel,
                Colors.lightBlue.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard() {
    final total = lowCount + moderateCount + highCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pinkAccent.shade100),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "This Week",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: lowCount.toDouble(),
                    title: '$lowCount',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.amber,
                    value: moderateCount.toDouble(),
                    title: '$moderateCount',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.redAccent,
                    value: highCount.toDouble(),
                    title: '$highCount',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
                sectionsSpace: 4,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? "No data yet"
                : "🟢 $lowCount Low   🟡 $moderateCount Moderate   🔴 $highCount High",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection() {
    if (isFamilyCaregiver) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              "Auto-refresh every 1 minute • Pull to refresh",
              style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.pink),
            onPressed: _refreshHealthData,
            tooltip: 'Refresh now',
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Auto-sync every 1 minute",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        ElevatedButton(
          onPressed: _runPrediction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Sync Now"),
        ),
      ],
    );
  }

  Widget _buildHealthCard(String title, String value, Color color) {
    return Container(
      height: 100,
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
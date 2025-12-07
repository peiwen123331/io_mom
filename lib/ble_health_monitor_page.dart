import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class BleHealthMonitor extends StatefulWidget {
  const BleHealthMonitor({super.key});
  @override
  State<BleHealthMonitor> createState() => _BleHealthMonitorState();
}

class _BleHealthMonitorState extends State<BleHealthMonitor> {
  // IMPORTANT: These UUIDs must match EXACTLY with your ESP32 code
  static const String SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0";
  static const String CHARACTERISTIC_UUID = "abcdef12-3456-789a-bcde-f1234567890a";

  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;
  String heartRate = "-", spo2 = "-", temperature = "-";
  String connectionStatus = "Disconnected";
  bool isConnected = false;
  bool isScanning = false;

  // CRITICAL FIX: Specify your regional database URL
  late final DatabaseReference db;

  @override
  void initState() {
    super.initState();
    // Initialize Firebase Database with your regional URL
    db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://io-mom-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref("Sensors");

    print("✅ Firebase Database initialized with regional URL");
  }

  Future<void> startScan() async {
    setState(() {
      connectionStatus = "Scanning...";
      isScanning = true;
    });

    try {
      // Start scanning
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          print("Found device: ${r.device.platformName}");

          // Check if this is our ESP32 device
          if (r.device.platformName == "ESP32_HealthMonitor") {
            print("✅ Found ESP32_HealthMonitor!");

            // Stop scanning
            await FlutterBluePlus.stopScan();
            device = r.device;

            setState(() {
              connectionStatus = "Connecting...";
            });

            try {
              // Connect to device
              await device!.connect(timeout: const Duration(seconds: 10));

              setState(() {
                connectionStatus = "Connected";
                isConnected = true;
                isScanning = false;
              });

              print("✅ Connected to ESP32!");

              // Discover services
              await discoverServices();

            } catch (e) {
              print("❌ Connection error: $e");
              setState(() {
                connectionStatus = "Connection Failed: $e";
                isConnected = false;
                isScanning = false;
              });
            }
            break;
          }
        }
      });

      // Handle timeout
      await Future.delayed(const Duration(seconds: 10));
      if (!isConnected) {
        await FlutterBluePlus.stopScan();
        setState(() {
          connectionStatus = "Device not found";
          isScanning = false;
        });
      }

    } catch (e) {
      print("❌ Scan error: $e");
      setState(() {
        connectionStatus = "Scan Failed: $e";
        isScanning = false;
      });
    }

    // Listen for connection state changes
    device?.connectionState.listen((state) {
      setState(() {
        if (state == BluetoothConnectionState.connected) {
          connectionStatus = "Connected";
          isConnected = true;
        } else if (state == BluetoothConnectionState.disconnected) {
          connectionStatus = "Disconnected";
          isConnected = false;
          print("⚠️ Device disconnected");
        }
      });
    });
  }

  Future<void> discoverServices() async {
    try {
      print("🔍 Discovering services...");
      List<BluetoothService> services = await device!.discoverServices();

      print("Found ${services.length} services");

      for (var service in services) {
        print("Service UUID: ${service.uuid}");

        // Check if this is our health monitor service
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          print("✅ Found Health Monitor Service!");

          for (var c in service.characteristics) {
            print("  Characteristic UUID: ${c.uuid}");

            // Check if this is our data characteristic
            if (c.uuid.toString().toLowerCase().contains(CHARACTERISTIC_UUID.toLowerCase().substring(0, 8))) {
              print("  ✅ Found Data Characteristic!");
              characteristic = c;

              // Enable notifications
              await characteristic!.setNotifyValue(true);
              print("  ✅ Notifications enabled");

              // Listen for data
              characteristic!.lastValueStream.listen((value) {
                try {
                  final jsonStr = utf8.decode(value);
                  print("📥 Received data: $jsonStr");

                  final data = jsonDecode(jsonStr);

                  setState(() {
                    temperature = data["temp"].toString();
                    heartRate = data["hr"].toString();
                    spo2 = data["spo2"].toString();
                  });

                  print("✅ Data parsed - Temp: $temperature, HR: $heartRate, SpO2: $spo2");

                  // Upload to Firebase (now using correct regional database)
                  print("📤 Uploading to Firebase...");
                  db.child("Temperature").set({"Celsius": data["temp"]}).then((_) {
                    print("  ✅ Temperature uploaded");
                  }).catchError((e) {
                    print("  ❌ Temperature upload failed: $e");
                  });

                  db.child("HeartRate").set({"bpm": data["hr"]}).then((_) {
                    print("  ✅ HeartRate uploaded");
                  }).catchError((e) {
                    print("  ❌ HeartRate upload failed: $e");
                  });

                  db.child("SpO2").set({"percent": data["spo2"]}).then((_) {
                    print("  ✅ SpO2 uploaded");
                  }).catchError((e) {
                    print("  ❌ SpO2 upload failed: $e");
                  });

                } catch (e) {
                  print("❌ Error processing data: $e");
                }
              });

              return; // Found what we need, exit
            }
          }
        }
      }

      // If we get here, we didn't find our service/characteristic
      print("⚠️ Could not find Health Monitor service or characteristic");
      setState(() {
        connectionStatus = "Service not found";
      });

    } catch (e) {
      print("❌ Error discovering services: $e");
      setState(() {
        connectionStatus = "Discovery Failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Health Monitor"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connection Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : (isScanning ? Colors.orange : Colors.red),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.bluetooth_connected :
                      (isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connectionStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Connect Button
              ElevatedButton.icon(
                onPressed: isScanning ? null : startScan,
                icon: const Icon(Icons.bluetooth),
                label: Text(isScanning ? "Scanning..." : "Connect to ESP32"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 40),

              // Data Display Cards
              _buildDataCard("🌡️ Temperature", "$temperature °C", Colors.orange),
              const SizedBox(height: 15),
              _buildDataCard("❤️ Heart Rate", "$heartRate bpm", Colors.red),
              const SizedBox(height: 15),
              _buildDataCard("💧 SpO₂", "$spo2 %", Colors.blue),

              const SizedBox(height: 30),

              // Debug Info
              if (isConnected)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text("Firebase: io-mom-iot (Asia Southeast)",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Service UUID: $SERVICE_UUID",
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      Text("Characteristic UUID: $CHARACTERISTIC_UUID",
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    device?.disconnect();
    super.dispose();
  }
}
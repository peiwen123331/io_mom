import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  CameraController? _cameraController;
  late final BarcodeScanner _scanner;
  bool _isBusy = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanner.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      Navigator.pop(context);
      return;
    }

    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);

      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_process);

      setState(() {});
    } catch (e) {
      log("Camera error: $e");
      Navigator.pop(context);
    }
  }

  Future<void> _process(CameraImage img) async {
    if (_isBusy || _hasScanned) return;
    _isBusy = true;

    try {
      final inputImage = _convert(img);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final codes = await _scanner.processImage(inputImage);

      if (codes.isNotEmpty) {
        final value = codes.first.rawValue;
        if (value != null && value.isNotEmpty) {
          _hasScanned = true;
          await _cameraController?.stopImageStream();
          Navigator.pop(context, value);
        }
      }
    } catch (_) {}

    _isBusy = false;
  }

  InputImage? _convert(CameraImage img) {
    final camera = _cameraController!.description;
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = InputImageFormat.nv21;

    final plane = img.planes.first;

    final metadata = InputImageMetadata(
      size: Size(img.width.toDouble(), img.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    final bytes = img.planes.fold<WriteBuffer>(
      WriteBuffer(),
          (buffer, p) => buffer..putUint8List(p.bytes),
    );

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: metadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Scan QR Code"),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

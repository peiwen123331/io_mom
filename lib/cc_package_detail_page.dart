import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:io_mom/database.dart';
import 'package:io_mom/package.dart';
import 'package:io_mom/package_images.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cc_package_page.dart';

class CCPackageDetailPage extends StatefulWidget {
  final String packageID;
  final String from;

  const CCPackageDetailPage({
    super.key,
    required this.packageID,
    required this.from,
  });

  @override
  State<CCPackageDetailPage> createState() => _CCPackageDetailPageState();
}

class _CCPackageDetailPageState extends State<CCPackageDetailPage> {
  final dbService = DatabaseService();
  final picker = ImagePicker();

  bool loading = false;
  List<File> newImages = []; // newly selected images
  List<String> existingImages = []; // Firestore saved images
  Package? package;
  List<String> availablePackageOptions = [];

  // Form fields
  String? selectedName;
  final customNameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final availabilityCtrl = TextEditingController();
  final statusCtrl = TextEditingController();
  final centerIDCtrl = TextEditingController();

  Package? currentPackage;

  final List<String> packageOptions = ['Normal','Plus','Premium','Customize'];

  @override
  void initState() {
    super.initState();
    availablePackageOptions = List.from(packageOptions);
    if (widget.from == "Edit") loadExistingPackage();
  }

  Future<void> loadExistingPackage() async {
    setState(() => loading = true);
    final pkg = await dbService.getPackageByPackageID(widget.packageID);

    if (!packageOptions.contains(pkg!.packageName)) {
      availablePackageOptions = List.from(packageOptions);
      availablePackageOptions.insert(packageOptions.length - 1, pkg.packageName); // Add before "Customize"
    }

    if (pkg != null) {
      currentPackage = pkg;
      selectedName = pkg.packageName;
      descCtrl.text = pkg.description;
      priceCtrl.text = pkg.price.toString();
      durationCtrl.text = pkg.duration.toString();
      availabilityCtrl.text = pkg.availability.toString();
      statusCtrl.text = pkg.status;
      centerIDCtrl.text  = pkg.CenterID;

      final imgList = await dbService.getPackageImagesByPackageID(pkg.PackageID);
      if (imgList != null) existingImages = imgList.map((e) => e.packageImgPath).toList();
    }
    setState(() => loading = false);
  }

  Future pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked != null) {
      setState(() => newImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> deletePackage() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Package'),
          content: const Text('Are you sure you want to delete this package? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If user confirmed deletion
    if (confirm == true) {
      setState(() => loading = true);

      try {
        // Delete package images first (if you have a method for this)
        // await dbService.deletePackageImages(widget.packageID);

        // Delete the package
        await dbService.deletePackageById(widget.packageID);

        setState(() => loading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to package list
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CcPackagePage()),
          );
        }
      } catch (e) {
        setState(() => loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete package: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> savePackage() async {
    // Determine final package name
    final packageName = selectedName == 'Customize'
        ? customNameCtrl.text.trim()
        : selectedName;

    // Validate
    if (packageName == null || packageName.isEmpty ||
        descCtrl.text.isEmpty ||
        priceCtrl.text.isEmpty ||
        durationCtrl.text.isEmpty ||
        availabilityCtrl.text.isEmpty) {
      showMessage("Please fill in all fields");
      return;
    }
    if (double.parse(priceCtrl.text) > 50000.00) {
      showMessage("The price can not exceed RM 50000.00.");
      return;
    }
    if (int.parse(durationCtrl.text) > 100) {
      showMessage("The price can not exceed 100 Days.");
      return;
    }
    if (int.parse(availabilityCtrl.text) > 100) {
      showMessage("The availability can not exceed 100.");
      return;
    }

    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    var cid = prefs.getString('CenterID');
    String packageID = widget.packageID;
    if (widget.from == "Add") {
      packageID = await dbService.generatePackageID();
      statusCtrl.text = 'A';
    }

    final pkg = Package(
      PackageID: packageID,
      packageName: packageName, // use the final name here
      description: descCtrl.text,
      price: double.parse(priceCtrl.text),
      duration: int.parse(durationCtrl.text),
      availability: int.parse(availabilityCtrl.text),
      status: statusCtrl.text,
      CenterID: cid!,
    );

    if (widget.from == "Add") {
      await dbService.insertPackage(pkg);
    } else {
      await dbService.editPackage(pkg);
    }

    // Upload images
    for (var img in newImages) {
      final imageModel = PackageImages(
        PackageID: packageID,
        packageImgPath: img.path,
      );
      await dbService.insertPackageImages(imageModel);
    }

    setState(() => loading = false);
    showMessage("Package saved successfully");
    Navigator.push(context, MaterialPageRoute(builder: (_)=> CcPackagePage()));
  }


  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.from == "Add" ? "Add Package" : "Edit Package"),
        actions: [
          // Only show delete button when editing (not when adding new package)
          if (widget.from == "Edit")
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Package',
              onPressed: deletePackage,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== PACKAGE NAME =====
            DropdownButtonFormField<String>(
              value: selectedName,
              items: availablePackageOptions  // Changed from packageOptions
                  .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedName = val;
                  if (val != 'Customize') {
                    customNameCtrl.text = ''; // clear custom text
                  }
                });
              },
              decoration: const InputDecoration(labelText: "Package Name"),
            ),
            const SizedBox(height: 10),
            if (selectedName == 'Customize') // show text field only if Customize is selected
              TextField(
                controller: customNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Enter your custom package name",
                ),
              ),

            // ===== DESCRIPTION =====
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 4,
            ),
            const SizedBox(height: 10),

            // ===== PRICE / DURATION =====
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(labelText: "Price (RM)"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: "Duration (Days)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ===== AVAILABILITY =====
            TextField(
              controller: availabilityCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Availability"),
            ),
            const SizedBox(height: 20),

            // ===== EXISTING IMAGES =====
            if (existingImages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Existing Images",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: existingImages.map((img) {
                        final imgProvider = img.startsWith('assets/')
                            ? AssetImage(img)
                            : FileImage(File(img)) as ImageProvider;
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(image: imgProvider, fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // ===== NEW IMAGES =====
            const Text("New Images",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: newImages.map((file) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        file,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: InkWell(
                          child: const Icon(Icons.close, size: 15, color: Colors.white),
                          onTap: () {
                            setState(() => newImages.remove(file));
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Add Images"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            ),
            const SizedBox(height: 30),

            // ===== SAVE BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: savePackage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                child: Text(widget.from == "Add" ? "Create Package" : "Save Changes",
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'database.dart';
import 'linked_account.dart';
import 'ultrasound_image.dart';
import 'user.dart';

class UltrasoundImgPage extends StatefulWidget {
  const UltrasoundImgPage({Key? key}) : super(key: key);

  @override
  State<UltrasoundImgPage> createState() => UltrasoundImgPageState();
}

class UltrasoundImgPageState extends State<UltrasoundImgPage> {
  final dbService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser!;

  List<UltrasoundImages> images = [];
  LinkedAccount fetchLinkAcc = LinkedAccount.empty();
  Users currentUser = Users.empty();
  String visibilityMessage = ""; // holds permission denied text

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // -----------------------------
  // LOAD IMAGES
  // -----------------------------
  Future<void> _loadImages() async {
    final fetchUser = await dbService.getUserByUID(user.uid);

    if (fetchUser == null) return;

    currentUser = fetchUser;

    List<UltrasoundImages>? fetchImg;

    if (currentUser.userRole == 'FC') {
      final linkedAccList =
      await dbService.getLinkedAccountByLinkedUserID(user.uid);

      if (linkedAccList != null && linkedAccList.isNotEmpty) {
        fetchLinkAcc = linkedAccList.first;

        if (fetchLinkAcc.ultrasoundImageVisibility == 'T') {
          visibilityMessage = "";
          fetchImg =
          await dbService.getUltrasoundImgByUserID(fetchLinkAcc.MainUserID);
        } else {
          visibilityMessage =
          "You do not have permission to view dairy data.";
        }
      }
    } else {
      // Normal parent
      fetchImg =
      await dbService.getUltrasoundImgByUserID(user.uid);
    }

    setState(() {
      images = fetchImg ?? [];
    });
  }

  // -----------------------------
  // ADD NEW IMAGE
  // -----------------------------
  Future<void> _addNewImage() async {
    File? imageFile;
    String description = "";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialog) {
          return AlertDialog(
            title: const Text("Add New Dairy Image"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked =
                      await picker.pickImage(source: ImageSource.gallery);

                      if (picked != null) {
                        setDialog(() {
                          imageFile = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: imageFile == null
                          ? const Center(child: Text('Tap to select image'))
                          : Image.file(imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder()),
                    onChanged: (val) => description = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Upload"),
                onPressed: () async {
                  if (imageFile == null || description.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select image and description")),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  final newId = await dbService.generateUltrasoundImgID();
                  final newImg = UltrasoundImages(
                    ImageID: newId,
                    imagePath: imageFile!.path,
                    description: description,
                    uploadDate: DateTime.now(),
                    userID: currentUser.userRole == 'FC'
                        ? fetchLinkAcc.MainUserID
                        : user.uid,
                  );

                  await dbService.insertUltrasoundImage(newImg);
                  await _loadImages();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Image uploaded successfully")),
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }

  // -----------------------------
  // EDIT DESCRIPTION
  // -----------------------------
  Future<void> editImgDesc(UltrasoundImages image) async {
    final controller = TextEditingController(text: image.description);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Description"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Description"),
        ),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter the description")),
                );
                return;
              }

              final updated = UltrasoundImages(
                ImageID: image.ImageID,
                imagePath: image.imagePath,
                description: controller.text.trim(),
                uploadDate: image.uploadDate,
                userID: image.userID,
              );

              await dbService.editUltrasoundImgByImageId(updated);
              Navigator.pop(context);
              await _loadImages();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Description updated")),
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // DELETE IMAGE
  // -----------------------------
  Future<void> deleteImgDesc(UltrasoundImages image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbService.deleteUltrasoundImageByImageId(image);
      await _loadImages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image deleted")),
      );
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Dairy Images",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // FC cannot upload unless linked correctly
          if (!(currentUser.userRole == 'FC' &&
              fetchLinkAcc.MainUserID.isEmpty))
            IconButton(
              icon: const Icon(Icons.add, color: Colors.pink),
              onPressed: _addNewImage,
            ),
        ],
      ),
      body: buildImageList(),
    );
  }

  // -----------------------------
  // MAIN LOGIC HANDLER
  // -----------------------------
  Widget buildImageList() {
    // Parent (P) => always show images
    if (currentUser.userRole == 'P') {
      return images.isEmpty
          ? const Center(child: Text("No ultrasound image found"))
          : _buildImageListView();
    }

    // FC role logic
    if (currentUser.userRole == 'FC') {
      if (visibilityMessage.isNotEmpty) {
        // FC but no permission
        return Center(child: Text(visibilityMessage));
      }

      // FC with permission
      return images.isEmpty
          ? const Center(child: Text("No ultrasound image found"))
          : _buildImageListView();
    }

    return const SizedBox.shrink();
  }

  // -----------------------------
  // LIST VIEW
  // -----------------------------
  Widget _buildImageListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: images.length,
      itemBuilder: (_, index) {
        final img = images[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (img.imagePath.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildImage(img.imagePath),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(img.description,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Upload Date: ${img.uploadDate.toIso8601String()}",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.pink),
                            onPressed: () => editImgDesc(img),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.pink),
                            onPressed: () => deleteImgDesc(img),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String path) {
    return path.startsWith('/')
        ? Image.file(File(path),
        height: 180, width: double.infinity, fit: BoxFit.cover)
        : Image.asset(path,
        height: 180, width: double.infinity, fit: BoxFit.cover);
  }
}

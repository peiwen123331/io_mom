import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:io_mom/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'resources.dart';
import 'bookmark.dart';
import 'bookmark_page.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({Key? key}) : super(key: key);

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final dbService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser!;
  List<Resources> _resources = [];
  List<String> _bookmarkedResourceIDs = [];

  int _selectedIndex = 3; // Bottom nav current index

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    final resources = await dbService.getAllResources() ?? [];
    final bookmarks = await dbService.getBookmarkByUserID(user.uid);
    final bookmarkedIDs = bookmarks?.map((b) => b.ResourceID).toList() ?? [];

    setState(() {
      _resources = resources;
      _bookmarkedResourceIDs = bookmarkedIDs;
    });
  }

  Future<void> _toggleBookmark(Resources resource) async {
    final isBookmarked = _bookmarkedResourceIDs.contains(resource.ResourceID);
    final bookmark = Bookmark(
      userID: user.uid,
      ResourceID: resource.ResourceID,
    );

    if (isBookmarked) {
      await dbService.deleteBookmark(bookmark);
      setState(() {
        _bookmarkedResourceIDs.remove(resource.ResourceID);
      });
    } else {
      await dbService.insertBookmark(bookmark);
      setState(() {
        _bookmarkedResourceIDs.add(resource.ResourceID);
      });
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not open $url');
    }
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
    // You can add navigation here to other pages if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>HomePage())),
        ),
        title: const Text(
          "Articles",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkedPage()),
              );
            },
          ),
        ],
      ),
      body: _resources.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          final isBookmarked =
          _bookmarkedResourceIDs.contains(resource.ResourceID);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resource.articleImgPath != null &&
                      resource.articleImgPath.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        resource.articleImgPath,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title ?? 'Untitled Article',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resource.description ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "SAVE FOR LATER",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isBookmarked
                                    ? Colors.pink
                                    : Colors.grey,
                              ),
                              onPressed: () =>
                                  _toggleBookmark(resource),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _openArticle(resource.articleURL ?? ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Read Article",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

    );
  }
}

import 'package:flutter/material.dart';
import 'package:io_mom/article_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'resources.dart';
import 'bookmark.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkedPage extends StatefulWidget {
  const BookmarkedPage({Key? key}) : super(key: key);

  @override
  State<BookmarkedPage> createState() => _BookmarkedPageState();
}

class _BookmarkedPageState extends State<BookmarkedPage> {
  final dbService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser!;
  List<Resources> _bookmarkedResources = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await dbService.getBookmarkByUserID(user.uid);
    final resources = await dbService.getResourcesByUserID(bookmarks);

    setState(() {
      _bookmarkedResources = resources ?? [];
    });
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not open $url');
    }
  }

  Future<void> _removeBookmark(Resources resource) async {
    final bookmark = Bookmark(userID: user.uid, ResourceID: resource.ResourceID);
    await dbService.deleteBookmark(bookmark);

    setState(() {
      _bookmarkedResources.removeWhere((r) => r.ResourceID == resource.ResourceID);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>ArticlesPage())),
        ),
        title: const Text(
          "Bookmarked Articles",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _bookmarkedResources.isEmpty
          ? const Center(
        child: Text(
          'No bookmarked articles',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookmarkedResources.length,
        itemBuilder: (context, index) {
          final resource = _bookmarkedResources[index];

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
                              "BOOKMARKED",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bookmark,
                                color: Colors.pink,
                              ),
                              onPressed: () =>
                                  _removeBookmark(resource),
                              tooltip: "Remove Bookmark",
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

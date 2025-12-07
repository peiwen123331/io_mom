import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'resources.dart';
import 'admin_resources_detail_page.dart';

class AdminResourcesPage extends StatefulWidget {
  const AdminResourcesPage({super.key});

  @override
  State<AdminResourcesPage> createState() => _AdminResourcesPageState();
}

class _AdminResourcesPageState extends State<AdminResourcesPage> {
  final dbService = DatabaseService();
  List<Resources> resources = [];
  List<Resources> filteredResources = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResources();
    _searchController.addListener(_filterResources);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() => isLoading = true);

    List<Resources>? resourceList = await dbService.getAllResources();

    setState(() {
      resources = resourceList ?? [];
      filteredResources = resources;
      isLoading = false;
    });
  }

  void _filterResources() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredResources = resources;
      } else {
        filteredResources = resources.where((resource) {
          final resourceId = resource.ResourceID.toLowerCase();
          final title = (resource.title ?? '').toLowerCase();
          final description = (resource.description ?? '').toLowerCase();

          return resourceId.contains(query) ||
              title.contains(query) ||
              description.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // -------------------- APP BAR --------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Resources Management",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 26, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResourceDetailPage()),
              );
              if (result == true) {
                _loadResources();
              }
            },
          )
        ],
      ),

      // -------------------- BODY --------------------
      body: Column(
        children: [
          // -------------------- SEARCH BAR --------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ID, title, or description...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // -------------------- LIST --------------------
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredResources.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? "No resources found"
                    : "No results found for '${_searchController.text}'",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                itemCount: filteredResources.length,
                itemBuilder: (context, index) {
                  final resource = filteredResources[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT ICON
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book,
                              color: Colors.white, size: 22),
                        ),

                        const SizedBox(width: 12),

                        // CENTER CARD
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ResourceDetailPage(resource: resource),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource.title ?? "Untitled Resource",
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    resource.ResourceID,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (resource.description != null &&
                                      resource.description!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      resource.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
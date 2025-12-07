import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';

import 'admin_page_bottom.dart';
import 'admin_page_drawer.dart';
import 'user.dart';
import 'edit_profile.dart';

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  final dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String selectedTab = "Pregnant Women";

  List<Users> users = [];
  List<Users> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);

    // Get all users first
    List<Users> allUsers = await dbService.getAllUsers();

    // Filter by role based on selected tab
    List<Users> userList;
    if (selectedTab == "Pregnant Women") {
      userList = allUsers.where((user) => user.userRole == 'P').toList();
    } else {
      userList = allUsers.where((user) => user.userRole == 'FC').toList();
    }

    setState(() {
      users = userList;
      filteredUsers = userList;
      isLoading = false;
    });
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          String name = (user.userName ?? '').toLowerCase();
          String email = (user.userEmail ?? '').toLowerCase();
          String phone = (user.phoneNo ?? '').toLowerCase();

          return name.contains(query) ||
              email.contains(query) ||
              phone.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminPageDrawer(userName: 'Admin'),
      appBar: AppBar(
        title: const Text("User Management"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ------------ TAB BUTTONS ------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(child: _buildTabButton("Pregnant Women")),
                const SizedBox(width: 10),
                Expanded(child: _buildTabButton("Family Member / Caregiver")),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ------------ SEARCH BAR ------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: const Icon(Icons.search, color: Colors.pink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUserList(),
          ),
        ],
      ),

      bottomNavigationBar: AdminPageBottom(
        currentIndex: 1,
        onTap: (i) {},
      ),
    );
  }

  // ------------ USER LIST ------------
  Widget _buildUserList() {
    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "No users found"
              : "No users match your search",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (_, index) {
        Users u = filteredUsers[index];
        return _buildUserTile(
          name: u.userName ?? "Unknown User",
          id: u.userID,
          email: u.userEmail,
          phone: u.phoneNo,
          role: u.userRole,
        );
      },
    );
  }

  // ------------ TAB BUTTON ------------
  Widget _buildTabButton(String title) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
          _searchController.clear(); // Clear search when switching tabs
        });
        _loadUsers(); // Reload users when tab changes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ------------ USER TILE ------------
  Widget _buildUserTile({
    required String name,
    required String id,
    String? email,
    String? phone,
    String? role,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to EditProfilePage with 'AdminUser' as from parameter
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(
              userID: id,
              from: 'AdminUser',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: role == 'P'
                  ? Colors.pink.shade100
                  : Colors.blue.shade100,
              child: Icon(
                role == 'P' ? Icons.pregnant_woman : Icons.family_restroom,
                color: role == 'P' ? Colors.pink : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  if (role != null && role.isNotEmpty)
                    Text(
                      role == 'P'
                          ? 'Pregnant Women'
                          : 'Family Member / Caregiver',
                      style: TextStyle(
                        color: role == 'P'
                            ? Colors.pink.shade400
                            : Colors.blue.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (email != null && email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    Text(
                      phone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            const Icon(Icons.edit, color: Colors.pink),
          ],
        ),
      ),
    );
  }
}
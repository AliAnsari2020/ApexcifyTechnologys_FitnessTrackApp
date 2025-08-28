import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  int rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  /// Fetch all users from Firestore
  Future<void> fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('user').get();

      setState(() {
        allUsers =
            snapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "name": doc.data()['name'] ?? 'N/A',
                "email": doc.data()['email'] ?? 'N/A',
                "age": doc.data()['age'] ?? 0,
                "weight": doc.data()['weight'] ?? 0,
                "height": doc.data()['height'] ?? 0,
              };
            }).toList();

        filteredUsers = List.from(allUsers);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => isLoading = false);
    }
  }

  /// Filter users by search term
  void filterUsers(String query) {
    query = query.toLowerCase();
    setState(() {
      filteredUsers =
          allUsers.where((user) {
            return user['name'].toLowerCase().contains(query) ||
                user['email'].toLowerCase().contains(query);
          }).toList();
    });
  }

  /// Edit user info
  void editUser(Map<String, dynamic> user) {
    TextEditingController nameController = TextEditingController(
      text: user['name'],
    );
    TextEditingController weightController = TextEditingController(
      text: user['weight'].toString(),
    );
    TextEditingController heightController = TextEditingController(
      text: user['height'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Edit User Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: "Weight"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: "Height"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('user')
                      .doc(user['id'])
                      .update({
                        "name": nameController.text,
                        "weight": int.tryParse(weightController.text) ?? 0,
                        "height": int.tryParse(heightController.text) ?? 0,
                      });
                  Navigator.pop(context);
                  fetchUsers();
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  /// Delete user with confirmation
  void deleteUser(String userId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Delete User",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to delete this user? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('user')
                      .doc(userId)
                      .delete();
                  Navigator.pop(context);
                  fetchUsers();
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 33, 44),
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // 👈 White color
          ),
        ),

        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 2,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name or email...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.teal,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: filterUsers,
                    ),
                  ),
                  // Data Table in Card
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 800,
                        ), // 📌 Center + Fixed width
                        child: Card(
                          margin: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: SingleChildScrollView(
                            child: PaginatedDataTable(
                              header: const Text(
                                "Registered Users",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  // 👈 White color added
                                ),
                              ),

                              rowsPerPage: rowsPerPage,
                              availableRowsPerPage: const [5, 10, 20],
                              columnSpacing: 20,
                              dataRowHeight: 60,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.teal.shade100,
                              ),
                              onRowsPerPageChanged: (value) {
                                setState(() {
                                  rowsPerPage = value ?? 5;
                                });
                              },
                              columns: const [
                                DataColumn(label: Text("Name")),
                                DataColumn(label: Text("Email")),
                                DataColumn(label: Text("Age")),
                                DataColumn(label: Text("Weight")),
                                DataColumn(label: Text("Height")),
                                DataColumn(label: Text("Actions")),
                              ],
                              source: _UserDataTableSource(
                                filteredUsers,
                                editUser,
                                deleteUser,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _UserDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  _UserDataTableSource(this.users, this.onEdit, this.onDelete);

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];
    return DataRow(
      cells: [
        DataCell(
          Text(
            user['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(user['email'])),
        DataCell(Text(user['age'].toString())),
        DataCell(Text(user['weight'].toString())),
        DataCell(Text(user['height'].toString())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "Delete",
                onPressed: () => onDelete(user['id']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => users.length;
  @override
  int get selectedRowCount => 0;
}

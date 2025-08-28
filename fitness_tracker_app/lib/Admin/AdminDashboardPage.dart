import 'package:fitness_tracker_app/Admin/data_export_page.dart';
import 'package:fitness_tracker_app/Admin/reports_analytics_page.dart';
import 'package:fitness_tracker_app/Admin/user_management_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isLoading = true;

  int totalUsers = 0;
  int totalSteps = 0;
  int goalSteps = 0;
  int totalCalories = 0;
  int goalCalories = 0;
  int totalMinutes = 0;
  int goalMinutes = 0;

  String selectedPage = 'Dashboard';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  /// Fetch data from Firestore
  Future<void> fetchDashboardData() async {
    try {
      setState(() => isLoading = true);

      // 🔹 Total Users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('user').get();
      int userCount = usersSnapshot.docs.length;

      // 🔹 Fitness Data
      final fitnessSnapshot =
          await FirebaseFirestore.instance.collection('fitness').get();
      int steps = 0, calories = 0, minutes = 0, workouts = 0;
      int gSteps = 0, gCalories = 0, gMinutes = 0;

      for (var doc in fitnessSnapshot.docs) {
        final data = doc.data();

        steps += (data['steps'] as num?)?.toInt() ?? 0;
        calories += (data['calories'] as num?)?.toInt() ?? 0;
        minutes += (data['minutes'] as num?)?.toInt() ?? 0;

        gSteps += (data['stepsGoal'] as num?)?.toInt() ?? 0;
        gCalories += (data['caloriesGoal'] as num?)?.toInt() ?? 0;
        gMinutes += (data['minutesGoal'] as num?)?.toInt() ?? 0;
      }

      setState(() {
        totalUsers = userCount;
        totalSteps = steps;
        goalSteps = gSteps;
        totalCalories = calories;
        goalCalories = gCalories;
        totalMinutes = minutes;
        goalMinutes = gMinutes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching data: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load dashboard data")),
        );
      }
    }
  }

  /// Logout function
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  /// Dashboard Card
  Widget buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sidebar Menu
  Widget buildSideMenu() {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard},
      {'title': 'Users', 'icon': Icons.people},
      {'title': 'Reports / Analytics', 'icon': Icons.bar_chart},
      {'title': 'Data Export', 'icon': Icons.download},
    ];

    return Container(
      width: 240,
      color: Colors.blue.shade900,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade800),
            child: const Center(
              child: Text(
                'Admin Panel',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
          ...menuItems.map(
            (item) => buildMenuItem(
              item['title'] as String,
              item['icon'] as IconData,
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: logout,
          ),
        ],
      ),
    );
  }

  /// Menu Item
  Widget buildMenuItem(String title, IconData icon) {
    final isSelected = selectedPage == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.shade700 : Colors.transparent,
      onTap: () {
        if (title == 'Users') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementPage()),
          );
        } else if (title == 'Reports / Analytics') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsAnalyticsPage()),
          );
        } else if (title == 'Data Export') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DataExportPage()),
          );
        } else {
          setState(() => selectedPage = title);
        }
      },
    );
  }

  /// Dashboard Grid
  Widget buildDashboardContent(double width) {
    int crossAxisCount =
        width > 1200
            ? 4
            : width > 800
            ? 3
            : 2;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.count(
          crossAxisCount: crossAxisCount,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            buildDashboardCard(
              title: "Users",
              value: "$totalUsers",
              icon: Icons.people,
              color: Colors.blue,
            ),
            buildDashboardCard(
              title: "Steps",
              value: "$totalSteps",
              icon: Icons.directions_walk,
              color: Colors.green,
            ),
            buildDashboardCard(
              title: "Goal Steps",
              value: "$goalSteps",
              icon: Icons.flag,
              color: Colors.teal,
            ),
            buildDashboardCard(
              title: "Calories",
              value: "$totalCalories",
              icon: Icons.local_fire_department,
              color: Colors.redAccent,
            ),
            buildDashboardCard(
              title: "Goal Calories",
              value: "$goalCalories",
              icon: Icons.bolt,
              color: Colors.purple,
            ),
            buildDashboardCard(
              title: "Minutes",
              value: "$totalMinutes",
              icon: Icons.access_time,
              color: Colors.orange,
            ),
            buildDashboardCard(
              title: "Goal Minutes",
              value: "$goalMinutes",
              icon: Icons.timer,
              color: Colors.pink,
            ),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          if (width >= 800) buildSideMenu(),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.blue.shade700,
                elevation: 2,
                title: Text(
                  selectedPage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              drawer: width < 800 ? Drawer(child: buildSideMenu()) : null,
              body:
                  selectedPage == 'Dashboard'
                      ? buildDashboardContent(width)
                      : Center(
                        child: Text(
                          '$selectedPage Page (Coming Soon)',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

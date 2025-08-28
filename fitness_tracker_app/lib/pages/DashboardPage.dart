import 'package:fitness_tracker_app/pages/ProfilePage.dart';
import 'package:fitness_tracker_app/pages/add_activity_page.dart';
import 'package:fitness_tracker_app/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

enum Period { daily, weekly, monthly }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Bottom Navigation pages
  final List<Widget> _pages = [
    DashboardContent(key: DashboardContent.dashboardKey), // FIXED
    const AddActivityPage(),
    const StatisticsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                backgroundColor: Colors.teal,
                child: const Icon(Icons.add, size: 30, color: Colors.white),
                onPressed: () {
                  (DashboardContent.dashboardKey.currentState)
                      ?._showAddDialog();
                },
              )
              : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Allows more than 3 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Add Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Statistics",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// ---------------------- DASHBOARD CONTENT ---------------------- ///
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  // Unique key for accessing state from parent
  static final GlobalKey<_DashboardContentState> dashboardKey =
      GlobalKey<_DashboardContentState>();

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Period _period = Period.daily;
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // Get date range for filter
  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case Period.daily:
        return (today, today.add(const Duration(days: 1)));
      case Period.weekly:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case Period.monthly:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return (start, end);
    }
  }

  /// Show Add Progress Dialog
  Future<void> _showAddDialog() async {
    final stepsController = TextEditingController();
    final caloriesController = TextEditingController();
    final minutesController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Progress'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Steps'),
                ),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Workout Minutes',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final steps = stepsController.text.trim();
                  final calories = caloriesController.text.trim();
                  final minutes = minutesController.text.trim();

                  if (steps.isNotEmpty &&
                      calories.isNotEmpty &&
                      minutes.isNotEmpty) {
                    await _db.collection('fitness').add({
                      'steps': int.parse(steps),
                      'calories': int.parse(calories),
                      'minutes': int.parse(minutes),
                      'date': Timestamp.fromDate(DateTime.now()),
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                  }
                },

                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  /// Quick Add Method
  Future<void> _quickAddLog(String type) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Quick Add $type'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter $type'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    int value = int.parse(controller.text);
                    Map<String, dynamic> logData = {
                      'steps': 0,
                      'calories': 0,
                      'minutes': 0,
                      'date': Timestamp.fromDate(DateTime.now()),
                    };

                    logData[type] = value;

                    await _db
                        .collection('users')
                        .doc(_uid)
                        .collection('logs')
                        .add(logData);

                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _getDateRange();

    return StreamBuilder<QuerySnapshot>(
      stream:
          _db
              .collection('users')
              .doc(_uid)
              .collection('logs')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('date', isLessThan: Timestamp.fromDate(end))
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        final logs = snapshot.data?.docs ?? [];
        int totalSteps = 0;
        int totalCalories = 0;
        int totalMinutes = 0;

        for (var doc in logs) {
          totalSteps += doc['steps'] as int;
          totalCalories += doc['calories'] as int;
          totalMinutes += doc['minutes'] as int;
        }

        final goalSteps =
            _period == Period.daily
                ? 10000
                : _period == Period.weekly
                ? 70000
                : 300000;
        final progress =
            goalSteps == 0 ? 0.0 : (totalSteps / goalSteps).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Quick Add Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAddButton(
                        Icons.directions_walk,
                        "Steps",
                        Colors.green,
                        "steps",
                      ),
                      _quickAddButton(
                        Icons.local_fire_department,
                        "Calories",
                        Colors.orange,
                        "calories",
                      ),
                      _quickAddButton(
                        Icons.fitness_center,
                        "Minutes",
                        Colors.blue,
                        "minutes",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle for Period Selection
              ToggleButtons(
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.white,
                fillColor: Colors.teal,
                isSelected: [
                  _period == Period.daily,
                  _period == Period.weekly,
                  _period == Period.monthly,
                ],
                onPressed: (index) {
                  setState(() {
                    _period = Period.values[index];
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Daily'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Weekly'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Monthly'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Steps Progress Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CircularPercentIndicator(
                        radius: 80.0,
                        lineWidth: 12.0,
                        animation: true,
                        percent: progress,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalSteps',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of $goalSteps',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.teal,
                        backgroundColor: Colors.teal.shade100,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calories & Workout Summary
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      title: "Calories",
                      value: "$totalCalories",
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      title: "Workout",
                      value: "$totalMinutes min",
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Quick Add Button Widget
  Widget _quickAddButton(
    IconData icon,
    String label,
    Color color,
    String type,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _quickAddLog(type),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Helper card widget
  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

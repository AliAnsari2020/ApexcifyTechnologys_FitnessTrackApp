import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Statistics"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("activities")
                .orderBy("timestamp", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No activities yet.\nStart your journey today! 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final activities = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final docId = activity.id; // Document ID for deletion
              final steps = activity["steps"] ?? 0;
              final workoutType = activity["workoutType"] ?? "Unknown";
              final duration = activity["duration"] ?? 0;
              final calories = activity["calories"] ?? 0;
              final timestamp = (activity["timestamp"] as Timestamp).toDate();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM, yyyy').format(timestamp),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  workoutType,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(context, docId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(Icons.directions_walk, "$steps steps"),
                          _buildStatItem(
                            Icons.local_fire_department,
                            "$calories cal burned",
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatItem(Icons.timer, "$duration mins"),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Reusable method for statistic items
  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Method to confirm deletion
  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Activity"),
            content: const Text(
              "Are you sure you want to delete this activity?",
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
                      .collection("activities")
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Activity deleted successfully"),
                    ),
                  );
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }
}

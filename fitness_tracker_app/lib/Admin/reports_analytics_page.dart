import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsAnalyticsPage extends StatefulWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage> {
  bool isLoading = true;
  double avgStepsPerDay = 0;
  double avgCaloriesPerWeek = 0;

  List<Map<String, dynamic>> topUsersBySteps = [];
  List<Map<String, dynamic>> topUsersByCalories = [];
  List<Map<String, dynamic>> topUsersByWorkouts = [];

  @override
  void initState() {
    super.initState();
    fetchReportsData();
  }

  /// Fetch Analytics Data
  Future<void> fetchReportsData() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      int totalSteps = 0;
      int totalCalories = 0;
      int totalWorkouts = 0;
      List<Map<String, dynamic>> userData = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        int steps = data['totalSteps'] ?? 0;
        int calories = data['totalCalories'] ?? 0;
        int workouts = data['totalWorkouts'] ?? 0;

        totalSteps += steps;
        totalCalories += calories;
        totalWorkouts += workouts;

        userData.add({
          'name': data['name'] ?? 'Unknown',
          'steps': steps,
          'calories': calories,
          'workouts': workouts,
        });
      }

      setState(() {
        avgStepsPerDay =
            usersSnapshot.docs.isNotEmpty
                ? (totalSteps / usersSnapshot.docs.length)
                : 0;
        avgCaloriesPerWeek =
            usersSnapshot.docs.isNotEmpty
                ? (totalCalories / usersSnapshot.docs.length / 7)
                : 0;

        topUsersBySteps = List.from(userData)
          ..sort((a, b) => b['steps'].compareTo(a['steps']));
        topUsersByCalories = List.from(userData)
          ..sort((a, b) => b['calories'].compareTo(a['calories']));
        topUsersByWorkouts = List.from(userData)
          ..sort((a, b) => b['workouts'].compareTo(a['workouts']));

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching analytics data: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load analytics data')),
      );
    }
  }

  /// Line Chart for Average Steps Trend
  Widget buildLineChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: true),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(1, 3000),
              FlSpot(2, 4500),
              FlSpot(3, 4000),
              FlSpot(4, 5500),
              FlSpot(5, 6000),
              FlSpot(6, 7000),
              FlSpot(7, 8000),
            ],
            isCurved: true,
            color: Colors.blueAccent,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Pie Chart for Workout Distribution
  Widget buildPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 40, color: Colors.blue, title: 'Cardio'),
          PieChartSectionData(
            value: 30,
            color: Colors.green,
            title: 'Strength',
          ),
          PieChartSectionData(value: 20, color: Colors.orange, title: 'Yoga'),
          PieChartSectionData(value: 10, color: Colors.purple, title: 'Others'),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  /// Bar Chart for Top Performers
  Widget buildBarChart(List<Map<String, dynamic>> topUsers, String metric) {
    return BarChart(
      BarChartData(
        barGroups:
            topUsers.take(5).toList().asMap().entries.map((entry) {
              int index = entry.key;
              var user = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: (user[metric] ?? 0).toDouble(),
                    color: Colors.blueAccent,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < topUsers.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      topUsers[index]['name'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Card Widget
  Widget buildCard({
    required String title,
    required Widget child,
    double height = 250,
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // 👈 White color
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Average Stats Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryTile(
                          'Avg Steps/Day',
                          avgStepsPerDay.toStringAsFixed(0),
                        ),
                        _buildSummaryTile(
                          'Avg Calories/Week',
                          avgCaloriesPerWeek.toStringAsFixed(0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Charts
                    buildCard(
                      title: "Steps Trend (Last 7 Days)",
                      child: buildLineChart(),
                    ),
                    buildCard(
                      title: "Workout Type Distribution",
                      child: buildPieChart(),
                    ),
                    buildCard(
                      title: "Top Users by Steps",
                      child: buildBarChart(topUsersBySteps, 'steps'),
                    ),
                    buildCard(
                      title: "Top Users by Calories",
                      child: buildBarChart(topUsersByCalories, 'calories'),
                    ),
                    buildCard(
                      title: "Top Users by Workouts",
                      child: buildBarChart(topUsersByWorkouts, 'workouts'),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Summary Tile Widget
  Widget _buildSummaryTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}

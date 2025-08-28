import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController stepsController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();

  String selectedWorkout = 'Running';
  bool isSaving = false;

  // Auto-calculate calories (basic formula)
  void calculateCalories() {
    int steps = int.tryParse(stepsController.text) ?? 0;
    int duration = int.tryParse(durationController.text) ?? 0;
    int calories = (steps * 0.04 + duration * 6).round();
    caloriesController.text = calories.toString();
  }

  Future<void> saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in!");

      // Save activity to Firestore
      await FirebaseFirestore.instance.collection('activities').add({
        'userId': user.uid,
        'steps': int.parse(stepsController.text),
        'workoutType': selectedWorkout,
        'duration': int.parse(durationController.text),
        'calories': int.parse(caloriesController.text),
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity added successfully!")),
      );

      // Navigate to Statistics Page
      Navigator.pushReplacementNamed(context, '/statistics');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Activity"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Steps Input
                TextFormField(
                  controller: stepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Steps",
                    prefixIcon: Icon(Icons.directions_walk),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Please enter steps" : null,
                  onChanged: (val) => calculateCalories(),
                ),
                const SizedBox(height: 15),

                // Workout Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedWorkout,
                  decoration: const InputDecoration(
                    labelText: "Workout Type",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Running', 'Cycling', 'Yoga', 'Gym']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() => selectedWorkout = val!);
                  },
                ),
                const SizedBox(height: 15),

                // Duration Input
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Duration (minutes)",
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Please enter duration" : null,
                  onChanged: (val) => calculateCalories(),
                ),
                const SizedBox(height: 15),

                // Calories Input
                TextFormField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Calories Burned",
                    prefixIcon: Icon(Icons.local_fire_department),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Please enter calories" : null,
                ),
                const SizedBox(height: 25),

                // Save Button
                ElevatedButton.icon(
                  onPressed: isSaving ? null : saveActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon:
                      isSaving
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : const Icon(Icons.save),
                  label: Text(
                    isSaving ? "Saving..." : "Save Activity",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

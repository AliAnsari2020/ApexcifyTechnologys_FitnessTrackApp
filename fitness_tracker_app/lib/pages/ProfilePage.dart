import 'package:fitness_tracker_app/Welcome_Screen/WelcomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final docRef = _db.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();

          // No profile found case
          if (data == null) {
            return _EmptyProfile(
              onCreate: () async {
                await _openEditSheet(
                  name: user.displayName ?? '',
                  age: null,
                  weight: null,
                  height: null,
                  onSaved: (payload) async {
                    await docRef.set(payload, SetOptions(merge: true));
                    if (payload['name'] != null &&
                        payload['name'] != user.displayName) {
                      await user.updateDisplayName(payload['name'] as String);
                    }
                  },
                );
              },
            );
          }

          final name = (data['name'] ?? user.displayName ?? 'User') as String;
          final age = _toInt(data['age']);
          final weight = _toDouble(data['weight']);
          final height = _toDouble(data['height']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.teal,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _InfoTile(
                          label: 'Age',
                          value: age != null ? '$age years' : '—',
                        ),
                        const Divider(height: 0),
                        _InfoTile(
                          label: 'Weight',
                          value:
                              weight != null ? '${_trimZero(weight)} kg' : '—',
                        ),
                        const Divider(height: 0),
                        _InfoTile(
                          label: 'Height',
                          value:
                              height != null ? '${_trimZero(height)} cm' : '—',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    await _openEditSheet(
                      name: name,
                      age: age,
                      weight: weight,
                      height: height,
                      onSaved: (payload) async {
                        await docRef.set(payload, SetOptions(merge: true));
                        if (payload['name'] != null &&
                            payload['name'] != user.displayName) {
                          await user.updateDisplayName(
                            payload['name'] as String,
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _showPasswordUpdateDialog,
                  icon: const Icon(Icons.lock),
                  label: const Text('Update Password'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text("Delete Profile"),
                            content: const Text(
                              "Are you sure you want to delete your profile? This action cannot be undone.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      try {
                        await docRef.delete();
                        _showToast("Profile deleted");
                      } catch (e) {
                        _showError("Failed to delete: $e");
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text("Delete Profile"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Logout method
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError('Failed to logout: $e');
    }
  }

  /// Password Update Dialog
  Future<void> _showPasswordUpdateDialog() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Update Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPasswordController.text);
                  Navigator.pop(ctx);
                  _showToast("Password updated successfully!");
                } catch (e) {
                  _showError("Failed to update password: $e");
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  /// Edit Profile Bottom Sheet
  Future<void> _openEditSheet({
    String? name,
    int? age,
    double? weight,
    double? height,
    required Future<void> Function(Map<String, dynamic> payload) onSaved,
  }) async {
    final nameController = TextEditingController(text: name ?? '');
    final ageController = TextEditingController(text: age?.toString() ?? '');
    final weightController = TextEditingController(
      text: weight?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: height?.toString() ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Edit Profile",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Age",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Weight (kg)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Height (cm)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final payload = {
                      'name': nameController.text.trim(),
                      'age': int.tryParse(ageController.text.trim()),
                      'weight': double.tryParse(weightController.text.trim()),
                      'height': double.tryParse(heightController.text.trim()),
                    };

                    Navigator.pop(ctx);
                    await onSaved(payload);
                    _showToast("Profile updated successfully!");
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show Toast
  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Show Error
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}

/// Empty profile widget
class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 72, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              'No profile found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Let's set up your basic info.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.edit),
              label: const Text('Create / Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Info Tile widget
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.info_outline, color: Colors.teal),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Helper functions
String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

int? _toInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  if (v is num) return v.toDouble();
  return null;
}

String _trimZero(double n) {
  if (n % 1 == 0) return n.toStringAsFixed(0);
  return n.toString();
}

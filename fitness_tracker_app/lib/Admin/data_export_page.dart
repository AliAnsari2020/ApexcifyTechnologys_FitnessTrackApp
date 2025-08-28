import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({Key? key}) : super(key: key);

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  bool isExporting = false;

  /// Fetch user data from Firestore
  Future<List<Map<String, dynamic>>> fetchUserData() async {
    final snapshot = await FirebaseFirestore.instance.collection('user').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'Name': data['name'] ?? 'N/A',
        'Email': data['email'] ?? 'N/A',
        'Age': data['age'] ?? 0,
        'Weight': data['weight'] ?? 0,
        'Height': data['height'] ?? 0,
      };
    }).toList();
  }

  /// Export CSV
  Future<void> exportCSV() async {
    setState(() => isExporting = true);
    try {
      final userData = await fetchUserData();
      List<List<dynamic>> csvData = [
        ['Name', 'Email', 'Age', 'Weight', 'Height'], // ✅ Only required fields
        ...userData.map(
          (u) => [u['Name'], u['Email'], u['Age'], u['Weight'], u['Height']],
        ),
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/user_data.csv";
      final file = File(path);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV Exported: $path')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV Export Failed: $e')));
    } finally {
      setState(() => isExporting = false);
    }
  }

  /// Export PDF
  Future<void> exportPDF() async {
    setState(() => isExporting = true);
    try {
      final userData = await fetchUserData();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build:
              (pw.Context context) => [
                pw.Text(
                  'User Data Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Name', 'Email', 'Age', 'Weight', 'Height'], // ✅
                  data:
                      userData
                          .map(
                            (u) => [
                              u['Name'],
                              u['Email'],
                              u['Age'],
                              u['Weight'],
                              u['Height'],
                            ],
                          )
                          .toList(),
                ),
              ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Exported Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF Export Failed: $e')));
    } finally {
      setState(() => isExporting = false);
    }
  }

  /// --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Export User Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Center(
        child:
            isExporting
                ? const CircularProgressIndicator()
                : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_download,
                            size: 80,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Export User Data",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Download your registered users' data in CSV or PDF format.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: exportCSV,
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Export as CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            onPressed: exportPDF,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export as PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

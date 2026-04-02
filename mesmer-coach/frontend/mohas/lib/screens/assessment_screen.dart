import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AssessmentScreen extends StatefulWidget {
  final int enterpriseId;
  final String type; // "baseline", "midline", or "endline"
  const AssessmentScreen({super.key, required this.enterpriseId, required this.type});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final storage = const FlutterSecureStorage();

  final _revenueController = TextEditingController();
  final _employeesController = TextEditingController();
  final _bookkeepingController = TextEditingController();
  final _painPointsController = TextEditingController();

  bool isSaving = false;

  Future<void> _saveAssessment() async {
    setState(() => isSaving = true);

    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    final body = {
      "enterpriseId": widget.enterpriseId,
      "type": widget.type,
      "responses": {
        "baselineMonthlyRevenue": double.tryParse(_revenueController.text) ?? 0,
        "baselineNoOfEmployees": int.tryParse(_employeesController.text) ?? 0,
        "bookkeepingPractice": _bookkeepingController.text,
        "topTwoPainPoints": _painPointsController.text,
      }
    };

    final response = await http.post(
      Uri.parse('$ip/api/assessments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.type.toUpperCase()} Assessment Saved!'), backgroundColor: const Color(0xFF2E7D32)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}'), backgroundColor: const Color(0xFFC62828)),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.type.toUpperCase()} Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _revenueController,
              decoration: const InputDecoration(labelText: 'Monthly Revenue'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _employeesController,
              decoration: const InputDecoration(labelText: 'Number of Employees'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _bookkeepingController,
              decoration: const InputDecoration(labelText: 'Bookkeeping Practice'),
              maxLines: 2,
            ),
            TextField(
              controller: _painPointsController,
              decoration: const InputDecoration(labelText: 'Top 2 Pain Points'),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSaving ? null : _saveAssessment,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save ${widget.type.toUpperCase()} Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}

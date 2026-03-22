import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class CoachingVisitScreen extends StatefulWidget {
  const CoachingVisitScreen({super.key});
  @override
  State<CoachingVisitScreen> createState() => _CoachingVisitScreenState();
}

class _CoachingVisitScreenState extends State<CoachingVisitScreen> {
  final storage = const FlutterSecureStorage();
  final picker = ImagePicker();

  final _focusController = TextEditingController();
  final _issuesController = TextEditingController();
  final _actionsController = TextEditingController();

  String followUpType = "In-person";
  DateTime? followUpDate = DateTime.now().add(const Duration(days: 7));

  Map<String, bool> practices = {
    "improved_financial_records_adopted": false,
    "separate_business_personal_finances": false,
    "costing_system_introduced": false,
    "inventory_tracking_system_introduced": false,
    "written_growth_plan_developed": false,
  };

  double currentRevenue = 0;
  List<String> photoUrls = [];

  Future<void> _pickPhoto() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => photoUrls.add(photo.path));
    }
  }

  Future<void> _saveVisit() async {
    // === VALIDATION ===
    if (_focusController.text.trim().isEmpty ||
        _issuesController.text.trim().isEmpty ||
        _actionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please fill Key Focus, Issues and Actions'), backgroundColor: Colors.red),
      );
      return;
    }

    final token = await storage.read(key: 'token');

    final body = {
      "enterpriseId": 1,                    // ← Change later when we have list
      "sessionNo": 1,
      "keyFocusArea": _focusController.text,
      "keyIssuesIdentified": _issuesController.text,
      "actionsAgreed": _actionsController.text,
      "evidenceUrls": photoUrls,
      "followUpDate": followUpDate?.toIso8601String(),
      "followUpType": followUpType,
      "measurableResults": {
        "business_practice_improvements": practices,
        "revenue_sales_growth": {
          "current_monthly_revenue": currentRevenue,
          "percentage_increase": 0
        }
      }
    };

    final response = await http.post(
      Uri.parse('http://192.168.43.231:5000/api/coaching-visits'),   // ←←← PUT YOUR REAL IP HERE
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Visit Saved Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);   // go back to dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Coaching Visit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _focusController, decoration: const InputDecoration(labelText: 'Key Focus Area *')),
            TextField(controller: _issuesController, decoration: const InputDecoration(labelText: 'Key Issues Identified *'), maxLines: 2),
            TextField(controller: _actionsController, decoration: const InputDecoration(labelText: 'Actions Agreed *'), maxLines: 3),

            const SizedBox(height: 20),
            const Text('Measurable Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...practices.keys.map((key) => CheckboxListTile(
                  title: Text(key.replaceAll('_', ' ')),
                  value: practices[key],
                  onChanged: (v) => setState(() => practices[key] = v!),
                )),

            TextField(
              decoration: const InputDecoration(labelText: 'Current Monthly Revenue'),
              keyboardType: TextInputType.number,
              onChanged: (v) => currentRevenue = double.tryParse(v) ?? 0,
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo Evidence'),
              onPressed: _pickPhoto,
            ),
            if (photoUrls.isNotEmpty) Text('${photoUrls.length} photo(s) attached'),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveVisit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: const Text('Save Coaching Visit', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

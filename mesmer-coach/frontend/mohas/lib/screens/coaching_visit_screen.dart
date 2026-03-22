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
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String keyFocusArea = '';
  String keyIssues = '';
  String actionsAgreed = '';
  String followUpType = 'In-person';
  DateTime? followUpDate;
  Map<String, dynamic> measurableResults = {
    "business_practice_improvements": {
      "improved_financial_records_adopted": false,
      "separate_business_personal_finances": false,
      "costing_system_introduced": false,
      "inventory_tracking_system_introduced": false,
      "written_growth_plan_developed": false,
    },
    "revenue_sales_growth": {"baseline_monthly_revenue": 0, "current_monthly_revenue": 0, "percentage_increase": 0}
  };

  List<String> evidenceUrls = [];

  Future<void> _submitVisit() async {
    final token = await storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('http://192.168.43.231:5000/api/coaching-visits'), // ← CHANGE TO YOUR IP
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "enterpriseId": 1, // Change to real enterprise ID later
        "sessionNo": 1,
        "keyFocusArea": keyFocusArea,
        "keyIssuesIdentified": keyIssues,
        "actionsAgreed": actionsAgreed,
        "evidenceUrls": evidenceUrls,
        "followUpDate": followUpDate?.toIso8601String(),
        "followUpType": followUpType,
        "measurableResults": measurableResults
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Coaching Visit Saved Successfully!')),
      );
      Navigator.pop(context);
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Key Focus Area'),
                onChanged: (v) => keyFocusArea = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Key Issues Identified'),
                onChanged: (v) => keyIssues = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Actions Agreed'),
                onChanged: (v) => actionsAgreed = v,
              ),
              // Measurable Results Checkboxes
              const Text('Business Practice Improvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...measurableResults['business_practice_improvements'].keys.map((key) {
                return CheckboxListTile(
                  title: Text(key.replaceAll('_', ' ')),
                  value: measurableResults['business_practice_improvements'][key],
                  onChanged: (val) {
                    setState(() => measurableResults['business_practice_improvements'][key] = val);
                  },
                );
              }).toList(),
              // Revenue fields (simple for now)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Current Monthly Revenue'),
                keyboardType: TextInputType.number,
                onChanged: (v) => measurableResults['revenue_sales_growth']['current_monthly_revenue'] = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitVisit,
                child: const Text('Save Coaching Visit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

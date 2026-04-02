import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddEnterpriseScreen extends StatefulWidget {
  const AddEnterpriseScreen({super.key});
  @override
  State<AddEnterpriseScreen> createState() => _AddEnterpriseScreenState();
}

class _AddEnterpriseScreenState extends State<AddEnterpriseScreen> {
  final storage = const FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeesController = TextEditingController();
  final _revenueController = TextEditingController();

  Future<void> _addEnterprise() async {
    if (_nameController.text.isEmpty || _ownerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enterprise Name and Owner Name are required')),
      );
      return;
    }

    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   

    final body = {
      "enterpriseName": _nameController.text,
      "ownerName": _ownerController.text,
      "gender": "Female",
      "age": 30,
      "sector": _sectorController.text,
      "location": _locationController.text,
      "contactNumber": _phoneController.text,
      "baselineEmployees": int.tryParse(_employeesController.text) ?? 0,
      "baselineMonthlyRevenue": double.tryParse(_revenueController.text) ?? 0,
      "existingRecordKeeping": "No",
      "keyChallenges": "New enterprise",
      "region": "Addis Ababa",
      "consentStatus": "Approved"
    };

    final response = await http.post(
      Uri.parse('$ip/api/enterprises'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ New Enterprise Added Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Enterprise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Enterprise Name *')),
            TextField(controller: _ownerController, decoration: const InputDecoration(labelText: 'Owner Name *')),
            TextField(controller: _sectorController, decoration: const InputDecoration(labelText: 'Sector')),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: _employeesController, decoration: const InputDecoration(labelText: 'Number of Employees'), keyboardType: TextInputType.number),
            TextField(controller: _revenueController, decoration: const InputDecoration(labelText: 'Monthly Revenue'), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _addEnterprise,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: const Text('Save New Enterprise', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AssignEnterpriseScreen extends StatefulWidget {
  const AssignEnterpriseScreen({super.key});
  @override
  State<AssignEnterpriseScreen> createState() => _AssignEnterpriseScreenState();
}

class _AssignEnterpriseScreenState extends State<AssignEnterpriseScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> enterprises = [];
  List<dynamic> coaches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   

    final entRes = await http.get(Uri.parse('$ip/api/enterprises'), headers: {'Authorization': 'Bearer $token'});
    if (entRes.statusCode == 200) enterprises = jsonDecode(entRes.body);

    final coachRes = await http.get(Uri.parse('$ip/api/auth/coaches'), headers: {'Authorization': 'Bearer $token'});
    if (coachRes.statusCode == 200) coaches = jsonDecode(coachRes.body);

    setState(() => isLoading = false);
  }

  Future<void> _assignCoach(int enterpriseId, int coachId) async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';

    try {
      final response = await http.put(
        Uri.parse('$ip/api/enterprises/$enterpriseId/assign-coach'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'coachId': coachId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Coach Assigned Successfully!'), backgroundColor: const Color(0xFF2E7D32)),
        );
        _loadData(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFC62828)),
      );
    }
  }

  void _showAssignDialog(dynamic enterprise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign to ${enterprise['enterpriseName']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Select Coach'),
            items: coaches.map((coach) {
              return DropdownMenuItem<int>(
                value: coach['id'],
                child: Text(coach['name']),
              );
            }).toList(),
            onChanged: (selectedCoachId) async {
              if (selectedCoachId != null) {
                Navigator.pop(context);
                await _assignCoach(enterprise['id'], selectedCoachId);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Enterprise to Coach')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: enterprises.length,
              itemBuilder: (context, index) {
                final e = enterprises[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(e['enterpriseName'] ?? ''),
                    subtitle: Text('Current Coach: ${e['coachId'] ?? 'Not Assigned'}'),
                    trailing: ElevatedButton(
                      child: const Text('Assign'),
                      onPressed: () => _showAssignDialog(e),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

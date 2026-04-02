import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'coaching_visit_screen.dart';
import 'coaching_history_screen.dart';
import 'assessment_screen.dart';   // ← New

class EnterpriseListScreen extends StatefulWidget {
  const EnterpriseListScreen({super.key});
  @override
  State<EnterpriseListScreen> createState() => _EnterpriseListScreenState();
}

class _EnterpriseListScreenState extends State<EnterpriseListScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> enterprises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnterprises();
  }

  Future<void> _loadEnterprises() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    final response = await http.get(
      Uri.parse('$ip/api/enterprises'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var all = jsonDecode(response.body);
      final role = await storage.read(key: 'role');
      final userId = await storage.read(key: 'userId');

      if (role == 'Coach') {
        enterprises = all.where((e) => e['coachId'].toString() == userId).toList();
      } else {
        enterprises = all;
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Enterprises'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enterprises.isEmpty
              ? const Center(child: Text('No enterprises assigned'))
              : ListView.builder(
                  itemCount: enterprises.length,
                  itemBuilder: (context, index) {
                    final e = enterprises[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(e['enterpriseName'] ?? ''),
                        subtitle: Text('${e['ownerName']} • ${e['sector']}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoachingVisitScreen(enterpriseId: e['id']),
                            ),
                          );
                        },
                        // Long press to open Assessment menu
                        onLongPress: () => _showAssessmentMenu(e),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAssessmentMenu(dynamic enterprise) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Baseline Assessment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentScreen(
                    enterpriseId: enterprise['id'],
                    type: 'baseline',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Midline Assessment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentScreen(
                    enterpriseId: enterprise['id'],
                    type: 'midline',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Endline Assessment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentScreen(
                    enterpriseId: enterprise['id'],
                    type: 'endline',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

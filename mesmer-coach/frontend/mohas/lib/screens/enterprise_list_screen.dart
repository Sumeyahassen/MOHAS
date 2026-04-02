import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'coaching_visit_screen.dart';
import 'coaching_history_screen.dart';

class EnterpriseListScreen extends StatefulWidget {
  const EnterpriseListScreen({super.key});
  @override
  State<EnterpriseListScreen> createState() => _EnterpriseListScreenState();
}

class _EnterpriseListScreenState extends State<EnterpriseListScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> enterprises = [];
  bool isLoading = true;
  String? userRole;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    userRole = await storage.read(key: 'role');
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← YOUR REAL IP

    // Load enterprises
    final response = await http.get(
      Uri.parse('$ip/api/enterprises'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var allEnterprises = jsonDecode(response.body);

      if (userRole == 'Coach') {
        // Coach can see only enterprises assigned to him
        currentUserId = int.tryParse((await storage.read(key: 'userId') ?? '0'));
        enterprises = allEnterprises.where((e) => e['coachId'] == currentUserId).toList();
      } else {
        // Supervisor / M&E / Admin can see all
        enterprises = allEnterprises;
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userRole == 'Coach' ? 'My Enterprises' : 'All Enterprises'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enterprises.isEmpty
              ? const Center(child: Text('No enterprises assigned yet'))
              : ListView.builder(
                  itemCount: enterprises.length,
                  itemBuilder: (context, index) {
                    final e = enterprises[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(e['enterpriseName'] ?? ''),
                        subtitle: Text('${e['ownerName']} • ${e['sector']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CoachingHistoryScreen(enterpriseId: e['id']),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoachingVisitScreen(enterpriseId: e['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

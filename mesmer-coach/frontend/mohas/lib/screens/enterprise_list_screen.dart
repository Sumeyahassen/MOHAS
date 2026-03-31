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

  @override
  void initState() {
    super.initState();
    _loadEnterprises();
  }

  Future<void> _loadEnterprises() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://YOUR_IP:5000/api/enterprises'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        enterprises = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Enterprises')),
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

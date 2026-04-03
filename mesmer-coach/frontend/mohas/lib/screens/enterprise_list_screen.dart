import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'coaching_visit_screen.dart';
import 'coaching_history_screen.dart';
import 'assessment_screen.dart';
import 'iap_screen.dart';
import 'graduation_screen.dart';

class EnterpriseListScreen extends StatefulWidget {
  const EnterpriseListScreen({super.key});
  @override
  State<EnterpriseListScreen> createState() => _EnterpriseListScreenState();
}

class _EnterpriseListScreenState extends State<EnterpriseListScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> enterprises = [];
  List<dynamic> _filtered = [];
  bool isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnterprises();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = enterprises.where((e) =>
        (e['enterpriseName'] ?? '').toLowerCase().contains(q) ||
        (e['ownerName'] ?? '').toLowerCase().contains(q) ||
        (e['sector'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _loadEnterprises() async {
    final token = await storage.read(key: 'token');
    const ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    try {
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
        _filtered = enterprises;
      }
    } catch (e) {
      print('Error loading enterprises: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Enterprises')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search enterprises...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('${_filtered.length} enterprise${_filtered.length != 1 ? 's' : ''}'),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No enterprises found'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final e = _filtered[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(e['enterpriseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${e['ownerName'] ?? ''} • ${e['sector'] ?? ''}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CoachingVisitScreen(enterpriseId: e['id']),
                                    ),
                                  );
                                },
                                onLongPress: () => _showEnterpriseMenu(e),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showEnterpriseMenu(dynamic e) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(e['enterpriseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Owner: ${e['ownerName'] ?? ''}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_task),
                title: const Text('New Coaching Visit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CoachingVisitScreen(enterpriseId: e['id'])));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View Visit History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CoachingHistoryScreen(enterpriseId: e['id'])));
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Individual Action Plan (IAP)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => IAPScreen(enterpriseId: e['id'])));
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Baseline Assessment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentScreen(enterpriseId: e['id'], type: 'baseline')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Midline Assessment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentScreen(enterpriseId: e['id'], type: 'midline')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Endline Assessment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentScreen(enterpriseId: e['id'], type: 'endline')));
                },
              ),
              // Graduation checklist — shows certificate lock status
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000)),
                title: const Text('Graduation & Certificate'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GraduationScreen(
                      enterpriseId: e['id'],
                      enterpriseName: e['enterpriseName'] ?? 'Enterprise',
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

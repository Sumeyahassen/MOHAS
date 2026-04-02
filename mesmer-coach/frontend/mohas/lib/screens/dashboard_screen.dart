import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'enterprise_list_screen.dart';
import 'coaching_visit_screen.dart';
import 'coaching_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();

  String coachName = "Coach";
  int assignedEnterprises = 0;
  int totalVisits = 0;
  double avgCompletion = 0;
  List<dynamic> recentVisits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoachDashboard();
  }

  Future<void> _loadCoachDashboard() async {
    final token = await storage.read(key: 'token');
    final userId = await storage.read(key: 'userId');
    final ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    try {
      // Get assigned enterprises for this coach
      final entRes = await http.get(
        Uri.parse('$ip/api/enterprises'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (entRes.statusCode == 200) {
        var all = jsonDecode(entRes.body);
        var myEnterprises = all.where((e) => e['coachId'].toString() == userId).toList();
        assignedEnterprises = myEnterprises.length;
      }

      // Get all visits by this coach
      final visitRes = await http.get(
        Uri.parse('$ip/api/coaching-visits'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (visitRes.statusCode == 200) {
        var visits = jsonDecode(visitRes.body);
        totalVisits = visits.length;

        // Recent 3 visits
        recentVisits = visits.take(3).toList();

        // Simple completion rate (enterprises with 8+ visits)
        if (assignedEnterprises > 0) {
          avgCompletion = (totalVisits / assignedEnterprises).clamp(0, 8) / 8 * 100;
        }
      }
    } catch (e) {
      print('Dashboard error: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MESMER Coach')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Coach!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Progress Cards
                  Row(
                    children: [
                      Expanded(
                        child: _progressCard('Assigned Enterprises', assignedEnterprises.toString(), Icons.business),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _progressCard('Total Visits', totalVisits.toString(), Icons.history),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Completion Rate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Average Completion Rate', style: TextStyle(fontSize: 16)),
                              Text('${avgCompletion.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: avgCompletion / 100, minHeight: 10),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text('Recent Visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  recentVisits.isEmpty
                      ? const Text('No visits yet')
                      : Column(
                          children: recentVisits.map((v) => ListTile(
                                leading: CircleAvatar(child: Text('${v['sessionNo']}')),
                                title: Text(v['keyFocusArea'] ?? ''),
                                subtitle: Text(v['actionsAgreed'] ?? ''),
                                trailing: Text(v['date'].toString().substring(0, 10)),
                              )).toList(),
                        ),

                  const SizedBox(height: 40),

                  // Quick Actions
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('My Enterprises', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 65)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen())),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Coaching Visit', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 65)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen())),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _progressCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

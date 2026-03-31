import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'enterprise_list_screen.dart';
import 'reports_screen.dart';
import 'qc_queue_screen.dart';
import 'all_visits_screen.dart';
import 'coach_performance_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});
  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final storage = const FlutterSecureStorage();
  int totalEnterprises = 0;
  int totalVisits = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    final entRes = await http.get(Uri.parse('$ip/api/enterprises'), headers: {'Authorization': 'Bearer $token'});
    if (entRes.statusCode == 200) totalEnterprises = jsonDecode(entRes.body).length;

    final visitRes = await http.get(Uri.parse('$ip/api/coaching-visits'), headers: {'Authorization': 'Bearer $token'});
    if (visitRes.statusCode == 200) totalVisits = jsonDecode(visitRes.body).length;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Program Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statCard('Enterprises', totalEnterprises.toString(), Icons.business),
                        _statCard('Total Visits', totalVisits.toString(), Icons.history),
                      ],
                    ),
            
                    const SizedBox(height: 40),
                    const Text('Supervisor Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text('All Enterprises'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen())),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.checklist),
                      label: const Text('QC Queue (Verification)'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QCQueueScreen())),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('All Coaching Visits'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVisitsScreen())),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Coach Performance Report'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachPerformanceScreen())),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.assessment),
                      label: const Text('Reports & Certificates'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                    ),
                  ],
                ),
              ),
          ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }
}

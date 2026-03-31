import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'enterprise_list_screen.dart';
import 'reports_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();
  int totalEnterprises = 0;
  int totalVisits = 0;
  List<double> revenueData = [0, 0]; // baseline, current
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';

    // Get enterprises
    final entRes = await http.get(
      Uri.parse('$ip/api/enterprises'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (entRes.statusCode == 200) {
      final enterprises = jsonDecode(entRes.body);
      totalEnterprises = enterprises.length;
    }

    // Get coaching visits (for chart)
    final visitRes = await http.get(
      Uri.parse('$ip/api/coaching-visits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (visitRes.statusCode == 200) {
      final visits = jsonDecode(visitRes.body);
      totalVisits = visits.length;

      // Simple real data for chart (last 2 visits revenue)
      if (visits.isNotEmpty) {
        final lastVisit = visits.last;
        final measurable = lastVisit['measurableResults'] ?? {};
        final revenue = measurable['revenue_sales_growth'] ?? {};
        revenueData[0] = (revenue['baseline_monthly_revenue'] ?? 0).toDouble();
        revenueData[1] = (revenue['current_monthly_revenue'] ?? 0).toDouble();
      }
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
                children: [
                  const Text('Dashboard Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCard('Enterprises', totalEnterprises.toString(), Icons.business),
                      _statCard('Visits Done', totalVisits.toString(), Icons.history),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text('Revenue Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [BarChartRodData(toY: revenueData[0], color: Colors.blue, width: 30)],
                            showingTooltipIndicators: [0],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [BarChartRodData(toY: revenueData[1], color: Colors.green, width: 30)],
                            showingTooltipIndicators: [0],
                          ),
                        ],
                        titlesData: const FlTitlesData(show: true),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list, size: 28),
                    label: const Text('Select Enterprise', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 65)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen())),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assessment, size: 28),
                    label: const Text('Reports & Certificates'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 65)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  ),
                ],
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
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

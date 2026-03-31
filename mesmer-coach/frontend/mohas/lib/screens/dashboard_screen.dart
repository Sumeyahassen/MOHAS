import 'package:flutter/material.dart';
import 'enterprise_list_screen.dart';
import 'reports_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MESMER Coach')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Overall Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  titlesData: const FlTitlesData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: Colors.blue, width: 25)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 28, color: Colors.green, width: 25)]),
                  ],
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
}

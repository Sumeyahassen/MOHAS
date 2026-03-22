import 'package:flutter/material.dart';
import 'enterprise_list_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MESMER Coach Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Progress Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Simple Revenue Chart
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 15000, color: Colors.blue)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 18000, color: Colors.green)]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.list, size: 30),
              label: const Text('Select Enterprise & Coach', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

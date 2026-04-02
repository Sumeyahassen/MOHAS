import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'enterprise_list_screen.dart';
import 'coaching_visit_screen.dart';
import 'iap_screen.dart';   // ← IAP Screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MESMER Coach')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('My Enterprises'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen())),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment),
              label: const Text('Individual Action Plan (IAP)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IAPScreen(enterpriseId: 1)), // test with enterprise ID 1
              ),
            ),
          ],
        ),
      ),
    );
  }
}

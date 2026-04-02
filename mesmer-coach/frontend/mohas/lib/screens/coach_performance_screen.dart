import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CoachPerformanceScreen extends StatefulWidget {
  const CoachPerformanceScreen({super.key});
  @override
  State<CoachPerformanceScreen> createState() => _CoachPerformanceScreenState();
}

class _CoachPerformanceScreenState extends State<CoachPerformanceScreen> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> coachesPerformance = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoachPerformance();
  }

  Future<void> _loadCoachPerformance() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ←←← CHANGE TO YOUR REAL IP

    // Get all visits
    final response = await http.get(
      Uri.parse('$ip/api/coaching-visits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> allVisits = jsonDecode(response.body);

      // Group visits by coach (createdBy)
      Map<int, List<dynamic>> grouped = {};
      for (var visit in allVisits) {
        int coachId = visit['createdBy'] ?? 0;
        grouped[coachId] ??= [];
        grouped[coachId]!.add(visit);
      }

      // Convert to performance list
      List<Map<String, dynamic>> list = [];
      grouped.forEach((coachId, visits) {
        list.add({
          "coachId": coachId,
          "coachName": "Coach $coachId",           // Later we can show real name
          "totalVisits": visits.length,
          "enterprises": visits.map((v) => v['enterpriseId']).toSet().length,
          "avgSessions": (visits.length / visits.map((v) => v['enterpriseId']).toSet().length).toStringAsFixed(1),
        });
      });

      setState(() {
        coachesPerformance = list;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Performance Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : coachesPerformance.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  itemCount: coachesPerformance.length,
                  itemBuilder: (context, index) {
                    final coach = coachesPerformance[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(coach['coachId'].toString()),
                        ),
                        title: Text(coach['coachName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${coach['totalVisits']} visits • ${coach['enterprises']} enterprises',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Avg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(coach['avgSessions'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

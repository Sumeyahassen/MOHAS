import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class CoachingHistoryScreen extends StatefulWidget {
  final int enterpriseId;
  const CoachingHistoryScreen({super.key, required this.enterpriseId});

  @override
  State<CoachingHistoryScreen> createState() => _CoachingHistoryScreenState();
}

class _CoachingHistoryScreenState extends State<CoachingHistoryScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> visits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/coaching-visits?enterpriseId=${widget.enterpriseId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        visits = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coaching History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : visits.isEmpty
              ? const Center(child: Text('No coaching visits yet'))
              : ListView.builder(
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final v = visits[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${v['sessionNo']}')),
                        title: Text(v['keyFocusArea'] ?? ''),
                        subtitle: Text(v['actionsAgreed'] ?? ''),
                        trailing: Text(v['date'].toString().substring(0, 10)),
                      ),
                    );
                  },
                ),
    );
  }
}

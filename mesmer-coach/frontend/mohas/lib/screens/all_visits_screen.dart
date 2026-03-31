import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllVisitsScreen extends StatefulWidget {
  const AllVisitsScreen({super.key});
  @override
  State<AllVisitsScreen> createState() => _AllVisitsScreenState();
}

class _AllVisitsScreenState extends State<AllVisitsScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> visits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllVisits();
  }

  Future<void> _loadAllVisits() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';
    final response = await http.get(Uri.parse('$ip/api/coaching-visits'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      setState(() {
        visits = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Coaching Visits')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final v = visits[index];
                return Card(
                  child: ListTile(
                    title: Text('Session ${v['sessionNo']} - ${v['keyFocusArea']}'),
                    subtitle: Text('Enterprise ${v['enterpriseId']}'),
                    trailing: Text(v['date'].toString().substring(0, 10)),
                  ),
                );
              },
            ),
    );
  }
}

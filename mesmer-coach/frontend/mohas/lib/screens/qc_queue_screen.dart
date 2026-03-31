import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QCQueueScreen extends StatefulWidget {
  const QCQueueScreen({super.key});
  @override
  State<QCQueueScreen> createState() => _QCQueueScreenState();
}

class _QCQueueScreenState extends State<QCQueueScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> queue = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQCQueue();
  }

  Future<void> _loadQCQueue() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';
    final response = await http.get(Uri.parse('$ip/api/coaching-visits'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      setState(() {
        queue = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QC Queue')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final v = queue[index];
                return Card(
                  child: ListTile(
                    title: Text(v['keyFocusArea'] ?? ''),
                    subtitle: Text('Enterprise ID: ${v['enterpriseId']}'),
                    trailing: ElevatedButton(
                      child: const Text('Verify'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visit Verified ✓')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

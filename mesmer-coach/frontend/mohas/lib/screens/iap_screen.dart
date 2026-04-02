import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IAPScreen extends StatefulWidget {
  final int enterpriseId;
  const IAPScreen({super.key, required this.enterpriseId});

  @override
  State<IAPScreen> createState() => _IAPScreenState();
}

class _IAPScreenState extends State<IAPScreen> {
  final storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> tasks = [];
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadIAP();
  }

  Future<void> _loadIAP() async {
    setState(() => isLoading = true);
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← Change to your real IP if different

    try {
      final response = await http.get(
        Uri.parse('$ip/api/enterprises/${widget.enterpriseId}/iap'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
        });
      }
    } catch (e) {
      print('Load IAP error: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveIAP() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one task'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';   // ← Change to your real IP

    try {
      final response = await http.post(
        Uri.parse('$ip/api/enterprises/${widget.enterpriseId}/iap'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'tasks': tasks}),
      );

      print('Save IAP Response: ${response.statusCode} - ${response.body}'); // for debugging

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ IAP Saved Successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => isSaving = false);
  }

  void _addTask() {
    setState(() {
      tasks.add({
        "task": "",
        "owner": "",
        "deadline": "",
        "status": "not_started"
      });
    });
  }

  void _removeTask(int index) {
    setState(() => tasks.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Individual Action Plan (IAP)')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(child: Text('No tasks yet. Tap + to add'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: TextField(
                                  decoration: const InputDecoration(labelText: 'Task *'),
                                  onChanged: (v) => tasks[index]['task'] = v,
                                  controller: TextEditingController(text: tasks[index]['task']),
                                ),
                                subtitle: TextField(
                                  decoration: const InputDecoration(labelText: 'Responsible Person'),
                                  onChanged: (v) => tasks[index]['owner'] = v,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeTask(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Task'),
                          onPressed: _addTask,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveIAP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 55),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save IAP', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

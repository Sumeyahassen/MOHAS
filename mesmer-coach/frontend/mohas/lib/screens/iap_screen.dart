import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

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
    const ip = 'http://192.168.43.231:5000';
    try {
      final response = await http.get(
        Uri.parse('$ip/api/enterprises/${widget.enterpriseId}/iap'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []));
      }
    } catch (e) {}
    setState(() => isLoading = false);
  }

  Future<void> _saveIAP() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one task'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => isSaving = true);
    final token = await storage.read(key: 'token');
    const ip = 'http://192.168.43.231:5000';
    try {
      final response = await http.post(
        Uri.parse('$ip/api/enterprises/${widget.enterpriseId}/iap'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'tasks': tasks}),
      );
      if (!mounted) return;
      final ok = response.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'IAP saved successfully' : 'Failed: ${response.body}'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connection error: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (mounted) setState(() => isSaving = false);
  }

  void _addTask() => setState(() => tasks.add({'task': '', 'owner': '', 'deadline': '', 'status': 'not_started'}));
  void _removeTask(int index) => setState(() => tasks.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Action Plan'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Task', style: TextStyle(color: Colors.white)),
            onPressed: _addTask,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.task_alt_rounded, size: 64, color: AppColors.divider),
                            SizedBox(height: 12),
                            Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('Tap "Add Task" to get started', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ]),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(children: [
                                Row(children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    onPressed: () => _removeTask(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Task *', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  onChanged: (v) => tasks[index]['task'] = v,
                                  controller: TextEditingController(text: tasks[index]['task']),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Responsible Person', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  onChanged: (v) => tasks[index]['owner'] = v,
                                  controller: TextEditingController(text: tasks[index]['owner']),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.divider))),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveIAP,
                      child: isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Action Plan', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

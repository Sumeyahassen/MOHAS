import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import 'training_attendance_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final token = await storage.read(key: 'token');
    const ip = AppConstants.baseUrl;   // ← Defined in lib/constants.dart

    try {
      final response = await http.get(
        Uri.parse('$ip/api/trainings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          sessions = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error loading sessions: $e');
    }
    setState(() => isLoading = false);
  }

  void _showCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => NewTrainingSessionDialog(onSessionCreated: _loadSessions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Sessions')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _showCreateSessionDialog,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text('No training sessions yet'))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(s['moduleName'] ?? 'Training Session'),
                        subtitle: Text('${s['date'].toString().substring(0, 10)} • ${s['location'] ?? ''}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingAttendanceScreen(
                                sessionId: s['id'],
                                sessionName: s['moduleName'], // Pass name for AppBar title
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// Dialog to create new session
class NewTrainingSessionDialog extends StatefulWidget {
  final VoidCallback onSessionCreated;
  const NewTrainingSessionDialog({super.key, required this.onSessionCreated});

  @override
  State<NewTrainingSessionDialog> createState() => _NewTrainingSessionDialogState();
}

class _NewTrainingSessionDialogState extends State<NewTrainingSessionDialog> {
  final _moduleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  Future<void> _createSession() async {
    if (_moduleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module name is required')),
      );
      return;
    }

    setState(() => isSaving = true);

    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    const ip = AppConstants.baseUrl;   // ← Defined in lib/constants.dart

    try {
      final response = await http.post(
        Uri.parse('$ip/api/trainings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'moduleName': _moduleController.text,
          'date': selectedDate.toIso8601String(),
          'location': _locationController.text.isEmpty ? 'Not specified' : _locationController.text,
          'trainerId': 1,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onSessionCreated(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Training Session Created!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Training Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _moduleController,
              decoration: const InputDecoration(labelText: 'Module Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(selectedDate.toString().substring(0, 10)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: isSaving ? null : _createSession,
          child: isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create Session'),
        ),
      ],
    );
  }
}

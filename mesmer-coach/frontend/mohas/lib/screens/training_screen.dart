import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    final ip = 'http://192.168.43.231:5000';   // ← CHANGE TO YOUR REAL IP

    final response = await http.get(
      Uri.parse('$ip/api/trainings'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        sessions = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _createNewSession() {
    showDialog(
      context: context,
      builder: (context) => const NewTrainingSessionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Sessions')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _createNewSession,
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
                        title: Text(s['moduleName'] ?? 'Training'),
                        subtitle: Text('${s['date'].toString().substring(0, 10)} • ${s['location'] ?? ''}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingAttendanceScreen(sessionId: s['id']),
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
  const NewTrainingSessionDialog({super.key});
  @override
  State<NewTrainingSessionDialog> createState() => _NewTrainingSessionDialogState();
}

class _NewTrainingSessionDialogState extends State<NewTrainingSessionDialog> {
  final _moduleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AlertDialog(
        title: const Text('Create New Training Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _moduleController,
              decoration: const InputDecoration(labelText: 'Module Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 10),
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
                if (date != null) setState(() => selectedDate = date);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: Save to backend later
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session created (backend save coming soon)')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

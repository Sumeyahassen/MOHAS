import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TrainingAttendanceScreen extends StatefulWidget {
  final int sessionId;
  const TrainingAttendanceScreen({super.key, required this.sessionId});

  @override
  State<TrainingAttendanceScreen> createState() => _TrainingAttendanceScreenState();
}

class _TrainingAttendanceScreenState extends State<TrainingAttendanceScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> attendees = [];
  Map<int, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  Future<void> _loadAttendees() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';

    final response = await http.get(
      Uri.parse('$ip/api/trainings/${widget.sessionId}/attendance'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        attendees = jsonDecode(response.body);
      });
    }
  }

  Future<void> _saveAttendance() async {
    final token = await storage.read(key: 'token');
    final ip = 'http://192.168.43.231:5000';

    await http.post(
      Uri.parse('$ip/api/trainings/${widget.sessionId}/attendance'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(attendance),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance Saved!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: _saveAttendance,
      ),
      body: ListView.builder(
        itemCount: attendees.length,
        itemBuilder: (context, index) {
          final attendee = attendees[index];
          return CheckboxListTile(
            title: Text(attendee['name'] ?? ''),
            subtitle: Text(attendee['enterpriseName'] ?? ''),
            value: attendance[attendee['id']] ?? false,
            onChanged: (val) {
              setState(() {
                attendance[attendee['id']] = val ?? false;
              });
            },
          );
        },
      ),
    );
  }
}

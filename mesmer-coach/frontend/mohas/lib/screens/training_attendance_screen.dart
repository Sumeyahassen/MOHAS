import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

class TrainingAttendanceScreen extends StatefulWidget {
  final int sessionId;
  final String? sessionName; // Optional display name for the session

  const TrainingAttendanceScreen({
    super.key,
    required this.sessionId,
    this.sessionName,
  });

  @override
  State<TrainingAttendanceScreen> createState() => _TrainingAttendanceScreenState();
}

class _TrainingAttendanceScreenState extends State<TrainingAttendanceScreen> {
  final storage = const FlutterSecureStorage();

  // List of enterprises (attendees) loaded from backend
  List<dynamic> attendees = [];

  // Map of enterpriseId → present (true/false)
  // Starts as false (absent) for everyone
  Map<int, bool> attendance = {};

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  /// Load the list of enterprises that can attend this session.
  /// The backend returns all enterprises so the trainer can mark who showed up.
  Future<void> _loadAttendees() async {
    final token = await storage.read(key: 'token');

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/trainings/${widget.sessionId}/attendance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        setState(() {
          attendees = list;
          // Initialize all as absent; will be overwritten if saved data exists
          for (var a in list) {
            attendance[a['id'] as int] = false;
          }
        });
      } else {
        _showSnack('Failed to load attendees', AppColors.error);
      }
    } catch (e) {
      _showSnack('Connection error: $e', AppColors.error);
    }

    setState(() => isLoading = false);
  }

  /// Save the attendance map to the backend.
  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    final token = await storage.read(key: 'token');

    // Build a descriptive payload: { enterpriseId: { present: bool, name: string } }
    final Map<String, dynamic> payload = {};
    for (var a in attendees) {
      final id = a['id'] as int;
      payload[id.toString()] = {
        'present': attendance[id] ?? false,
        'name': a['ownerName'] ?? '',
        'enterprise': a['enterpriseName'] ?? '',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/trainings/${widget.sessionId}/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack('Attendance saved successfully', AppColors.success);
        Navigator.pop(context);
      } else {
        _showSnack('Failed to save: ${response.body}', AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Connection error: $e', AppColors.error);
    }

    if (mounted) setState(() => isSaving = false);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mark all attendees as present with one tap
  void _markAll(bool present) {
    setState(() {
      for (var a in attendees) {
        attendance[a['id'] as int] = present;
      }
    });
  }

  int get _presentCount => attendance.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionName != null
            ? 'Attendance — ${widget.sessionName}'
            : 'Take Attendance'),
        actions: [
          // Quick mark-all buttons
          TextButton(
            onPressed: () => _markAll(true),
            child: const Text('All Present', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => _markAll(false),
            child: const Text('Clear', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : attendees.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppColors.divider),
                      SizedBox(height: 12),
                      Text('No enterprises found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary bar — shows present count out of total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: AppColors.primary.withOpacity(0.07),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$_presentCount of ${attendees.length} present',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Attendee list with checkboxes
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: attendees.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final a = attendees[index];
                          final id = a['id'] as int;
                          final isPresent = attendance[id] ?? false;

                          return CheckboxListTile(
                            // Show enterprise name as title, owner as subtitle
                            title: Text(
                              a['enterpriseName'] ?? 'Enterprise $id',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isPresent ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              a['ownerName'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            // Green check when present, grey when absent
                            value: isPresent,
                            activeColor: AppColors.success,
                            checkColor: Colors.white,
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: isPresent
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.divider,
                              child: Icon(
                                isPresent ? Icons.check_rounded : Icons.person_outline_rounded,
                                size: 18,
                                color: isPresent ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() => attendance[id] = val ?? false);
                            },
                          );
                        },
                      ),
                    ),

                    // Save button pinned at bottom
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.divider)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Attendance ($_presentCount present)',
                            style: const TextStyle(fontSize: 15),
                          ),
                          onPressed: isSaving ? null : _saveAttendance,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

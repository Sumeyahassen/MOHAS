import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

/// QC Queue — Supervisor reviews pending coaching visits and approves or rejects them.
/// Each visit shows key details, evidence count, and action buttons.
class QCQueueScreen extends StatefulWidget {
  const QCQueueScreen({super.key});
  @override
  State<QCQueueScreen> createState() => _QCQueueScreenState();
}

class _QCQueueScreenState extends State<QCQueueScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> queue = [];
  bool isLoading = true;

  // Track which tab is selected: pending / approved / rejected
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => isLoading = true);
    final token = await storage.read(key: 'token');

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/coaching-visits'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => queue = jsonDecode(response.body));
      }
    } catch (e) {
      _showSnack('Connection error: $e', AppColors.error);
    }
    setState(() => isLoading = false);
  }

  /// Send approve or reject decision to backend
  Future<void> _updateQC(int visitId, String status, {String? note}) async {
    final token = await storage.read(key: 'token');

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/api/coaching-visits/$visitId/qc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status, 'note': note}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack(
          status == 'approved' ? 'Visit approved ✓' : 'Visit rejected',
          status == 'approved' ? AppColors.success : AppColors.warning,
        );
        _loadQueue(); // Refresh list
      } else {
        _showSnack('Failed: ${response.body}', AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Connection error: $e', AppColors.error);
    }
  }

  /// Show a dialog asking for a rejection reason before rejecting
  void _showRejectDialog(int visitId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Visit'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection (optional)',
            hintText: 'e.g. Missing evidence photos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _updateQC(visitId, 'rejected', note: noteController.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  List<dynamic> get _filtered =>
      queue.where((v) => (v['qcStatus'] ?? 'pending') == _filter).toList();

  // Color badge for each QC status
  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QC Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadQueue,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs: Pending / Approved / Rejected
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['pending', 'approved', 'rejected'].map((status) {
                final count = queue.where((v) => (v['qcStatus'] ?? 'pending') == status).length;
                final isSelected = _filter == status;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = status),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _statusColor(status).withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _statusColor(status) : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isSelected ? _statusColor(status) : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? _statusColor(status) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Visit list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: AppColors.divider),
                            const SizedBox(height: 12),
                            Text(
                              'No $_filter visits',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          final status = v['qcStatus'] ?? 'pending';
                          final evidenceCount = (v['evidenceUrls'] as List?)?.length ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row: session number + status badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Session ${v['sessionNo']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Enterprise name
                                  Text(
                                    v['enterprise']?['enterpriseName'] ?? 'Enterprise ${v['enterpriseId']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),

                                  // Focus area
                                  Text(
                                    v['keyFocusArea'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Evidence count + date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 14,
                                        color: evidenceCount > 0 ? AppColors.success : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$evidenceCount photo${evidenceCount != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: evidenceCount > 0 ? AppColors.success : AppColors.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        v['date']?.toString().substring(0, 10) ?? '',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),

                                  // Show rejection note if rejected
                                  if (status == 'rejected' && v['qcNote'] != null && v['qcNote'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              v['qcNote'],
                                              style: const TextStyle(fontSize: 12, color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Action buttons — only show for pending visits
                                  if (status == 'pending') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.close_rounded, size: 16),
                                            label: const Text('Reject'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              side: const BorderSide(color: AppColors.error),
                                            ),
                                            onPressed: () => _showRejectDialog(v['id']),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.check_rounded, size: 16),
                                            label: const Text('Approve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                            ),
                                            onPressed: () => _updateQC(v['id'], 'approved'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

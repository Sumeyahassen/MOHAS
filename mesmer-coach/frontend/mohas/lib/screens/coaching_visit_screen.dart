import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../services/offline_sync.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class CoachingVisitScreen extends StatefulWidget {
  final int enterpriseId;
  const CoachingVisitScreen({super.key, required this.enterpriseId});
  @override
  State<CoachingVisitScreen> createState() => _CoachingVisitScreenState();
}

class _CoachingVisitScreenState extends State<CoachingVisitScreen> {
  final storage = const FlutterSecureStorage();
  final picker = ImagePicker();
  final _focusController = TextEditingController();
  final _issuesController = TextEditingController();
  final _actionsController = TextEditingController();

  String followUpType = 'In-person';
  DateTime? followUpDate = DateTime.now().add(const Duration(days: 7));

  Map<String, bool> practices = {
    'improved_financial_records_adopted': false,
    'separate_business_personal_finances': false,
    'costing_system_introduced': false,
    'inventory_tracking_system_introduced': false,
    'written_growth_plan_developed': false,
  };

  double currentRevenue = 0;

  // Stores server URLs after upload (not local paths)
  List<String> photoUrls = [];

  // Tracks local file paths for preview before upload
  List<String> _localPhotoPaths = [];

  bool _isSaving = false;
  bool _isUploading = false; // True while a photo is being uploaded

  /// Pick a photo from camera and immediately upload it to the server.
  /// The returned server URL is stored in photoUrls[] for the visit record.
  Future<void> _pickPhoto() async {
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Compress to reduce upload size
    );
    if (photo == null) return;

    setState(() {
      _localPhotoPaths.add(photo.path); // Show preview immediately
      _isUploading = true;
    });

    final token = await storage.read(key: 'token');

    try {
      // Use Dio for multipart upload
      final dio = Dio();
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path,
            filename: 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      });

      final response = await dio.post(
        '${AppConstants.baseUrl}/api/upload/photo',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Store the server URL — this is what gets saved in the visit record
        final serverUrl = response.data['url'] as String;
        setState(() => photoUrls.add(serverUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded to server'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Upload failed — keep local path as fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo saved locally (upload failed)'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _saveVisit() async {
    if (_focusController.text.trim().isEmpty || _issuesController.text.trim().isEmpty || _actionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Key Focus, Issues and Actions'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSaving = true);

    final body = {
      'enterpriseId': widget.enterpriseId,
      'sessionNo': 1,
      'keyFocusArea': _focusController.text,
      'keyIssuesIdentified': _issuesController.text,
      'actionsAgreed': _actionsController.text,
      'evidenceUrls': photoUrls,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpType': followUpType,
      'measurableResults': {
        'business_practice_improvements': practices,
        'revenue_sales_growth': {'current_monthly_revenue': currentRevenue, 'percentage_increase': 0}
      }
    };

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await OfflineSync.saveOffline(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved offline — will sync when connected'), backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } else {
      final token = await storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/coaching-visits'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit saved successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Coaching Visit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Session Details'),
            const SizedBox(height: 10),
            TextField(controller: _focusController, decoration: const InputDecoration(labelText: 'Key Focus Area *', prefixIcon: Icon(Icons.center_focus_strong_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _issuesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Key Issues Identified *', prefixIcon: Icon(Icons.report_problem_outlined), alignLabelWithHint: true)),
            const SizedBox(height: 12),
            TextField(controller: _actionsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Actions Agreed *', prefixIcon: Icon(Icons.checklist_rounded), alignLabelWithHint: true)),

            const SizedBox(height: 24),
            _sectionLabel('Business Practice Improvements'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Column(
                children: practices.keys.map((key) {
                  final label = key.replaceAll('_', ' ');
                  return CheckboxListTile(
                    dense: true,
                    title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    value: practices[key],
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => practices[key] = v!),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            _sectionLabel('Revenue'),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: 'Current Monthly Revenue (ETB)', prefixIcon: Icon(Icons.attach_money_rounded)),
              keyboardType: TextInputType.number,
              onChanged: (v) => currentRevenue = double.tryParse(v) ?? 0,
            ),

            const SizedBox(height: 20),
            _sectionLabel('Evidence Photos'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              label: Text(
                _isUploading
                    ? 'Uploading photo...'
                    : _localPhotoPaths.isEmpty
                        ? 'Take Photo Evidence'
                        : '${photoUrls.length} uploaded — add more',
                style: const TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isUploading ? null : _pickPhoto,
            ),
            // Show thumbnails of captured photos
            if (_localPhotoPaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _localPhotoPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_localPhotoPaths[i]),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Green checkmark overlay if this photo was uploaded
                      if (i < photoUrls.length)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveVisit,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Coaching Visit', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_sync.dart';
import '../theme/app_theme.dart';

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
  List<String> photoUrls = [];
  bool _isSaving = false;

  Future<void> _pickPhoto() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => photoUrls.add(photo.path));
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
        Uri.parse('http://192.168.43.231:5000/api/coaching-visits'),
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
              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              label: Text(photoUrls.isEmpty ? 'Take Photo Evidence' : '${photoUrls.length} photo(s) attached — add more',
                  style: const TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _pickPhoto,
            ),

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

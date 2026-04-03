import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

class AddEnterpriseScreen extends StatefulWidget {
  const AddEnterpriseScreen({super.key});
  @override
  State<AddEnterpriseScreen> createState() => _AddEnterpriseScreenState();
}

class _AddEnterpriseScreenState extends State<AddEnterpriseScreen> {
  final storage = const FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeesController = TextEditingController();
  final _revenueController = TextEditingController();

  // Gender and region dropdown values
  String _gender = 'Female';
  String _region = 'Addis Ababa';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _sectorController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _employeesController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  Future<void> _addEnterprise() async {
    if (_nameController.text.trim().isEmpty || _ownerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enterprise Name and Owner Name are required'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final token = await storage.read(key: 'token');

    final body = {
      "enterpriseName": _nameController.text.trim(),
      "ownerName": _ownerController.text.trim(),
      "gender": _gender,
      "age": 30,
      "sector": _sectorController.text.trim(),
      "location": _locationController.text.trim(),
      "contactNumber": _phoneController.text.trim(),
      "baselineEmployees": int.tryParse(_employeesController.text) ?? 0,
      "baselineMonthlyRevenue": double.tryParse(_revenueController.text) ?? 0,
      "existingRecordKeeping": "No",
      "keyChallenges": "New enterprise",
      "region": _region,
      "consentStatus": "Approved"
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/enterprises'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enterprise added successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  // Helper — wraps each field with consistent vertical spacing
  Widget _field(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: child,
      );

  // Section label
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Enterprise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Business Info ──────────────────────────────
            _label('BUSINESS INFORMATION'),

            _field(TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Enterprise Name *',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            )),

            _field(TextField(
              controller: _sectorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Sector / Industry',
                prefixIcon: Icon(Icons.category_rounded),
              ),
            )),

            _field(TextField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location / Woreda',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            )),

            // Region dropdown
            _field(DropdownButtonFormField<String>(
              value: _region,
              decoration: const InputDecoration(
                labelText: 'Region',
                prefixIcon: Icon(Icons.map_rounded),
              ),
              items: [
                'Addis Ababa', 'Oromia', 'Amhara', 'Tigray',
                'SNNPR', 'Somali', 'Afar', 'Benishangul-Gumuz',
                'Gambela', 'Harari', 'Dire Dawa',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _region = v!),
            )),

            // ── Owner Info ─────────────────────────────────
            _label('OWNER INFORMATION'),

            _field(TextField(
              controller: _ownerController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Owner Full Name *',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            )),

            // Gender dropdown
            _field(DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_rounded),
              ),
              items: ['Female', 'Male']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            )),

            _field(TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            )),

            // ── Baseline Figures ───────────────────────────
            _label('BASELINE FIGURES'),

            _field(TextField(
              controller: _employeesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Employees',
                prefixIcon: Icon(Icons.people_rounded),
              ),
            )),

            _field(TextField(
              controller: _revenueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Revenue (ETB)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            )),

            const SizedBox(height: 8),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save New Enterprise',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _isSaving ? null : _addEnterprise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

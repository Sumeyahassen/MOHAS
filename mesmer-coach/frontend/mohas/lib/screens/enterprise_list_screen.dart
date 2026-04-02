import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import 'coaching_visit_screen.dart';
import 'assessment_screen.dart';

class EnterpriseListScreen extends StatefulWidget {
  const EnterpriseListScreen({super.key});
  @override
  State<EnterpriseListScreen> createState() => _EnterpriseListScreenState();
}

class _EnterpriseListScreenState extends State<EnterpriseListScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> enterprises = [];
  List<dynamic> _filtered = [];
  bool isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnterprises();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = enterprises.where((e) =>
        (e['enterpriseName'] ?? '').toLowerCase().contains(q) ||
        (e['ownerName'] ?? '').toLowerCase().contains(q) ||
        (e['sector'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _loadEnterprises() async {
    final token = await storage.read(key: 'token');
    const ip = 'http://192.168.43.231:5000';
    try {
      final response = await http.get(Uri.parse('$ip/api/enterprises'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        var all = jsonDecode(response.body);
        final role = await storage.read(key: 'role');
        final userId = await storage.read(key: 'userId');
        enterprises = role == 'Coach' ? all.where((e) => e['coachId'].toString() == userId).toList() : all;
        _filtered = enterprises;
      }
    } catch (e) {}
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprises')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search enterprises...',
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('${_filtered.length} enterprise${_filtered.length != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_outlined, size: 64, color: AppColors.divider),
                              SizedBox(height: 12),
                              Text('No enterprises found', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final e = _filtered[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
                                ),
                                title: Text(e['enterpriseName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                                subtitle: Text('${e['ownerName'] ?? ''} • ${e['sector'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => CoachingVisitScreen(enterpriseId: e['id']))),
                                onLongPress: () => _showAssessmentMenu(e),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showAssessmentMenu(dynamic enterprise) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            Text(enterprise['enterpriseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            for (final type in ['baseline', 'midline', 'endline'])
              ListTile(
                leading: const Icon(Icons.assessment_rounded, color: AppColors.primary),
                title: Text('${type[0].toUpperCase()}${type.substring(1)} Assessment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AssessmentScreen(enterpriseId: enterprise['id'], type: type),
                  ));
                },
              ),
          ],
        ),
      ),
    );
  }
}

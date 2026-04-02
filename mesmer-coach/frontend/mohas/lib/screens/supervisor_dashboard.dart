import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import 'enterprise_list_screen.dart';
import 'reports_screen.dart';
import 'qc_queue_screen.dart';
import 'all_visits_screen.dart';
import 'coach_performance_screen.dart';
import 'assign_enterprise_screen.dart';
import 'add_enterprise_screen.dart';
import 'login_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});
  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final storage = const FlutterSecureStorage();
  int totalEnterprises = 0;
  int totalVisits = 0;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await storage.read(key: 'token');
    const ip = 'http://192.168.43.231:5000';
    try {
      final entRes = await http.get(Uri.parse('$ip/api/enterprises'), headers: {'Authorization': 'Bearer $token'});
      if (entRes.statusCode == 200) totalEnterprises = jsonDecode(entRes.body).length;
      final visitRes = await http.get(Uri.parse('$ip/api/coaching-visits'), headers: {'Authorization': 'Bearer $token'});
      if (visitRes.statusCode == 200) totalVisits = jsonDecode(visitRes.body).length;
    } catch (e) {}
    setState(() => isLoading = false);
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.supervisor_account_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Supervisor'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Logout', onPressed: _logout),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _selectedIndex == 0
              ? _overviewTab()
              : _toolsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: 'Tools'),
        ],
      ),
    );
  }

  Widget _overviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Program Overview', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('MESMER Business Coaching', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              Expanded(child: _statCard('Enterprises', totalEnterprises.toString(), Icons.business_rounded, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Visits', totalVisits.toString(), Icons.history_rounded, AppColors.dark)),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Quick Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          _menuTile(Icons.list_alt_rounded, 'All Enterprises', 'View and manage enterprises', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseListScreen()))),
          _menuTile(Icons.bar_chart_rounded, 'Coach Performance', 'Track coach metrics', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachPerformanceScreen()))),
          _menuTile(Icons.picture_as_pdf_rounded, 'Reports & Certificates', 'Generate PDF reports', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
        ],
      ),
    );
  }

  Widget _toolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Management Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _menuTile(Icons.person_add_rounded, 'Assign Enterprise to Coach', 'Manage coach assignments', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignEnterpriseScreen()))),
          _menuTile(Icons.add_business_rounded, 'Add New Enterprise', 'Register a new enterprise', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEnterpriseScreen()))),
          _menuTile(Icons.checklist_rounded, 'QC Queue', 'Review quality control items', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QCQueueScreen()))),
          _menuTile(Icons.view_list_rounded, 'All Visits', 'Browse all coaching visits', () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVisitsScreen()))),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

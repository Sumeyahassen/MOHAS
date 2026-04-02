import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _generateCertificate(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (ctx) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('MOHAS CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1B5E20'))),
                pw.SizedBox(height: 30),
                pw.Text('This is to certify that', style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),
                pw.Text('Sumeya Trading', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('has successfully completed the MESMER Business Coaching Program'),
                pw.SizedBox(height: 30),
                pw.Text('Date: March 2026', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Certificate ID: MESMER-2026-001', style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate generated'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Certificates')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _reportTile(
              context,
              icon: Icons.workspace_premium_rounded,
              title: 'Completion Certificate',
              subtitle: 'Generate a PDF certificate for an enterprise',
              onTap: () => _generateCertificate(context),
            ),
            _reportTile(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Program Report',
              subtitle: 'Full program summary — coming soon',
              onTap: null,
            ),
            _reportTile(
              context,
              icon: Icons.table_chart_rounded,
              title: 'Excel Export',
              subtitle: 'Export data to spreadsheet — coming soon',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary.withOpacity(0.1) : AppColors.divider.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: enabled ? AppColors.primary : AppColors.textSecondary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: enabled ? AppColors.textPrimary : AppColors.textSecondary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: enabled ? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary) : null,
        onTap: onTap,
      ),
    );
  }
}

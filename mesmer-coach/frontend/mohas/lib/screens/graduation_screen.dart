import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

/// Graduation Screen — shows the triangulation checklist for an enterprise.
/// The certificate button is LOCKED until all three criteria are met:
///   1. Baseline assessment completed
///   2. At least 8 approved coaching visits
///   3. At least one visit has evidence photos on the server
class GraduationScreen extends StatefulWidget {
  final int enterpriseId;
  final String enterpriseName;

  const GraduationScreen({
    super.key,
    required this.enterpriseId,
    required this.enterpriseName,
  });

  @override
  State<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends State<GraduationScreen> {
  final storage = const FlutterSecureStorage();

  bool isLoading = true;
  bool isIssuing = false;

  // Checklist data from backend
  bool hasBaseline = false;
  int completedVisits = 0;
  bool hasEvidence = false;
  bool canGraduate = false;
  bool certificateIssued = false;

  static const int requiredVisits = 8;

  @override
  void initState() {
    super.initState();
    _checkGraduation();
  }

  /// Load the graduation checklist from the backend
  Future<void> _checkGraduation() async {
    setState(() => isLoading = true);
    final token = await storage.read(key: 'token');

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/graduation/${widget.enterpriseId}/check'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          hasBaseline = data['hasBaseline'] ?? false;
          completedVisits = data['completedVisits'] ?? 0;
          hasEvidence = data['hasEvidence'] ?? false;
          canGraduate = data['canGraduate'] ?? false;
        });
      }
    } catch (e) {
      _showSnack('Connection error: $e', AppColors.error);
    }

    setState(() => isLoading = false);
  }

  /// Issue the certificate — calls backend to mark as issued, then generates PDF
  Future<void> _issueCertificate() async {
    setState(() => isIssuing = true);
    final token = await storage.read(key: 'token');

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/graduation/${widget.enterpriseId}/issue-certificate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => certificateIssued = true);
        await _generateCertificatePDF();
      } else {
        final err = jsonDecode(response.body);
        _showSnack(err['error'] ?? 'Failed to issue certificate', AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Connection error: $e', AppColors.error);
    }

    if (mounted) setState(() => isIssuing = false);
  }

  /// Generate and print/share the PDF certificate
  Future<void> _generateCertificatePDF() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final certId = 'MESMER-${widget.enterpriseId}-${now.year}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header border decoration
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#1565C0'), width: 3),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'MOHAS CONSULT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1565C0'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0D47A1'),
                      ),
                    ),
                    pw.Text(
                      'MESMER Business Coaching Program',
                      style: pw.TextStyle(fontSize: 13, color: PdfColor.fromHex('#5A6478')),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text('This is to certify that', style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      widget.enterpriseName,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1A2340'),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'has successfully completed all requirements of the\nMESMER Business Coaching Program',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                    pw.SizedBox(height: 24),
                    // Criteria summary
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        _pdfBadge('✓ Baseline\nAssessment'),
                        _pdfBadge('✓ $completedVisits Coaching\nVisits'),
                        _pdfBadge('✓ Evidence\nDocumented'),
                      ],
                    ),
                    pw.SizedBox(height: 24),
                    pw.Divider(),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Date: ${now.day}/${now.month}/${now.year}',
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Certificate ID: $certId',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      if (!mounted) return;
      _showSnack('Certificate generated successfully', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('PDF error: $e', AppColors.error);
    }
  }

  pw.Widget _pdfBadge(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#E3F2FD'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1565C0'))),
      );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graduation Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _checkGraduation,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enterprise name banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Enterprise',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          widget.enterpriseName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Graduation Requirements',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All three criteria must be met before a certificate can be issued.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Checklist items
                  _checklistItem(
                    icon: Icons.assessment_rounded,
                    title: 'Baseline Assessment',
                    subtitle: 'Enterprise must have a completed baseline assessment',
                    isDone: hasBaseline,
                  ),
                  const SizedBox(height: 10),
                  _checklistItem(
                    icon: Icons.event_available_rounded,
                    title: 'Coaching Visits ($completedVisits / $requiredVisits approved)',
                    subtitle: 'At least 8 coaching visits must be approved by supervisor',
                    isDone: completedVisits >= requiredVisits,
                    // Show progress bar for visits
                    progress: completedVisits / requiredVisits,
                  ),
                  const SizedBox(height: 10),
                  _checklistItem(
                    icon: Icons.photo_library_rounded,
                    title: 'Evidence Documentation',
                    subtitle: 'At least one visit must have photos uploaded to the server',
                    isDone: hasEvidence,
                  ),
                  const SizedBox(height: 32),

                  // Overall status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: canGraduate
                          ? AppColors.success.withOpacity(0.08)
                          : AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canGraduate
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          canGraduate
                              ? Icons.workspace_premium_rounded
                              : Icons.lock_outline_rounded,
                          color: canGraduate ? AppColors.success : AppColors.warning,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canGraduate
                                    ? 'Ready for Graduation'
                                    : 'Not Yet Eligible',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: canGraduate ? AppColors.success : AppColors.warning,
                                ),
                              ),
                              Text(
                                canGraduate
                                    ? 'All criteria met. Certificate can be issued.'
                                    : 'Complete all requirements above to unlock the certificate.',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Certificate button — disabled until canGraduate is true
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: isIssuing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.workspace_premium_rounded),
                      label: Text(
                        isIssuing
                            ? 'Generating...'
                            : canGraduate
                                ? 'Issue & Print Certificate'
                                : 'Certificate Locked',
                        style: const TextStyle(fontSize: 15),
                      ),
                      // Only enabled when all criteria pass
                      onPressed: (canGraduate && !isIssuing) ? _issueCertificate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canGraduate ? AppColors.success : AppColors.divider,
                        foregroundColor:
                            canGraduate ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _checklistItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppColors.success.withOpacity(0.4) : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.divider.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isDone ? AppColors.success : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isDone ? AppColors.success : AppColors.divider,
                size: 24,
              ),
            ],
          ),
          // Progress bar for visits count
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

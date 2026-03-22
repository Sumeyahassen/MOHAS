import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _generateCertificate(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('MESMER CERTIFICATE OF COMPLETION', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text('This is to certify that', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
                pw.Text('Sumeya Trading', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('has successfully completed the MESMER Business Coaching Program'),
                pw.SizedBox(height: 30),
                pw.Text('Date: March 2026', style: const pw.TextStyle(fontSize: 16)),
                pw.Text('Certificate ID: MESMER-2026-001', style: const pw.TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Certificate Generated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Certificates')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 30),
              label: const Text('Generate Certificate (PDF)', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(300, 60)),
              onPressed: () => _generateCertificate(context),
            ),
            const SizedBox(height: 30),
            const Text('Full reports and Excel export coming soon'),
          ],
        ),
      ),
    );
  }
}

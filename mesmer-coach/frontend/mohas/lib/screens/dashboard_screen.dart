import 'package:flutter/material.dart';
import 'coaching_visit_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MESMER Coach Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.person, size: 90, color: Colors.blue),
            const Text('Welcome Coach!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 30),
              label: const Text('New Coaching Visit', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachingVisitScreen()));
              },
            ),
            const SizedBox(height: 20),
            const Text('Your enterprises and progress will appear here soon'),
          ],
        ),
      ),
    );
  }
}

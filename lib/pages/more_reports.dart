import 'package:flutter/material.dart';
import 'coming_soon_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> reportOptions = [
      'Daily Report',
      'Weekly Report',
      'Monthly Report',
      'Most Sold Items',
      'Most Sale Hours',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Reports'),
      ),
      body: ListView.separated(
        itemCount: reportOptions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(reportOptions[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComingSoonPage(title: reportOptions[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
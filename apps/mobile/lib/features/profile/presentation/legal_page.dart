import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.asset});
  final String title, asset;
  static void open(BuildContext context, String title, String asset) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalPage(title: title, asset: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<String>(
      future: rootBundle.loadString('assets/legal/$asset.md'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Chưa mở được tài liệu. Hãy thử lại.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              for (final section in snapshot.data!.trim().split('\n\n'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    section.replaceFirst(RegExp(r'^#+ '), ''),
                    style: TextStyle(
                      fontSize: section.startsWith('#') ? 20 : 16,
                      fontWeight: section.startsWith('#')
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

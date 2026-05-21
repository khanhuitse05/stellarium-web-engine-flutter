import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mlastro_skymap/sky_map_assets.dart';

class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open source licenses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Third-party software',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const _NoticeSection(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _AgplLicensePage(),
              ),
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('View full AGPL v3 license text'),
          ),
        ],
      ),
    );
  }
}

class _NoticeSection extends StatelessWidget {
  const _NoticeSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(SkyMapAssets.notice),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Could not load notice: ${snap.error}');
        }
        return SelectableText(
          snap.data ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}

class _AgplLicensePage extends StatelessWidget {
  const _AgplLicensePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GNU AGPL v3')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(SkyMapAssets.agplLicense),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load license: ${snap.error}'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snap.data ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
            ),
          );
        },
      ),
    );
  }
}

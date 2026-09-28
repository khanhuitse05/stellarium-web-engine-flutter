import 'package:flutter/material.dart';
import 'pages/embedded_map_page.dart';
import 'pages/observatory_page.dart';
import 'pages/telescope_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MlastroSkymapExampleApp());
}

class MlastroSkymapExampleApp extends StatelessWidget {
  const MlastroSkymapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLASTRO Sky Map Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090C15),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E66FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const ExampleHubPage(),
    );
  }
}

class ExampleHubPage extends StatelessWidget {
  const ExampleHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MLASTRO Sky Map Examples'),
        backgroundColor: const Color(0xFF101524),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B284F), Color(0xFF0E1428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334A8A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'STELLARIUM WEB ENGINE',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'High-Performance WebGL Astronomy Sky Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Featuring real-time celestial search, horizontal (Alt/Az) coordinates, rich object details, dynamic styling, time simulation, and telescope mount telemetry.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E66FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.rocket_launch, size: 18),
                  label: const Text('Launch Full Observatory'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ObservatoryPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'DEMONSTRATION SCENARIOS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Demo 1: Full Interactive Observatory
          _DemoCard(
            title: '1. Flagship Interactive Observatory',
            subtitle:
                'Full-screen planetarium with instant search, category filters, expandable astronomical ephemeris (RA/Dec, Alt/Az), time machine, and Red Night Vision mode.',
            icon: Icons.nightlife,
            accentColor: Colors.cyanAccent,
            tags: const ['Search & Filters', 'Object Details', 'Styles & Layers', 'Night Vision'],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ObservatoryPage()),
            ),
          ),
          const SizedBox(height: 14),
          // Demo 2: Telescope GOTO & Slew Simulator
          _DemoCard(
            title: '2. Telescope Mount Telemetry & GOTO',
            subtitle:
                'Split-view astrophotography dashboard featuring live crosshair reticle streaming, simulated slew physics, target catalog, and manual N/S/E/W slew controls.',
            icon: Icons.track_changes,
            accentColor: Colors.lightGreenAccent,
            tags: ['Position Stream', 'GOTO Kinematics', 'Mount Slew', 'Crosshairs'],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelescopeDashboardPage()),
            ),
          ),
          const SizedBox(height: 14),
          // Demo 3: Embedded Sky Map Card
          _DemoCard(
            title: '3. Embedded Sky Map Component',
            subtitle:
                'Demonstrates integrating the sky map as an embedded widget inside standard app cards, target planners, and observation session logs.',
            icon: Icons.dashboard_customize,
            accentColor: Colors.purpleAccent,
            tags: ['Embedded Card', 'Presets', 'Target Planner'],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmbeddedMapPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tags,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF131929),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    radius: 20,
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

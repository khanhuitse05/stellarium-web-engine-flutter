import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class EmbeddedMapPage extends StatefulWidget {
  const EmbeddedMapPage({super.key});

  @override
  State<EmbeddedMapPage> createState() => _EmbeddedMapPageState();
}

class _EmbeddedMapPageState extends State<EmbeddedMapPage> {
  late final SkyMapCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SkyMapCubit(
      initialConfig: SkyMapConfig.minimalist(),
    )..start();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Embedded Sky Map Component'),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TARGET OBSERVATION PLANNER',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Demonstrates embedding SkyMapWebView directly inside a standard Flutter card alongside target metadata, logs, and exposure settings.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Embedded Sky Map Card
          Container(
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                SkyMapWebView(cubit: _cubit),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Interactive WebGL Card',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quick Target Selection Actions
          const Text(
            'FAST TARGET FLY-TO',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('M 42 Orion'),
                avatar: const Icon(Icons.blur_on, size: 16),
                onPressed: () => _cubit.centerOnObject(
                  const SkyObject(
                    id: 'M 42',
                    name: 'Orion Nebula',
                    kind: SkyObjectKind.messier,
                    raHours: 5.588,
                    decDeg: -5.39,
                  ),
                ),
              ),
              ActionChip(
                label: const Text('M 31 Andromeda'),
                avatar: const Icon(Icons.blur_circular, size: 16),
                onPressed: () => _cubit.centerOnObject(
                  const SkyObject(
                    id: 'M 31',
                    name: 'Andromeda Galaxy',
                    kind: SkyObjectKind.messier,
                    raHours: 0.712,
                    decDeg: 41.27,
                  ),
                ),
              ),
              ActionChip(
                label: const Text('Jupiter'),
                avatar: const Icon(Icons.public, size: 16),
                onPressed: () => _cubit.centerOnObject(
                  const SkyObject(
                    id: 'Jupiter',
                    name: 'Jupiter',
                    kind: SkyObjectKind.planet,
                    raHours: 4.12,
                    decDeg: 19.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Style presets toggle
          const Text(
            'CARD RENDERING STYLE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _cubit.updateConfig(SkyMapConfig.minimalist()),
                  child: const Text('Minimalist', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _cubit.updateConfig(SkyMapConfig.stargazing()),
                  child: const Text('Stargaze', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _cubit.updateConfig(SkyMapConfig.planetarium()),
                  child: const Text('Planetarium', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

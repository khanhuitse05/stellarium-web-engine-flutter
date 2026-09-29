import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

import '../widgets/expanded_object_detail_sheet.dart';
import '../widgets/location_selector_dialog.dart';
import '../widgets/sky_map_style_sheet.dart';
import '../widgets/time_machine_dock.dart';

class ObservatoryPage extends StatefulWidget {
  const ObservatoryPage({super.key});

  @override
  State<ObservatoryPage> createState() => _ObservatoryPageState();
}

class _ObservatoryPageState extends State<ObservatoryPage> {
  late final SkyMapCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SkyMapCubit()..start();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SkyMapCubit, SkyMapState>(
        builder: (context, state) {
          final isNight = state.config.nightMode;
          final bottomPadding = MediaQuery.paddingOf(context).bottom;

          return Scaffold(
            backgroundColor:
                isNight ? const Color(0xFF0F0000) : const Color(0xFF05070D),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Sky Map WebGL View
                SkyMapWebView(cubit: _cubit),

                // Top Glassmorphic Navigation Bar
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 12,
                  right: 12,
                  child: _TopBar(cubit: _cubit, state: state, isNight: isNight),
                ),

                // Right Camera & Direction Controls
                Positioned(
                  right: 12,
                  top: MediaQuery.paddingOf(context).top + 76,
                  child: _CameraControls(cubit: _cubit, isNight: isNight),
                ),

                // Bottom Content: Selected Object Panel OR Time Machine Dock
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12 + bottomPadding,
                  child: state.selected != null
                      ? SkyObjectPanel(
                          object: state.selected!,
                          onClose: () => _cubit.deselectObject(),
                          onCopyCoordinates: () => copySkyObjectCoordinates(
                            context,
                            state.selected!,
                          ),
                          onMoreDetails: () => ExpandedObjectDetailSheet.show(
                            context,
                            object: state.selected!,
                            isNight: isNight,
                            onCenterOnObject: () =>
                                _cubit.centerOnObject(state.selected!),
                          ),
                          onGoto: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Slewing telescope to ${state.selected!.name}…',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        )
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: TimeMachineDock(cubit: _cubit),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.cubit,
    required this.state,
    required this.isNight,
  });

  final SkyMapCubit cubit;
  final SkyMapState state;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isNight
          ? const Color(0xDD200303)
          : Colors.black.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNight
              ? const Color(0x66FF2222)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Back to launcher hub
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: isNight ? const Color(0xFFFF8888) : Colors.white,
              tooltip: 'Back to demo launcher',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            // Location indicator & selector
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => LocationSelectorDialog.show(context, cubit: cubit),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color:
                          isNight ? Colors.redAccent : Colors.lightBlueAccent,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Observatory Site',
                          style: TextStyle(
                            color: isNight ? Colors.red.shade300 : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${state.observerLat.toStringAsFixed(2)}°N, ${state.observerLonEast.toStringAsFixed(2)}°E',
                          style: TextStyle(
                            color: isNight
                                ? const Color(0xFFFFCCCC)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Search button
            IconButton(
              tooltip: 'Search celestial objects',
              icon: Icon(
                Icons.search,
                color: isNight ? Colors.redAccent : Colors.cyanAccent,
              ),
              onPressed: () => SkyMapSearchSheet.show(
                context,
                packageCubit: cubit,
                onSelectObject: (obj) {
                  cubit.centerOnObject(obj);
                  cubit.selectById(obj.id);
                  cubit.resumeMapInteraction();
                },
              ),
            ),
            // Night vision toggle
            IconButton(
              tooltip: isNight
                  ? 'Switch to standard mode'
                  : 'Switch to red night mode',
              icon: Icon(
                isNight ? Icons.nightlight : Icons.nightlight_outlined,
                color: isNight ? Colors.redAccent : Colors.amberAccent,
              ),
              onPressed: () => cubit.setNightMode(!isNight),
            ),
            // Sky Map Styles & Layers
            IconButton(
              tooltip: 'Sky map display layers',
              icon: Icon(
                Icons.layers_outlined,
                color: isNight ? Colors.redAccent : Colors.lightGreenAccent,
              ),
              onPressed: () => SkyMapStyleSheet.show(context, cubit: cubit),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({required this.cubit, required this.isNight});

  final SkyMapCubit cubit;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom in
        _buildNavButton(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onTap: () => cubit.zoomIn(),
        ),
        const SizedBox(height: 6),
        // Zoom out
        _buildNavButton(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onTap: () => cubit.zoomOut(),
        ),
        const SizedBox(height: 6),
        // Reset FOV
        _buildNavButton(
          icon: Icons.fullscreen,
          tooltip: 'Default field of view',
          onTap: () => cubit.setFov(75),
        ),
        const SizedBox(height: 12),
        // Look Zenith
        _buildNavButton(
          icon: Icons.vertical_align_top,
          tooltip: 'Look Zenith (Straight up)',
          onTap: () => cubit.lookZenith(),
        ),
        const SizedBox(height: 6),
        // Cardinal Direction Compass
        PopupMenuButton<double>(
          tooltip: 'Point compass horizon',
          color: isNight ? const Color(0xFF220505) : const Color(0xFF1E222D),
          itemBuilder: (context) => [
            _buildCompassItem(0, 'North (0°)', isNight),
            _buildCompassItem(90, 'East (90°)', isNight),
            _buildCompassItem(180, 'South (180°)', isNight),
            _buildCompassItem(270, 'West (270°)', isNight),
          ],
          onSelected: (az) => cubit.lookCardinal(az),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isNight
                  ? const Color(0xDD200303)
                  : Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNight
                    ? const Color(0x66FF2222)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.explore_outlined,
              size: 20,
              color: isNight ? Colors.redAccent : Colors.tealAccent,
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<double> _buildCompassItem(
    double az,
    String label,
    bool isNight,
  ) {
    return PopupMenuItem<double>(
      value: az,
      child: Text(
        label,
        style: TextStyle(
          color: isNight ? const Color(0xFFFF9999) : Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isNight
            ? const Color(0xDD200303)
            : Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNight
              ? const Color(0x66FF2222)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 20,
          color: isNight ? const Color(0xFFFF8888) : Colors.white,
        ),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

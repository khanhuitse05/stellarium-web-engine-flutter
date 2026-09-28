import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class SkyMapStyleSheet extends StatelessWidget {
  const SkyMapStyleSheet({required this.cubit, super.key});

  final SkyMapCubit cubit;

  static Future<void> show(BuildContext context, {required SkyMapCubit cubit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkyMapStyleSheet(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = cubit.state.config;
    final isNight = config.nightMode;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF140202) : const Color(0xFF131722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isNight ? const Color(0xFF661111) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: isNight ? Colors.redAccent : Colors.lightBlueAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sky Map Styles & Layers',
                  style: TextStyle(
                    color: isNight ? const Color(0xFFFF9999) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionHeader('PRESETS', isNight),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PresetButton(
                      label: 'Stargazing',
                      icon: Icons.star_border,
                      isNight: isNight,
                      onTap: () => cubit.updateConfig(SkyMapConfig.stargazing()),
                    ),
                    _PresetButton(
                      label: 'Deep Sky',
                      icon: Icons.blur_on,
                      isNight: isNight,
                      onTap: () => cubit.updateConfig(SkyMapConfig.deepSky()),
                    ),
                    _PresetButton(
                      label: 'Planetarium',
                      icon: Icons.auto_awesome,
                      isNight: isNight,
                      onTap: () => cubit.updateConfig(SkyMapConfig.planetarium()),
                    ),
                    _PresetButton(
                      label: 'Minimalist',
                      icon: Icons.crop_free,
                      isNight: isNight,
                      onTap: () => cubit.updateConfig(SkyMapConfig.minimalist()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('VISION MODE', isNight),
                _buildSwitchTile(
                  title: 'Red Night Vision Mode',
                  subtitle:
                      'Monochromatic red overlay to preserve ocular dark adaptation.',
                  value: config.nightMode,
                  isNight: isNight,
                  icon: Icons.visibility,
                  onChanged: (val) => cubit.setNightMode(val),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('CONSTELLATIONS', isNight),
                _buildSwitchTile(
                  title: 'Constellation Lines',
                  subtitle: 'Stick figure connection lines between stars',
                  value: config.showConstellationLines,
                  isNight: isNight,
                  icon: Icons.linear_scale,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showConstellationLines: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Constellation Art',
                  subtitle: 'Mythological drawings and illustrations',
                  value: config.showConstellationArt,
                  isNight: isNight,
                  icon: Icons.brush_outlined,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showConstellationArt: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Constellation Labels',
                  subtitle: 'Names and astronomical labels',
                  value: config.showConstellationLabels,
                  isNight: isNight,
                  icon: Icons.label_outline,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showConstellationLabels: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Constellation Boundaries',
                  subtitle: 'Official 88 IAU constellation borderlines',
                  value: config.showConstellationBoundaries,
                  isNight: isNight,
                  icon: Icons.crop_square,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showConstellationBoundaries: val),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('GRIDS & COORDINATE LINES', isNight),
                _buildSwitchTile(
                  title: 'Azimuthal (Alt/Az) Grid',
                  subtitle: 'Altitude and azimuth coordinate grid lines',
                  value: config.showAzimuthalGrid,
                  isNight: isNight,
                  icon: Icons.grid_on,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showAzimuthalGrid: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Equatorial (RA/Dec) Grid',
                  subtitle: 'Celestial equator and right ascension grid',
                  value: config.showEquatorialGrid,
                  isNight: isNight,
                  icon: Icons.public,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showEquatorialGrid: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Meridian Line',
                  subtitle: 'North-Zenith-South local celestial meridian',
                  value: config.showMeridianLine,
                  isNight: isNight,
                  icon: Icons.vertical_align_center,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showMeridianLine: val),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('ENVIRONMENT & ATMOSPHERE', isNight),
                _buildSwitchTile(
                  title: 'Atmospheric Glow',
                  subtitle: 'Daylight sky scattering and twilight simulation',
                  value: config.showAtmosphere,
                  isNight: isNight,
                  icon: Icons.cloud_outlined,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showAtmosphere: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Ground Landscape / Horizon',
                  subtitle: 'Simulated terrain and horizon line',
                  value: config.showLandscape,
                  isNight: isNight,
                  icon: Icons.landscape_outlined,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showLandscape: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Milky Way Galaxy',
                  subtitle: 'Diffuse galactic plane survey rendering',
                  value: config.showMilkyWay,
                  isNight: isNight,
                  icon: Icons.all_inclusive,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showMilkyWay: val),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('CELESTIAL BODIES', isNight),
                _buildSwitchTile(
                  title: 'Stars',
                  subtitle: 'Point stars and photometric magnitudes',
                  value: config.showStars,
                  isNight: isNight,
                  icon: Icons.star,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showStars: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Deep Sky Objects (DSO)',
                  subtitle: 'Nebulae, galaxies, and star clusters',
                  value: config.showDsos,
                  isNight: isNight,
                  icon: Icons.grain,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showDsos: val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Planets & Solar System',
                  subtitle: 'Sun, Moon, and planetary ephemerides',
                  value: config.showPlanets,
                  isNight: isNight,
                  icon: Icons.brightness_2_outlined,
                  onChanged: (val) => cubit.updateConfig(
                    config.copyWith(showPlanets: val),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: isNight ? Colors.redAccent : Colors.lightBlueAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isNight,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isNight
            ? const Color(0x22FF0000)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          secondary: Icon(
            icon,
            size: 20,
            color: isNight ? Colors.red.shade300 : Colors.white70,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isNight ? const Color(0xFFFFCCCC) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          value: value,
          activeThumbColor: isNight ? Colors.redAccent : null,
          activeTrackColor: isNight ? const Color(0xFF660000) : null,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.icon,
    required this.isNight,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isNight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isNight ? const Color(0xFFFF8888) : Colors.white,
        side: BorderSide(
          color: isNight ? const Color(0xFF882222) : Colors.white24,
        ),
        backgroundColor: isNight
            ? const Color(0x33440000)
            : Colors.white.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
    );
  }
}

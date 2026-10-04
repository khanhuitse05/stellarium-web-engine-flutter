import 'package:equatable/equatable.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';

/// Data emitted when a user clicks and holds on any point on the sky map canvas.
final class SkyPointLongPressEvent extends Equatable {
  const SkyPointLongPressEvent({
    required this.aboveHorizon,
    required this.raHours,
    required this.decDeg,
    required this.altDeg,
    required this.azDeg,
    this.object,
  });

  /// Whether the clicked point is above the local observer's horizon (`altDeg > 0`).
  final bool aboveHorizon;

  /// Right ascension in hours [0, 24).
  final double raHours;

  /// Declination in degrees [-90, +90].
  final double decDeg;

  /// Altitude in degrees [-90, +90].
  final double altDeg;

  /// Azimuth in degrees [0, 360).
  final double azDeg;

  /// Snapped catalog object if held directly on or near a known target.
  final SkyObject? object;

  @override
  List<Object?> get props => [
        aboveHorizon,
        raHours,
        decDeg,
        altDeg,
        azDeg,
        object,
      ];
}

import 'package:equatable/equatable.dart';

/// Equatorial position of a connected telescope mount, when available.
final class SkyMapTelescopePosition extends Equatable {
  const SkyMapTelescopePosition({
    required this.raHours,
    required this.decDeg,
    this.isTracking = false,
    this.isSlewing = false,
  });

  final double raHours;
  final double decDeg;
  final bool isTracking;
  final bool isSlewing;

  @override
  List<Object?> get props => [raHours, decDeg, isTracking, isSlewing];
}

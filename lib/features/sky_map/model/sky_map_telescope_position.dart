import 'package:equatable/equatable.dart';

/// Equatorial position of a connected telescope mount, when available.
final class SkyMapTelescopePosition extends Equatable {
  const SkyMapTelescopePosition({
    required this.raHours,
    required this.decDeg,
  });

  final double raHours;
  final double decDeg;

  @override
  List<Object?> get props => [raHours, decDeg];
}

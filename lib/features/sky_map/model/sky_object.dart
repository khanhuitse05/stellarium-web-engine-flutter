import 'package:equatable/equatable.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

class SkyObject extends Equatable {
  const SkyObject({
    required this.id,
    required this.name,
    required this.kind,
    required this.raHours,
    required this.decDeg,
    this.magnitude,
  });

  final String id;
  final String name;
  final SkyObjectKind kind;
  final double raHours;
  final double decDeg;
  final double? magnitude;

  @override
  List<Object?> get props => [id, name, kind, raHours, decDeg, magnitude];
}

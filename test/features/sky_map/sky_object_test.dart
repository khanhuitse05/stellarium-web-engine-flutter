import 'package:flutter_test/flutter_test.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

void main() {
  group('SkyObject', () {
    test('isAboveHorizon returns true when altDeg > 0', () {
      const objVisible = SkyObject(
        id: 'M 42',
        name: 'Orion Nebula',
        kind: SkyObjectKind.messier,
        raHours: 5.588,
        decDeg: -5.39,
        altDeg: 45.2,
        azDeg: 180.0,
      );
      expect(objVisible.isAboveHorizon, isTrue);

      const objBelow = SkyObject(
        id: 'M 31',
        name: 'Andromeda',
        kind: SkyObjectKind.messier,
        raHours: 0.712,
        decDeg: 41.27,
        altDeg: -15.4,
        azDeg: 340.0,
      );
      expect(objBelow.isAboveHorizon, isFalse);
    });

    test('compassDirection returns correct cardinal and ordinal abbreviations', () {
      SkyObject makeWithAz(double az) => SkyObject(
            id: 'test',
            name: 'test',
            kind: SkyObjectKind.star,
            raHours: 0,
            decDeg: 0,
            azDeg: az,
          );

      expect(makeWithAz(0).compassDirection, 'N');
      expect(makeWithAz(358).compassDirection, 'N');
      expect(makeWithAz(90).compassDirection, 'E');
      expect(makeWithAz(180).compassDirection, 'S');
      expect(makeWithAz(270).compassDirection, 'W');
      expect(makeWithAz(45).compassDirection, 'NE');
      expect(makeWithAz(135).compassDirection, 'SE');
      expect(makeWithAz(225).compassDirection, 'SW');
      expect(makeWithAz(315).compassDirection, 'NW');
    });

    test('retains constellation, aliases, and type metadata', () {
      const obj = SkyObject(
        id: 'M 42',
        name: 'Orion Nebula',
        kind: SkyObjectKind.messier,
        raHours: 5.588,
        decDeg: -5.39,
        magnitude: 4.0,
        constellation: 'Ori',
        typeDescription: 'Diffuse Nebula',
        distance: 1344.0,
        aliases: ['M 42', 'NGC 1976', 'Great Orion Nebula'],
      );

      expect(obj.constellation, 'Ori');
      expect(obj.typeDescription, 'Diffuse Nebula');
      expect(obj.distance, 1344.0);
      expect(obj.aliases, contains('Great Orion Nebula'));
      expect(obj.kind, SkyObjectKind.messier);
    });
  });
}

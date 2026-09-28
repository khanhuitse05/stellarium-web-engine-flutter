class ObservatoryPreset {
  const ObservatoryPreset({
    required this.name,
    required this.locationName,
    required this.latitude,
    required this.longitudeEast,
    required this.elevationMeters,
    required this.description,
  });

  final String name;
  final String locationName;
  final double latitude;
  final double longitudeEast;
  final int elevationMeters;
  final String description;

  static const List<ObservatoryPreset> presets = [
    ObservatoryPreset(
      name: 'Mauna Kea Observatories',
      locationName: 'Hawaii, USA',
      latitude: 19.8206,
      longitudeEast: -155.4681,
      elevationMeters: 4205,
      description: 'One of the premier optical/infrared observatory sites on Earth.',
    ),
    ObservatoryPreset(
      name: 'Paranal Observatory (VLT)',
      locationName: 'Atacama Desert, Chile',
      latitude: -24.6272,
      longitudeEast: -70.4042,
      elevationMeters: 2635,
      description: 'Home of ESO Very Large Telescope with pristine dark skies.',
    ),
    ObservatoryPreset(
      name: 'Roque de los Muchachos',
      locationName: 'La Palma, Canary Islands',
      latitude: 28.7567,
      longitudeEast: -17.8850,
      elevationMeters: 2396,
      description: 'Top European Northern Observatory above cloud inversion layers.',
    ),
    ObservatoryPreset(
      name: 'Royal Observatory Greenwich',
      locationName: 'London, United Kingdom',
      latitude: 51.4769,
      longitudeEast: 0.0005,
      elevationMeters: 46,
      description: 'Historic prime meridian reference (0° Longitude).',
    ),
    ObservatoryPreset(
      name: 'Hanoi',
      locationName: 'Vietnam',
      latitude: 21.0285,
      longitudeEast: 105.8542,
      elevationMeters: 10,
      description: 'Northern Vietnam urban stargazing and planetary observations.',
    ),
    ObservatoryPreset(
      name: 'Tokyo',
      locationName: 'Japan',
      latitude: 35.6762,
      longitudeEast: 139.6503,
      elevationMeters: 40,
      description: 'Metropolitan observations of Moon, planets, and bright stars.',
    ),
    ObservatoryPreset(
      name: 'New York City',
      locationName: 'USA',
      latitude: 40.7128,
      longitudeEast: -74.0060,
      elevationMeters: 10,
      description: 'East coast metropolitan observing.',
    ),
    ObservatoryPreset(
      name: 'Sydney Observatory',
      locationName: 'Australia',
      latitude: -33.8596,
      longitudeEast: 151.2052,
      elevationMeters: 42,
      description: 'Southern hemisphere skies overlooking the Southern Cross & Magellanic clouds.',
    ),
  ];
}

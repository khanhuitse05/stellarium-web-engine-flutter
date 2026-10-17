import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

void main() {
  const testObject = SkyObject(
    id: 'M 42',
    name: 'Orion Nebula',
    kind: SkyObjectKind.messier,
    raHours: 5.588,
    decDeg: -5.39,
  );

  Widget buildPanel({required double width, VoidCallback? onCenter}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SkyObjectPanel(
              object: testObject,
              onMoreDetails: () {},
              onCenterInFov: onCenter ?? () {},
              onGoto: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('SkyObjectPanel shows icon only for details and center when width < 360',
      (tester) async {
    // Width 320 (< 360)
    await tester.pumpWidget(buildPanel(width: 320));
    await tester.pumpAndSettle();

    // Details button icon should be present, but label 'Details' should not
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Details'), findsNothing);

    // Center button icon should be present, but label 'Center' should not
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    expect(find.text('Center'), findsNothing);

    // Goto button still has text
    expect(find.text('Goto'), findsOneWidget);

    // Details and Center buttons should be compact (width 48), leaving more space for Goto
    final detailsFinder = find.ancestor(
      of: find.byIcon(Icons.info_outline_rounded),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(detailsFinder.first).width, 48.0);

    final centerFinder = find.ancestor(
      of: find.byIcon(Icons.center_focus_strong_rounded),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(centerFinder.first).width, 48.0);

    final gotoWidth = tester.getSize(find.widgetWithText(FilledButton, 'Goto')).width;
    expect(gotoWidth, greaterThan(150.0));
  });

  testWidgets('SkyObjectPanel shows label and icon for details and center when width >= 360',
      (tester) async {
    // Width 500 (>= 360)
    await tester.pumpWidget(buildPanel(width: 500));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    expect(find.text('Center'), findsOneWidget);

    expect(find.text('Goto'), findsOneWidget);
  });

  testWidgets('SkyObjectPanel defaults to expanded for SkyObjectKind.customPoint',
      (tester) async {
    const customPoint = SkyObject(
      id: 'custom_point_12_34',
      name: 'Custom Point',
      kind: SkyObjectKind.customPoint,
      raHours: 12.0,
      decDeg: 34.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyObjectPanel(
            object: customPoint,
            expandedBuilder: (context, obj) => const Text('Expanded Content Here'),
            onGoto: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Expanded content should be visible immediately for customPoint
    expect(find.text('Expanded Content Here'), findsOneWidget);
    expect(find.text('Less'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
  });

  testWidgets('SkyObjectPanel defaults to collapsed for non-customPoint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyObjectPanel(
            object: testObject, // SkyObjectKind.messier
            expandedBuilder: (context, obj) => const Text('Expanded Content Here'),
            onGoto: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Expanded content should NOT be visible by default for standard objects
    expect(find.text('Expanded Content Here'), findsNothing);
    expect(find.text('Details'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}

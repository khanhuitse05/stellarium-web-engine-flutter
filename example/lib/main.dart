import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MlastroSkymapExampleApp());
}

class MlastroSkymapExampleApp extends StatelessWidget {
  const MlastroSkymapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLASTRO Sky Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const SkyMapPage(),
    );
  }
}

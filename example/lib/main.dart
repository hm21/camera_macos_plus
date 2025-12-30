import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'main_container_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      home: MainContainerWidget(),
    );
  }
}

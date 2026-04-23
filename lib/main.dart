import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/word_search_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(const WordTrailApp());
}

import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../screens/home_page.dart';
import '../screens/splash_intro_page.dart';
import 'app_theme.dart';

class WordTrailApp extends StatefulWidget {
  const WordTrailApp({super.key});

  @override
  State<WordTrailApp> createState() => _WordTrailAppState();
}

class _WordTrailAppState extends State<WordTrailApp> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordTrail',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SplashIntroPage(
        controller: _controller,
        child: HomePage(controller: _controller),
      ),
    );
  }
}

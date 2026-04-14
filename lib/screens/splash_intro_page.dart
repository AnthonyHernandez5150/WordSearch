import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_colors.dart';
import '../controllers/game_controller.dart';

class SplashIntroPage extends StatefulWidget {
  const SplashIntroPage({
    super.key,
    required this.controller,
    required this.child,
  });

  final GameController controller;
  final Widget child;

  @override
  State<SplashIntroPage> createState() => _SplashIntroPageState();
}

class _SplashIntroPageState extends State<SplashIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _copyFade;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoLift = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _copyFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 1.0, curve: Curves.easeOut),
    );
    _queueFinish();
  }

  Future<void> _queueFinish() async {
    await _controller.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _finish();
  }

  void _finish() {
    if (_finished || !mounted) {
      return;
    }
    _finished = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return widget.child;
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: wtBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: _finish,
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: wtAppBackgroundGradient),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Positioned(
                  top: -120,
                  left: -80,
                  child: _SplashGlow(
                    color: Color(0x3072F5C8),
                    size: 320,
                  ),
                ),
                const Positioned(
                  right: -90,
                  bottom: -120,
                  child: _SplashGlow(
                    color: Color(0x2E9A5BFF),
                    size: 340,
                  ),
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Opacity(
                            opacity: _logoFade.value,
                            child: Transform.translate(
                              offset: Offset(0, _logoLift.value),
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 212,
                                  height: 212,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(48),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: wtCyan.withValues(alpha: 0.11),
                                        blurRadius: 46,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/branding/wordtrail_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: _copyFade.value,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - _copyFade.value)),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        'Word',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: wtWhite,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return wtTrailGradient.createShader(
                                            Rect.fromLTWH(
                                              0,
                                              0,
                                              bounds.width,
                                              bounds.height,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Trail',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                color: wtWhite,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  RichText(
                                    text: const TextSpan(
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: 'FIND WORDS. ',
                                          style: TextStyle(
                                            color: Color(0xCCF5F7FB),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.9,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'FOLLOW THE PATH.',
                                          style: TextStyle(
                                            color: wtMint,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

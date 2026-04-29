import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeOpacity;

  late AnimationController _textController;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;

  late AnimationController _shimmerController;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  late AnimationController _loadingController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ).drive(Tween<double>(begin: 0.3, end: 1.0));
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _badgeScale = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));
    _badgeOpacity = CurvedAnimation(
      parent: _badgeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleSlide = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ).drive(Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero));
    _titleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));
    _subtitleSlide = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ).drive(Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero));
    _subtitleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ).drive(Tween<double>(begin: 1.0, end: 1.12));

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _badgeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _textController.forward();
    });

    // Navigate to Login after splash (2.8s)
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _badgeController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    // Responsive sizing
    final logoCardSize = isTablet ? 140.0 : 110.0;
    final badgeSize = isTablet ? 52.0 : 40.0;
    final badgeIconSize = isTablet ? 28.0 : 22.0;
    final chartIconSize = isTablet ? 52.0 : 40.0;
    final titleFontSize = isTablet ? 34.0 : 26.0;
    final subtitleFontSize = isTablet ? 17.0 : 14.0;
    final stackSize = logoCardSize + badgeSize * 0.5;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F2F8), Color(0xFFE8EBF5), Color(0xFFF4F5FA)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: ParticlePainter(_particleController.value),
                );
              },
            ),

            // Main content — centered with maxWidth constraint for tablet
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with badge
                      SizedBox(
                        width: stackSize,
                        height: stackSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Logo card
                            AnimatedBuilder(
                              animation: _logoController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Transform.scale(
                                    scale: _logoScale.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  return Container(
                                    width: logoCardSize,
                                    height: logoCardSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 30 : 24,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4F5BD5,
                                          ).withValues(alpha: 0.12),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: -2,
                                          offset: const Offset(-4, -4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 30 : 24,
                                      ),
                                      child: Stack(
                                        children: [
                                          child!,
                                          Positioned.fill(
                                            child: AnimatedBuilder(
                                              animation: _shimmerController,
                                              builder: (context, _) {
                                                final shimmerPos =
                                                    _shimmerController.value *
                                                        3 -
                                                    1;
                                                return ShaderMask(
                                                  shaderCallback: (bounds) {
                                                    return LinearGradient(
                                                      begin: Alignment(
                                                        shimmerPos - 0.3,
                                                        -0.5,
                                                      ),
                                                      end: Alignment(
                                                        shimmerPos + 0.3,
                                                        0.5,
                                                      ),
                                                      colors: [
                                                        Colors.white.withValues(
                                                          alpha: 0.0,
                                                        ),
                                                        Colors.white.withValues(
                                                          alpha: 0.25,
                                                        ),
                                                        Colors.white.withValues(
                                                          alpha: 0.0,
                                                        ),
                                                      ],
                                                    ).createShader(bounds);
                                                  },
                                                  child: Container(
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 8),
                                          _buildSparkle(isTablet ? 8 : 6),
                                          const SizedBox(width: 6),
                                          _buildSparkle(isTablet ? 5 : 4),
                                        ],
                                      ),
                                      SizedBox(height: isTablet ? 6 : 4),
                                      Icon(
                                        Icons.show_chart_rounded,
                                        size: chartIconSize,
                                        color: const Color(0xFF2D3A8C),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _badgeController,
                                  _pulseController,
                                ]),
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _badgeOpacity.value,
                                    child: Transform.scale(
                                      scale:
                                          _badgeScale.value * _pulseScale.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: badgeSize,
                                  height: badgeSize,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF5B6EE8),
                                        Color(0xFF3D4FBF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 16 : 12,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4F5BD5,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.query_stats_rounded,
                                    color: Colors.white,
                                    size: badgeIconSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isTablet ? 48 : 36),

                      // Title
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _titleOpacity,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'Analytics Dashboard',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1F3C),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Subtitle
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _subtitleOpacity,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'Precision Analytics for Modern Enterprise',
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8A93B2),
                            letterSpacing: 0.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading bar at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _loadingController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: Curves.easeInOut.transform(_loadingController.value),
                    minHeight: isTablet ? 4 : 3,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F5BD5),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(double size) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final t = _shimmerController.value * 2 * math.pi;
        final opacity = (math.sin(t) * 0.4 + 0.6).clamp(0.2, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xFF4F5BD5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Floating particles painter
class ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> _particles;

  ParticlePainter(this.progress)
    : _particles = List.generate(18, (i) => _Particle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = size.height - t * (size.height + 40) + 20;
      final opacity = (math.sin(t * math.pi) * 0.18).clamp(0.0, 0.18);
      final paint = Paint()
        ..color = const Color(0xFF4F5BD5).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double offset;
  final double radius;

  _Particle(int seed)
    : x = ((seed * 137.508) % 100) / 100,
      offset = ((seed * 61.803) % 100) / 100,
      radius = 2.0 + (seed % 5) * 1.2;
}

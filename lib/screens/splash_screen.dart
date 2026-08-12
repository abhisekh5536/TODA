import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A premium animated splash screen for TODA.
/// Shows a gradient background, animated glow orbs, the app icon with a
/// pulsing ring, the "TODA" title with a slide-in, and a sleek progress bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Animation controllers ---
  late final AnimationController _glowCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _titleCtrl;
  late final AnimationController _subCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _checkCtrl;

  // --- Tweens ---
  late final Animation<double> _glow1Op;
  late final Animation<double> _glow2Op;
  late final Animation<double> _glow1Sc;
  late final Animation<double> _glow2Sc;
  late final Animation<double> _pulseSc;
  late final Animation<double> _pulseOp;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subSlide;
  late final Animation<double> _subFade;
  late final Animation<double> _barW;
  late final Animation<double> _checkSc;
  late final Animation<double> _checkDraw;

  @override
  void initState() {
    super.initState();

    // Glow orbs — slow breathing loop
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Pulse ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Title
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Subtitle
    _subCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Progress bar
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // Checkmark
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // --- Tweens ---
    _glow1Op = Tween<double>(begin: 0.18, end: 0.38).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
    _glow2Op = Tween<double>(begin: 0.14, end: 0.30).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
    _glow1Sc = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
    _glow2Sc = Tween<double>(begin: 1.06, end: 0.94).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
    _pulseSc = Tween<double>(begin: 1.0, end: 1.20).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutCubic),
    );
    _pulseOp = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut),
    );
    _subSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _subCtrl, curve: Curves.easeOutCubic),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subCtrl, curve: Curves.easeOut),
    );
    _barW = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );
    _checkSc = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    _checkDraw = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutCubic),
    );

    // Stagger one‑shot animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _titleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _subCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _barCtrl.forward();
        _checkCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _titleCtrl.dispose();
    _subCtrl.dispose();
    _barCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F3040),
                    Color(0xFF143D52),
                    Color(0xFF0B2A3A),
                  ],
                ),
              ),
            ),
          ),

          // ── Animated glow orbs ──
          Positioned(
            top: -120,
            right: -80,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Transform.scale(
                scale: _glow1Sc.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sand.withValues(alpha: _glow1Op.value),
                        AppColors.sand.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Transform.scale(
                scale: _glow2Sc.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.terracotta
                            .withValues(alpha: _glow2Op.value),
                        AppColors.terracotta.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Small ambient particles ──
          Positioned(
            top: h * 0.20,
            left: 44,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.22 + 0.16 * _glowCtrl.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.33,
            right: 55,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.18 + 0.14 * _glowCtrl.value,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sand,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.30,
            right: 38,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.16 + 0.12 * _glowCtrl.value,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.38,
            left: 60,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.14 + 0.10 * _glowCtrl.value,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8FA28A),
                  ),
                ),
              ),
            ),
          ),

          // ── Center content ──
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Icon with pulse ring & checkmark ──
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseCtrl,
                      _checkCtrl,
                    ]),
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring
                        Transform.scale(
                          scale: _pulseSc.value,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.sand.withValues(
                                  alpha: _pulseOp.value,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Outer gradient ring
                        Container(
                          width: 108,
                          height: 108,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE3AE8F),
                                Color(0xFFA56F63),
                              ],
                            ),
                          ),
                        ),
                        // Inner circle + checkmark
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.deepTeal,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sand
                                    .withValues(alpha: 0.28),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: _checkSc.value,
                              child: CustomPaint(
                                size: const Size(38, 38),
                                painter: _CheckPainter(
                                  progress: _checkDraw.value,
                                  color: AppColors.sand,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── "TODA" title ──
                  AnimatedBuilder(
                    animation: _titleCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _titleFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFE4C4),
                                Color(0xFFD99B7F),
                                Color(0xFFC8A96B),
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'TODA',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Tagline ──
                  AnimatedBuilder(
                    animation: _subCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _subFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _subSlide.value),
                        child: const Text(
                          'Organize your day, beautifully',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: Color(0xFFA9BFC4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // ── Progress bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 32),
                    child: AnimatedBuilder(
                      animation: _barCtrl,
                      builder: (_, __) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _barW.value,
                              minHeight: 3.5,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.07,
                              ),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFD99B7F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws an animated checkmark stroke.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.82, size.height * 0.28);

    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;
    final total = metrics.first.length;
    canvas.drawPath(
      metrics.first.extractPath(0, total * progress.clamp(0.0, 1.0)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

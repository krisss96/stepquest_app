import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class BattlePage extends StatelessWidget {
  final double playerProgress;
  final double rivalProgress;
  final Color rivalColor;
  final VoidCallback? onIncrementProgress;

  const BattlePage({
    super.key,
    required this.playerProgress,
    required this.rivalProgress,
    required this.rivalColor,
    this.onIncrementProgress,
  });

  @override
  Widget build(BuildContext context) {
    // Math: Convert meters (0-500) to Alignment (-1.0 to 1.0)
    final double playerFactor = (playerProgress / 500).clamp(0.0, 0.9);
    final double rivalFactor = (rivalProgress / 500).clamp(0.0, 0.9);
    double playerAlign = playerFactor * 2 - 1;
    double rivalAlign = rivalFactor * 2 - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7CFDD8),
                Color(0xFF2D6253),
                Color(0xFF18372E),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 70),

                // HEADER - Updated with Swords Emojis and Specialized Font
                ClipPath(
                  clipper: RibbonClipper(),
                  child: AnimatedBattleBanner(
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      // Darker charcoal gradient for a more "Epic" feel
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("⚔️", style: TextStyle(fontSize: 26, decoration: TextDecoration.none)),
                            SizedBox(width: 12),
                            Text(
                              "BATTLE",
                              style: GoogleFonts.kodeMono(
                                color: Colors.white,
                                fontSize: 32,
                                letterSpacing: 5.0,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("⚔️", style: TextStyle(fontSize: 26, decoration: TextDecoration.none)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // VS BOX
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassBox(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // PLAYER
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 3,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),

                          Text(
                            "V S",
                            style: GoogleFonts.geologica(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),

                          // RIVAL
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: rivalColor,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.android,
                                size: 50,
                                color: rivalColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // PLAYER BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassBox(
                    borderColor: Colors.blueAccent,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // THE TRAIL
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: playerFactor,
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(alpha: 0.6),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // FINISH LINE
                          Align(
                            alignment: const Alignment(0.8, 0),
                            child: Container(
                              width: 35,
                              height: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/finish.png'),
                                  fit: BoxFit.cover,
                                  repeat: ImageRepeat.repeatY,
                                ),
                              ),
                            ),
                          ),
                          // RUNNER
                          Align(
                            alignment: Alignment(playerAlign, 0),
                            child: Image.asset(
                              'assets/runner.png',
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BOT BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassBox(
                    borderColor: rivalColor,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          //  TRAIL
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: rivalFactor,
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    colors: [
                                      rivalColor.withValues(alpha: 0.2),
                                      rivalColor,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rivalColor.withValues(alpha: 0.6),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // FINISH LINE
                          Align(
                            alignment: const Alignment(0.8, 0),
                            child: Container(
                              width: 35,
                              height: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/finish.png'),
                                  fit: BoxFit.cover,
                                  repeat: ImageRepeat.repeatY,
                                ),
                              ),
                            ),
                          ),
                          // RUNNER
                          Align(
                            alignment: Alignment(rivalAlign, 0),
                            child: Image.asset(
                              'assets/runner.png',
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // CHART WIDGETS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: StatCard(
                            label: "${(playerProgress / 1000).toStringAsFixed(1)}K / 0.5K",
                            progress: (playerProgress / 500).clamp(0.0, 1.0),
                            color: Colors.blueAccent,
                            icon: Icons.person,
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: StatCard(
                            label: "${(rivalProgress / 1000).toStringAsFixed(1)}K / 0.5K",
                            progress: (rivalProgress / 500).clamp(0.0, 1.0),
                            color: rivalColor,
                            icon: Icons.android,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          )
      ),
    );
  }
}

class AnimatedBattleBanner extends StatefulWidget {
  final Widget child;

  const AnimatedBattleBanner({super.key, required this.child});

  @override
  State<AnimatedBattleBanner> createState() => _AnimatedBattleBannerState();
}

class _AnimatedBattleBannerState extends State<AnimatedBattleBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value * 2 * 3.1415926535897932;
        final sway = math.sin(t) * 0.012;
        final lift = math.cos(t) * 1.8;

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.rotate(
            angle: sway,
            child: child,
          ),
        );
      },
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const GlassBox({super.key, required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              color: color ?? Colors.white.withValues(alpha: 0.3),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.white10,
                      color: color,
                    ),
                  ),
                  Icon(icon, color: color, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.geologica(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double notchWidth = 30.0;
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - notchWidth, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(notchWidth, size.height / 2);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
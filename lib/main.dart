import 'package:flutter/material.dart';
import 'package:stacked_carousel/stacked_carousel.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const CarouselDemoPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo page
// ─────────────────────────────────────────────────────────────────────────────
class CarouselDemoPage extends StatefulWidget {
  const CarouselDemoPage({super.key});

  @override
  State<CarouselDemoPage> createState() => _CarouselDemoPageState();
}

class _CarouselDemoPageState extends State<CarouselDemoPage> {
  final _controller = StackedCarouselController();
  FlyDirection _flyDirection = FlyDirection.end;
  TextDirection _textDirection = TextDirection.rtl;

  static const _cards = [
    _CardData(
      gradient: [Color(0xFF6C63FF), Color(0xFF3B1F8C)],
      emoji: '🌊',
      title: 'Ocean Vibes',
      subtitle: 'Deep blue serenity',
    ),
    _CardData(
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      emoji: '🔥',
      title: 'Flame Energy',
      subtitle: 'Bold and passionate',
    ),
    _CardData(
      gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      emoji: '🌿',
      title: 'Nature Fresh',
      subtitle: 'Calm and renewed',
    ),
    _CardData(
      gradient: [Color(0xFFF093FB), Color(0xFFF5576C)],
      emoji: '🌸',
      title: 'Blossom Pink',
      subtitle: 'Soft and dreamy',
    ),
    _CardData(
      gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      emoji: '❄️',
      title: 'Arctic Cool',
      subtitle: 'Crisp and clear',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 32, 28, 8),
              child: Text(
                'Featured',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Text(
                'Tap a card or use the buttons below.',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Directionality(
                  textDirection: _textDirection,
                  child: StackedCarousel(
                    controller: _controller,
                    // autoPlay: false,
                    autoPlayInterval: const Duration(seconds: 3),
                    animationDuration: const Duration(milliseconds: 650),
                    cardWidthFactor: 0.8,
                    cardHeight: 350,
                    isDotIndicatorEnabled: true,

                    cardAlignment: CrossAxisAlignment.start,
                    peekOffsetY: 12,
                    peekOffsetX: 80,
                    flyDirection: _flyDirection,
                    peekTiltAngle: 0.10,
                    reverseSwipeDirection: false,
                    reverseOnBack: false,
                    visibleCount: 2,
                    flyCurve: Easing.legacyAccelerate,
                    dotIndicatorActiveColor: Colors.red,
                    dotIndicatorInactiveColor: Colors.white,
                    // dotIndicatorSize: 12,
                    // dotIndicatorSpacing: 12,
                    onCardTap: (index) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tapped card $index — ${_cards[index].title}',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    items: _cards.map((c) => _DemoCard(data: c)).toList(),
                  ),
                ),
              ),
            ),
            // ── Fly direction ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _textDirection = _textDirection == TextDirection.rtl
                          ? TextDirection.ltr
                          : TextDirection.rtl;
                    }),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white54),
                      ),
                      child: Text(
                        _textDirection == TextDirection.rtl ? 'RTL' : 'LTR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: FlyDirection.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final direction = FlyDirection.values[i];
                          final selected = direction == _flyDirection;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _flyDirection = direction),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white54
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                direction.name,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Controller buttons ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Row(
                children: [
                  // Previous
                  _CtrlButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: _controller.previous,
                  ),
                  const SizedBox(width: 12),
                  // Next
                  _CtrlButton(
                    icon: Icons.arrow_forward_rounded,
                    onTap: _controller.next,
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                  // Jump-to dots
                  ...List.generate(
                    _cards.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => _controller.jumpTo(i),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white30,
                            border: Border.all(color: Colors.white54, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sample card content
// ─────────────────────────────────────────────────────────────────────────────

class _CardData {
  const _CardData({
    required this.gradient,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
  final List<Color> gradient;
  final String emoji;
  final String title;
  final String subtitle;
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.data});
  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _Circle(
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -30,
            child: _Circle(
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 40,
            child: _Circle(
              size: 100,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(data.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                // CTA pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

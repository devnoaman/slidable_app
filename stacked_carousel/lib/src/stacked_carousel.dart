// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Which direction the front card flies when it is dismissed.
enum FlyDirection { up, down }

// ─────────────────────────────────────────────────────────────────────────────
// StackedCarouselController
// ─────────────────────────────────────────────────────────────────────────────

/// External controller for [StackedCarousel].
///
/// Create one in a [StatefulWidget], pass it to [StackedCarousel.controller],
/// and call [next], [previous], or [jumpTo] from anywhere.
///
/// ```dart
/// final _controller = StackedCarouselController();
///
/// // in build:
/// StackedCarousel(controller: _controller, items: ...)
///
/// // elsewhere:
/// _controller.next();
/// ```
class StackedCarouselController {
  _StackedCarouselState? _state;

  void _attach(_StackedCarouselState s) => _state = s;
  void _detach() => _state = null;

  /// Advance to the next card (same as auto-advance).
  void next() => _state?._advance();

  /// Go back to the previous card.
  void previous() => _state?._retreat();

  /// Jump directly to [index] without animation.
  void jumpTo(int index) => _state?._jumpTo(index);

  /// The currently visible card index.
  int get currentIndex => _state?._currentIndex ?? 0;

  /// Total number of cards.
  int get itemCount => _state?.widget.items.length ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// StackedCarousel widget
// ─────────────────────────────────────────────────────────────────────────────

class StackedCarousel extends StatefulWidget {
  const StackedCarousel({
    super.key,
    required this.items,
    this.controller,
    this.onCardTap,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 600),
    this.peekOffsetY = 28.0,
    this.peekOffsetX = 0.0,
    this.peekTiltAngle = 0.12,
    this.cardWidthFactor = 1.0,
    this.cardHeight = 420.0,
    this.cardAlignment = CrossAxisAlignment.center,
    this.flyDirection = FlyDirection.up,
    this.swipeThreshold = 300.0,
    this.autoPlay = true,
    this.isDotIndicatorEnabled = true,
  });

  /// Optional external controller — use it to call [next], [previous], [jumpTo].
  final StackedCarouselController? controller;

  /// Called when a card is tapped, with the tapped card's index.
  final ValueChanged<int>? onCardTap;

  /// The list of widgets to display as cards.
  final List<Widget> items;

  /// How long to wait between auto-advances.
  final Duration autoPlayInterval;

  /// Duration of the fly-away / rise-up animation.
  final Duration animationDuration;

  /// Fraction of the parent width used by each card (0.0 – 1.0).
  final double cardWidthFactor;

  /// Explicit card height in logical pixels, independent of width.
  final double cardHeight;

  /// Horizontal alignment of the card stack within the available width.
  /// [CrossAxisAlignment.start] = left-aligned.
  /// [CrossAxisAlignment.center] = centred (default).
  final CrossAxisAlignment cardAlignment;

  /// How many pixels the peek card is offset on the Y-axis.
  final double peekOffsetY;

  /// How many pixels the peek card is offset on the X-axis.
  /// Positive = right, negative = left.
  final double peekOffsetX;

  /// Tilt angle of the peeking card in radians.
  final double peekTiltAngle;

  /// Direction the front card flies when dismissed.
  final FlyDirection flyDirection;

  /// Minimum horizontal swipe velocity (px/s) to trigger navigation.
  /// Lower = more sensitive. Defaults to 300.
  final double swipeThreshold;

  /// Whether the carousel auto-advances on a timer.
  final bool autoPlay;

  /// Whether the dot indicator is visible.
  final bool isDotIndicatorEnabled;

  @override
  State<StackedCarousel> createState() => _StackedCarouselState();
}

class _StackedCarouselState extends State<StackedCarousel>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isAnimating = false;
  bool _isReversing = false;
  Timer? _timer;

  late AnimationController _flyController;
  late Animation<double> _flyOffsetY;
  late Animation<double> _flyOpacity;
  late Animation<double> _flyScale;

  late AnimationController _riseController;
  late Animation<double> _riseOffsetY;
  late Animation<double> _riseOffsetX;
  late Animation<double> _riseTilt;
  late Animation<double> _riseScale;

  /// Short fade-in controller for the NEW peek card that appears after
  /// each transition. Starts at 1.0 so the first render is immediately visible.
  late AnimationController _peekFadeController;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _flyController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _riseController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _peekFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // first render: peek card is immediately visible
    );

    _buildTweens();

    if (widget.autoPlay && widget.items.length > 1) {
      _startTimer();
    }
  }

  // ── Tween builders ────────────────────────────────────────────────────────

  /// Forward tweens — current card flies away, next card rises from peek.
  void _buildTweens() {
    final double flySign = widget.flyDirection == FlyDirection.up ? -1.0 : 1.0;

    _flyOffsetY = Tween<double>(begin: 0, end: flySign * 500).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInBack),
    );
    _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _flyController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _flyScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeIn),
    );

    _riseOffsetY = Tween<double>(begin: widget.peekOffsetY, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseOffsetX = Tween<double>(begin: widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseTilt = Tween<double>(begin: widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
  }

  /// Reverse tweens — current card sinks to peek, previous card slides in from above.
  void _buildReverseTweens() {
    _flyOffsetY = Tween<double>(begin: 0, end: widget.peekOffsetY).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic),
    );
    _flyOpacity = Tween<double>(begin: 1, end: 1).animate(_flyController);
    _flyScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic),
    );

    _riseOffsetY =
        Tween<double>(begin: -widget.peekOffsetY * 3, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseOffsetX = Tween<double>(begin: -widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseTilt = Tween<double>(begin: -widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(StackedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
    if (oldWidget.peekOffsetX != widget.peekOffsetX ||
        oldWidget.peekOffsetY != widget.peekOffsetY ||
        oldWidget.peekTiltAngle != widget.peekTiltAngle ||
        oldWidget.flyDirection != widget.flyDirection ||
        oldWidget.animationDuration != widget.animationDuration) {
      _flyController.duration = widget.animationDuration;
      _riseController.duration = widget.animationDuration;
      _buildTweens();
    }
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.autoPlayInterval != widget.autoPlayInterval) {
      _timer?.cancel();
      if (widget.autoPlay && widget.items.length > 1) _startTimer();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _timer?.cancel();
    _flyController.dispose();
    _riseController.dispose();
    _peekFadeController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) => _advance());
  }

  Future<void> _advance() async {
    if (_isAnimating || widget.items.length <= 1) return;
    _isAnimating = true;
    _buildTweens();
    setState(() => _isReversing = false);
    _flyController.reset();
    _riseController.reset();
    await Future.wait([
      _flyController.forward(),
      Future.delayed(
        const Duration(milliseconds: 80),
        () => _riseController.forward(),
      ),
    ]);
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.items.length;
    });
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
    // Fade in the new peek card.
    _peekFadeController.forward(from: 0);
  }

  Future<void> _retreat() async {
    if (_isAnimating || widget.items.length <= 1) return;
    _isAnimating = true;
    _buildReverseTweens();
    _flyController.reset();
    _riseController.reset();
    setState(() => _isReversing = true);
    await Future.wait([
      _riseController.forward(),
      Future.delayed(
        const Duration(milliseconds: 80),
        () => _flyController.forward(),
      ),
    ]);
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.items.length) % widget.items.length;
      _isReversing = false;
    });
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
    // Fade in the new peek card.
    _peekFadeController.forward(from: 0);
  }

  void _jumpTo(int index) {
    if (index == _currentIndex || _isAnimating) return;
    setState(() {
      _currentIndex = index.clamp(0, widget.items.length - 1);
    });
  }

  /// Forward: next card (index+1). Reverse: previous card (index-1).
  int get _nextIndex => _isReversing
      ? (_currentIndex - 1 + widget.items.length) % widget.items.length
      : (_currentIndex + 1) % widget.items.length;

  // ── Build helpers ─────────────────────────────────────────────────────────

  /// Builds the two animated card widgets in the correct Z order.
  ///
  /// Forward → peek card behind (Z=0), current card on top (Z=1).
  /// Reverse → current card behind (Z=0), incoming previous card on top (Z=1).
  List<Widget> _buildCardLayers(double cardWidth, double cardHeight) {
    Widget tappable(Widget card, int index) {
      final cb = widget.onCardTap;
      if (cb == null) return card;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => cb(index),
        child: card,
      );
    }

    final Widget peekCard = widget.items.length > 1
        ? AnimatedBuilder(
            animation: Listenable.merge([_riseController, _peekFadeController]),
            builder: (context, child) {
              return Positioned(
                top: _riseOffsetY.value,
                child: Opacity(
                  // During the rise animation the fade controller is already at
                  // 1.0, so this only affects the idle appearance of new cards.
                  opacity: _peekFadeController.value,
                  child: Transform.translate(
                    offset: Offset(_riseOffsetX.value, 0),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()..rotateZ(_riseTilt.value),
                      child: Transform.scale(
                        scale: _riseScale.value,
                        child: SizedBox(
                            width: cardWidth, height: cardHeight, child: child),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: tappable(
              _CardShell(child: widget.items[_nextIndex]),
              _nextIndex,
            ),
          )
        : const SizedBox.shrink();

    final Widget currentCard = AnimatedBuilder(
      animation: _flyController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _flyOffsetY.value),
          child: Transform.scale(
            scale: _flyScale.value,
            child: Opacity(
              opacity: _flyOpacity.value,
              child:
                  SizedBox(width: cardWidth, height: cardHeight, child: child),
            ),
          ),
        );
      },
      child: tappable(
        _CardShell(child: widget.items[_currentIndex]),
        _currentIndex,
      ),
    );

    return _isReversing ? [currentCard, peekCard] : [peekCard, currentCard];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * widget.cardWidthFactor;
        final cardHeight = widget.cardHeight;

        return SizedBox(
          width: constraints.maxWidth,
          height: cardHeight + widget.peekOffsetY + 16,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -widget.swipeThreshold) {
                _advance();
              } else if (velocity > widget.swipeThreshold) {
                _retreat();
              }
            },
            child: Stack(
              alignment: widget.cardAlignment == CrossAxisAlignment.start
                  ? Alignment.topLeft
                  : Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                ..._buildCardLayers(cardWidth, cardHeight),
                if (widget.isDotIndicatorEnabled)
                  Positioned(
                    bottom: 0,
                    child: _DotsIndicator(
                      count: widget.items.length,
                      current: _currentIndex,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card shell — rounded shadow container.
// ─────────────────────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicators
// ─────────────────────────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

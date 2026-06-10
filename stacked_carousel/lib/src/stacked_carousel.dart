// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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

  /// Reactive notifier — listen to index changes without polling.
  ///
  /// ```dart
  /// _controller.indexNotifier.addListener(() {
  ///   print('Now at ${_controller.currentIndex}');
  /// });
  /// ```
  ValueNotifier<int> get indexNotifier =>
      _state?._indexNotifier ?? ValueNotifier(0);

  /// `true` when there is a next card available.
  /// Always `true` when [StackedCarousel.loop] is `true`.
  bool get canGoNext => _state?._canGoNext ?? false;

  /// `true` when there is a previous card available.
  /// Always `true` when [StackedCarousel.loop] is `true`.
  bool get canGoPrevious => _state?._canGoPrevious ?? false;
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
    this.onIndexChanged,
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
    this.visibleCount = 3,
    this.loop = true,
    this.initialIndex = 0,
    // ── Drag scrubbing ───────────────────────────────────────────────────────
    this.dragEnabled = true,
    this.dragCommitThreshold = 0.35,
    this.reverseSwipeDirection = false,

    /// When `true` (default) going back uses the distinctive sink/rise animation.
    /// When `false`, back uses the same fly-away animation as forward.
    this.reverseOnBack = true,
    // ── Exit offsets ─────────────────────────────────────────────────────────
    this.flyExitOffsetY = 500.0,
    this.flyExitOffsetX = 0.0,
    // ── Animation curves ────────────────────────────────────────────────────
    this.flyCurve = Curves.easeInBack,
    this.flyOpacityCurve = Curves.easeIn,
    this.flyOpacityInterval = const Interval(0.5, 1.0),
    this.flyScaleCurve = Curves.easeIn,
    this.riseCurve = Curves.easeOutCubic,
    this.reverseSinkCurve = Curves.easeInCubic,
    this.reverseRiseCurve = Curves.easeOutCubic,
    // ── Auto-play interaction ───────────────────────────────────────────────
    this.pauseAutoPlayOnInteraction = true,
    this.resumeAutoPlayDelay = const Duration(seconds: 5),
    // ── Swipe callbacks ───────────────────────────────────────────────────────
    this.onSwipeStart,
    this.onSwipeEnd,
    // ── Card appearance ───────────────────────────────────────────────────────
    this.cardBorderRadius = 28.0,
    this.cardShadows,
    // ── Custom indicator ──────────────────────────────────────────────────────
    this.indicatorBuilder,
    this.dotIndicatorActiveColor = Colors.white,
    this.dotIndicatorInactiveColor = Colors.grey,
    this.dotIndicatorSize = 6,
    this.dotIndicatorSpacing = 6,
  });

  /// Optional external controller — use it to call [next], [previous], [jumpTo].
  final StackedCarouselController? controller;

  /// Called when a card is tapped, with the tapped card's index.
  final ValueChanged<int>? onCardTap;

  /// Fired whenever the active index changes (advance, retreat, or jumpTo).
  final ValueChanged<int>? onIndexChanged;

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

  /// The maximum number of cards visible in the stack at once.
  final int visibleCount;

  /// Whether the carousel wraps at the ends. Set `false` for bounded flows.
  final bool loop;

  /// The index of the card shown on first render. Clamped to valid range.
  final int initialIndex;

  // ── Drag scrubbing ────────────────────────────────────────────────────────

  /// Whether dragging the card scrubs the animation interactively.
  final bool dragEnabled;

  /// Fraction of card width to drag before a release commits the transition.
  final double dragCommitThreshold;

  /// Reverses which swipe direction advances vs retreats.
  ///
  /// By default (LTR layout):
  ///   swipe left → next card, swipe right → previous card.
  ///
  /// With `reverseSwipeDirection: true`:
  ///   swipe right → next card, swipe left → previous card.
  ///
  /// Stacks with [Directionality] (RTL already flips the default).
  final bool reverseSwipeDirection;

  /// Controls the back-gesture animation style.
  ///
  /// `true` (default) — back uses the distinctive **sink + rise** animation:
  ///   the current card sinks into the peek slot while the previous card
  ///   slides in from above.
  ///
  /// `false` — back uses the same **fly-away** animation as forward:
  ///   the current card flies off-screen exactly like a forward advance,
  ///   but the index goes backward. Use this for a uniform carousel feel.
  final bool reverseOnBack;

  // ── Exit offsets ──────────────────────────────────────────────────────────

  /// How far (px) the card travels on Y during exit. Default 500.
  final double flyExitOffsetY;

  /// How far (px) the card drifts on X during exit. Default 0 (straight up/down).
  final double flyExitOffsetX;

  // ── Animation curves ──────────────────────────────────────────────────────

  final Curve flyCurve;
  final Curve flyOpacityCurve;
  final Interval flyOpacityInterval;
  final Curve flyScaleCurve;
  final Curve riseCurve;
  final Curve reverseSinkCurve;
  final Curve reverseRiseCurve;

  // ── Auto-play interaction ─────────────────────────────────────────────────

  /// Pause auto-advance when the user manually swipes, then resume after
  /// [resumeAutoPlayDelay] of inactivity.
  final bool pauseAutoPlayOnInteraction;

  /// How long after a manual swipe to wait before restarting auto-play.
  final Duration resumeAutoPlayDelay;

  // ── Swipe callbacks ────────────────────────────────────────────────────

  /// Fired when a swipe gesture begins. Wire [HapticFeedback.lightImpact]
  /// here for tactile feedback without hardcoding it in the package.
  final VoidCallback? onSwipeStart;

  /// Fired when a swipe gesture ends (committed or cancelled).
  final VoidCallback? onSwipeEnd;

  // ── Card appearance ─────────────────────────────────────────────────────

  /// Corner radius for every card. Defaults to 28.
  final double cardBorderRadius;

  /// Custom shadows for every card. `null` = package defaults.
  final List<BoxShadow>? cardShadows;

  // ── Custom indicator ─────────────────────────────────────────────────────

  /// Replaces the built-in dot indicator with any widget.
  /// Receives [count] (total cards) and [current] (active index).
  /// Set [isDotIndicatorEnabled] to `false` when using this.
  final Widget Function(int count, int current)? indicatorBuilder;

  final Color dotIndicatorActiveColor;
  final Color dotIndicatorInactiveColor;
  final double dotIndicatorSize;
  final double dotIndicatorSpacing;

  @override
  State<StackedCarousel> createState() => _StackedCarouselState();
}

class _StackedCarouselState extends State<StackedCarousel>
    with TickerProviderStateMixin {
  late int _currentIndex;
  bool _isAnimating = false;
  bool _isReversing = false;
  Timer? _timer;

  // ── Reactive index ────────────────────────────────────────────────────────
  late final ValueNotifier<int> _indexNotifier;

  // ── Bounds helpers ────────────────────────────────────────────────────────
  bool get _canGoNext => widget.loop || _currentIndex < widget.items.length - 1;
  bool get _canGoPrevious => widget.loop || _currentIndex > 0;

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _flyController;
  late Animation<double> _flyOffsetY;
  late Animation<double> _flyOffsetX;
  late Animation<double> _flyOpacity;
  late Animation<double> _flyScale;

  late AnimationController _riseController;
  late Animation<double> _riseOffsetY;
  late Animation<double> _riseOffsetX;
  late Animation<double> _riseTilt;
  late Animation<double> _riseScale;

  // ── Drag-to-scrub state ───────────────────────────────────────────────────
  bool _isDragging = false;
  bool _dragDirectionDetermined = false;
  bool _dragDirectionForward = true;
  double _accumulatedDragX = 0;
  // Set from build() so drag handlers can read it without a BuildContext.
  double _dirFactor = 1.0;
  double _cardWidth = 300.0;

  // ── Auto-play pause / resume ──────────────────────────────────────────────
  Timer? _resumeTimer;

  // ── Helper: fire index change notifications ───────────────────────────────
  void _notifyIndexChange() {
    _indexNotifier.value = _currentIndex;
    widget.onIndexChanged?.call(_currentIndex);
  }

  @override
  void initState() {
    super.initState();
    final maxIdx = (widget.items.length - 1).clamp(0, widget.items.length);
    _currentIndex = widget.initialIndex.clamp(0, maxIdx);
    _indexNotifier = ValueNotifier(_currentIndex);
    widget.controller?._attach(this);

    _flyController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _riseController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
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

    _flyOffsetY =
        Tween<double>(begin: 0, end: flySign * widget.flyExitOffsetY).animate(
      CurvedAnimation(parent: _flyController, curve: widget.flyCurve),
    );
    _flyOffsetX = Tween<double>(begin: 0, end: widget.flyExitOffsetX).animate(
      CurvedAnimation(parent: _flyController, curve: widget.flyCurve),
    );
    _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _flyController,
        curve: Interval(
          widget.flyOpacityInterval.begin,
          widget.flyOpacityInterval.end,
          curve: widget.flyOpacityCurve,
        ),
      ),
    );
    _flyScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _flyController, curve: widget.flyScaleCurve),
    );

    _riseOffsetY = Tween<double>(begin: widget.peekOffsetY, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.riseCurve),
    );
    _riseOffsetX = Tween<double>(begin: widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.riseCurve),
    );
    _riseTilt = Tween<double>(begin: widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.riseCurve),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.riseCurve),
    );
  }

  /// Reverse tweens — current card sinks to peek, previous card slides in from above.
  void _buildReverseTweens() {
    _flyOffsetY = Tween<double>(begin: 0, end: widget.peekOffsetY).animate(
      CurvedAnimation(parent: _flyController, curve: widget.reverseSinkCurve),
    );
    _flyOffsetX = Tween<double>(begin: 0, end: 0).animate(_flyController);
    _flyOpacity = Tween<double>(begin: 1, end: 1).animate(_flyController);
    _flyScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _flyController, curve: widget.reverseSinkCurve),
    );

    _riseOffsetY =
        Tween<double>(begin: -widget.peekOffsetY * 3, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.reverseRiseCurve),
    );
    _riseOffsetX = Tween<double>(begin: -widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.reverseRiseCurve),
    );
    _riseTilt = Tween<double>(begin: -widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.reverseRiseCurve),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: widget.reverseRiseCurve),
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
        oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.flyCurve != widget.flyCurve ||
        oldWidget.flyOpacityCurve != widget.flyOpacityCurve ||
        oldWidget.flyOpacityInterval != widget.flyOpacityInterval ||
        oldWidget.flyScaleCurve != widget.flyScaleCurve ||
        oldWidget.riseCurve != widget.riseCurve ||
        oldWidget.reverseSinkCurve != widget.reverseSinkCurve ||
        oldWidget.reverseRiseCurve != widget.reverseRiseCurve ||
        oldWidget.flyExitOffsetY != widget.flyExitOffsetY ||
        oldWidget.flyExitOffsetX != widget.flyExitOffsetX) {
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
    _resumeTimer?.cancel();
    _indexNotifier.dispose();
    _flyController.dispose();
    _riseController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
        widget.autoPlayInterval, (_) => _advance(fromTimer: true));
  }

  /// If [pauseAutoPlayOnInteraction] is on, stop the periodic timer and
  /// schedule a one-shot resume after [resumeAutoPlayDelay].
  void _pauseAutoPlayForInteraction() {
    if (!widget.pauseAutoPlayOnInteraction || !widget.autoPlay) return;
    _timer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(widget.resumeAutoPlayDelay, _startTimer);
  }

  Future<void> _advance({bool fromTimer = false}) async {
    if (_isAnimating || _isDragging || widget.items.length <= 1) return;
    if (!_canGoNext) return;
    if (!fromTimer) _pauseAutoPlayForInteraction();
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
    _notifyIndexChange();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
  }

  Future<void> _retreat() async {
    if (_isAnimating || _isDragging || widget.items.length <= 1) return;
    if (!_canGoPrevious) return;
    _pauseAutoPlayForInteraction();
    _isAnimating = true;
    if (widget.reverseOnBack) {
      _buildReverseTweens();
      setState(() => _isReversing = true);
    } else {
      _buildTweens();
      setState(() => _isReversing = false);
    }
    _flyController.reset();
    _riseController.reset();
    if (widget.reverseOnBack) {
      // Reverse: rise controller leads, fly follows slightly behind.
      await Future.wait([
        _riseController.forward(),
        Future.delayed(
          const Duration(milliseconds: 80),
          () => _flyController.forward(),
        ),
      ]);
    } else {
      // Same as forward: fly leads, rise follows.
      await Future.wait([
        _flyController.forward(),
        Future.delayed(
          const Duration(milliseconds: 80),
          () => _riseController.forward(),
        ),
      ]);
    }
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.items.length) % widget.items.length;
      _isReversing = false;
    });
    _notifyIndexChange();
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
  }

  void _jumpTo(int index) {
    if (index == _currentIndex || _isAnimating) return;
    final clamped = widget.loop
        ? index % widget.items.length
        : index.clamp(0, widget.items.length - 1);
    setState(() {
      _currentIndex = clamped;
      _isReversing = false;
    });
    _notifyIndexChange();
  }

  /// Forward: next card (index+1). Reverse: previous card (index-1).
  int get _nextIndex => _isReversing
      ? (_currentIndex - 1 + widget.items.length) % widget.items.length
      : (_currentIndex + 1) % widget.items.length;

  // ── Build helpers ─────────────────────────────────────────────────────────

  /// Builds the two animated card widgets in the correct Z order.
  ///
  /// [dirFactor] is +1.0 for LTR and -1.0 for RTL. It mirrors the X offset
  /// and tilt of the peek card so the stack looks natural in both directions.
  ///
  /// Forward → peek card behind (Z=0), current card on top (Z=1).
  /// Reverse → current card behind (Z=0), incoming previous card on top (Z=1).
  List<Widget> _buildCardLayers(
    double cardWidth,
    double cardHeight,
    double dirFactor,
  ) {
    Widget tappable(Widget card, int index) {
      final cb = widget.onCardTap;
      if (cb == null) return card;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => cb(index),
        child: card,
      );
    }

    final int n = widget.items.length;
    if (n == 0) return [];
    if (n == 1) {
      return [tappable(_CardShell(child: widget.items[0]), 0)];
    }

    // Allow peekCount up to visibleCount-1 regardless of item count.
    // Indices wrap via modulo, so with 2 items and visibleCount=3, the
    // third stack slot simply shows the next item again (cycled).
    final int peekCount =
        (widget.visibleCount - 1).clamp(1, widget.visibleCount - 1);
    final List<Widget> layers = [];

    Widget buildCardState(
        int actualIndex, double effectiveI, double opacity, Widget cachedCard) {
      final offsetY = effectiveI * widget.peekOffsetY;
      final offsetX = effectiveI * widget.peekOffsetX * dirFactor;
      final tilt = effectiveI * widget.peekTiltAngle * dirFactor;
      final scale = 1.0 - (0.07 * effectiveI);

      Widget card = Transform.translate(
        offset: Offset(offsetX, 0),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()..rotateZ(tilt),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: cachedCard,
            ),
          ),
        ),
      );

      if (opacity < 1.0) {
        card = Opacity(opacity: opacity, child: card);
      }

      return Positioned(
        top: offsetY,
        child: card,
      );
    }

    if (!_isReversing) {
      // Forward or rest animation
      // During forward animation one extra ghost layer fades in from behind.
      // No longer capped at n-1 so repeated items can fill the extra slot.
      final int maxK = _isAnimating ? peekCount + 1 : peekCount;

      for (int k = maxK; k >= 1; k--) {
        final int idx = (_currentIndex + k) % n;
        // Cache the card widget — passed as [child] so it isn't rebuilt each frame.
        final Widget cachedCard = tappable(
          _CardShell(
            child: widget.items[idx],
            borderRadius: widget.cardBorderRadius,
            shadows: widget.cardShadows,
            shadowOpacityFactor: (1.0 - 0.2 * (k - 1)).clamp(0.0, 1.0),
          ),
          idx,
        );
        layers.add(
          AnimatedBuilder(
            animation: _riseController,
            builder: (context, child) {
              final curveT =
                  Curves.easeOutCubic.transform(_riseController.value);
              final effectiveI = k - curveT;

              double opacity = 1.0;
              if (k == peekCount + 1) {
                opacity = curveT;
              }

              return buildCardState(idx, effectiveI, opacity, child!);
            },
            child: cachedCard,
          ),
        );
      }

      // Current (front) card — also cached.
      final Widget cachedFront = tappable(
        _CardShell(
          child: widget.items[_currentIndex],
          borderRadius: widget.cardBorderRadius,
          shadows: widget.cardShadows,
        ),
        _currentIndex,
      );
      layers.add(
        AnimatedBuilder(
          animation: _flyController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_flyOffsetX.value, _flyOffsetY.value),
              child: Transform.scale(
                scale: _flyScale.value,
                child: Opacity(
                  opacity: _flyOpacity.value,
                  child: child,
                ),
              ),
            );
          },
          child: SizedBox(
              width: cardWidth, height: cardHeight, child: cachedFront),
        ),
      );
    } else {
      // Reverse animation
      for (int k = peekCount; k >= 0; k--) {
        final int idx = (_currentIndex + k) % n;
        final Widget cachedCard = tappable(
          _CardShell(
            child: widget.items[idx],
            borderRadius: widget.cardBorderRadius,
            shadows: widget.cardShadows,
            shadowOpacityFactor: (1.0 - 0.2 * k).clamp(0.0, 1.0),
          ),
          idx,
        );
        layers.add(
          AnimatedBuilder(
            animation: _flyController,
            builder: (context, child) {
              final curveT = Curves.easeInCubic.transform(_flyController.value);
              final effectiveI = k + curveT;

              double opacity = 1.0;
              if (k == peekCount) {
                opacity = 1.0 - curveT;
              }

              return buildCardState(idx, effectiveI, opacity, child!);
            },
            child: cachedCard,
          ),
        );
      }

      final Widget cachedIncoming = tappable(
        _CardShell(
          child: widget.items[_nextIndex],
          borderRadius: widget.cardBorderRadius,
          shadows: widget.cardShadows,
        ),
        _nextIndex,
      );
      layers.add(
        AnimatedBuilder(
          animation: _riseController,
          builder: (context, child) {
            return Positioned(
              top: _riseOffsetY.value,
              child: Transform.translate(
                offset: Offset(_riseOffsetX.value * dirFactor, 0),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..rotateZ(_riseTilt.value * dirFactor),
                  child: Transform.scale(
                    scale: _riseScale.value,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: SizedBox(
              width: cardWidth, height: cardHeight, child: cachedIncoming),
        ),
      );
    }

    return layers;
  }

  // ── Drag-to-scrub handlers ─────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    if (!widget.dragEnabled || _isAnimating || widget.items.length <= 1) return;
    _isDragging = true;
    _dragDirectionDetermined = false;
    _accumulatedDragX = 0;
    widget.onSwipeStart?.call();
    _pauseAutoPlayForInteraction();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    _accumulatedDragX += details.delta.dx * _dirFactor;

    // Wait until the user has moved enough to determine direction.
    if (!_dragDirectionDetermined) {
      if (_accumulatedDragX.abs() < 6) return;
      // Negative accumulated = dragging toward next; positive = toward previous.
      _dragDirectionForward = _accumulatedDragX < 0;

      // Respect loop / bounds.
      if (_dragDirectionForward && !_canGoNext) {
        _isDragging = false;
        return;
      }
      if (!_dragDirectionForward && !_canGoPrevious) {
        _isDragging = false;
        return;
      }

      if (_dragDirectionForward) {
        _buildTweens();
        setState(() => _isReversing = false);
      } else {
        // Backward drag: use reverse or forward tweens based on flag.
        if (widget.reverseOnBack) {
          _buildReverseTweens();
          setState(() => _isReversing = true);
        } else {
          _buildTweens();
          setState(() => _isReversing = false);
        }
      }
      _flyController.reset();
      _riseController.reset();
      _dragDirectionDetermined = true;
    }

    if (!_dragDirectionDetermined) return;

    // Map accumulated drag to a 0-1 controller value.
    final fraction = (_accumulatedDragX.abs() / _cardWidth).clamp(0.0, 1.0);
    _flyController.value = fraction;
    _riseController.value = fraction;
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!_isDragging) return;
    if (!_dragDirectionDetermined) {
      _isDragging = false;
      widget.onSwipeEnd?.call();
      return;
    }

    final velocity = (details.primaryVelocity ?? 0) * _dirFactor;
    final fraction = _flyController.value;

    // Commit if dragged far enough OR flicked fast enough in the right direction.
    final bool fastFling = velocity.abs() > widget.swipeThreshold &&
        ((_dragDirectionForward && velocity < 0) ||
            (!_dragDirectionForward && velocity > 0));
    final bool shouldCommit =
        fraction >= widget.dragCommitThreshold || fastFling;

    _isDragging = false;
    _dragDirectionDetermined = false;
    _isAnimating = true;

    // Use spring physics so the commit / snap-back feels physical.
    // The spring stiffness scales with remaining distance so short snaps
    // feel snappy and long ones feel weighty.
    final double endValue = shouldCommit ? 1.0 : 0.0;
    final double dragVelocity =
        (details.primaryVelocity ?? 0).abs() / (_cardWidth * 1000);
    final spring = SpringDescription(
      mass: 1,
      stiffness: shouldCommit ? 200 : 300,
      damping: shouldCommit ? 20 : 26,
    );
    await Future.wait([
      _flyController.animateWith(
        SpringSimulation(spring, _flyController.value, endValue, dragVelocity),
      ),
      _riseController.animateWith(
        SpringSimulation(spring, _riseController.value, endValue, dragVelocity),
      ),
    ]);

    if (shouldCommit) {
      setState(() {
        if (_dragDirectionForward) {
          _currentIndex = (_currentIndex + 1) % widget.items.length;
        } else {
          _currentIndex =
              (_currentIndex - 1 + widget.items.length) % widget.items.length;
        }
        _isReversing = false;
      });
      _notifyIndexChange();
    } else {
      setState(() => _isReversing = false);
    }

    widget.onSwipeEnd?.call();
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
  }

  void _onDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _dragDirectionDetermined = false;
    setState(() => _isReversing = false);
    widget.onSwipeEnd?.call();
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    // +1 for LTR, -1 for RTL — mirrors X offsets and tilt.
    // dirFactor encodes both reading direction and the optional swipe-flip.
    // +1.0 = LTR default (left swipe → next)
    // -1.0 = RTL or reverseSwipeDirection flips it
    // If both are true they cancel out (double negation = LTR again).
    final bool effectiveReverse = (isRTL) ^ widget.reverseSwipeDirection; // XOR
    _dirFactor = effectiveReverse ? -1.0 : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * widget.cardWidthFactor;
        _cardWidth = cardWidth; // cache for drag handlers
        final cardHeight = widget.cardHeight;

        // Resolve start alignment to the correct physical side.
        final Alignment stackAlignment;
        if (widget.cardAlignment == CrossAxisAlignment.center) {
          stackAlignment = Alignment.topCenter;
        } else {
          stackAlignment = isRTL ? Alignment.topRight : Alignment.topLeft;
        }

        final int peekCount = (widget.visibleCount - 1)
            .clamp(1, widget.items.length > 1 ? widget.items.length - 1 : 1);

        return SizedBox(
          width: constraints.maxWidth,
          height: cardHeight + (widget.peekOffsetY * peekCount) + 16,
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _onDragCancel,
            child: Stack(
              alignment: stackAlignment,
              clipBehavior: Clip.none,
              children: [
                ..._buildCardLayers(cardWidth, cardHeight, _dirFactor),
                // Built-in dot indicator (can be disabled in favour of indicatorBuilder).
                if (widget.isDotIndicatorEnabled)
                  Positioned(
                    bottom: 0,
                    child: _DotsIndicator(
                      count: widget.items.length,
                      current: _currentIndex,
                      activeColor: widget.dotIndicatorActiveColor,
                      inactiveColor: widget.dotIndicatorInactiveColor,
                      dotSize: widget.dotIndicatorSize,
                      dotSpacing: widget.dotIndicatorSpacing,
                    ),
                  ),
                // Custom indicator overrides the built-in one.
                if (widget.indicatorBuilder != null)
                  Positioned(
                    bottom: 0,
                    child: widget.indicatorBuilder!(
                        widget.items.length, _currentIndex),
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
  const _CardShell({
    required this.child,
    this.borderRadius = 28.0,
    this.shadows,
    this.shadowOpacityFactor = 1.0,
  });
  final Widget child;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  /// 0.0 = fully transparent shadow, 1.0 = full opacity (used for depth fading).
  final double shadowOpacityFactor;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> effectiveShadows = shadows ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22 * shadowOpacityFactor),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08 * shadowOpacityFactor),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicators
// ─────────────────────────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotSize,
    required this.dotSpacing,
  });
  final int count;
  final int current;

  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double dotSpacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: dotSpacing / 2),
          width: active ? dotSize * 3.33 : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

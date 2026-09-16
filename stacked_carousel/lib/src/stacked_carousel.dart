// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Which direction the front card flies when it is dismissed.
///
/// Vertical values (`up`, `down`) travel [StackedCarousel.flyExitOffsetY]
/// pixels, with optional [StackedCarousel.flyExitOffsetX] horizontal drift.
///
/// Physical values (`left`, `right`, and their diagonals) always travel
/// toward that screen edge.
///
/// Directional values (`start`, `end`, and their diagonals) follow
/// [Directionality]: `start` is left in LTR and right in RTL. Pair
/// [FlyDirection.end] with [CrossAxisAlignment.start] so a stack that sits
/// on the start edge dismisses cards toward the end edge.
///
/// Horizontal travel uses [StackedCarousel.flyExitOffsetX]. If it is `0`
/// (the default), [StackedCarousel.flyExitOffsetY] is used so those
/// directions work with the default constructor values.
enum FlyDirection {
  up,
  down,
  left,
  right,
  start,
  end,
  upLeft,
  upRight,
  downLeft,
  downRight,
  upStart,
  upEnd,
  downStart,
  downEnd;

  /// Maps logical start/end values to physical left/right for [textDirection].
  FlyDirection resolve(TextDirection textDirection) {
    final rtl = textDirection == TextDirection.rtl;
    return switch (this) {
      FlyDirection.start => rtl ? FlyDirection.right : FlyDirection.left,
      FlyDirection.end => rtl ? FlyDirection.left : FlyDirection.right,
      FlyDirection.upStart => rtl ? FlyDirection.upRight : FlyDirection.upLeft,
      FlyDirection.upEnd => rtl ? FlyDirection.upLeft : FlyDirection.upRight,
      FlyDirection.downStart =>
        rtl ? FlyDirection.downRight : FlyDirection.downLeft,
      FlyDirection.downEnd =>
        rtl ? FlyDirection.downLeft : FlyDirection.downRight,
      _ => this,
    };
  }

  /// Exit translation for a card dismissed in this direction.
  Offset resolveExitOffset({
    required double offsetX,
    required double offsetY,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    // Horizontal travel falls back to the Y magnitude so left/right/diagonals
    // work when [offsetX] is left at its default of 0.
    final hx = offsetX != 0.0 ? offsetX.abs() : offsetY;
    switch (resolve(textDirection)) {
      case FlyDirection.up:
        return Offset(offsetX, -offsetY);
      case FlyDirection.down:
        return Offset(offsetX, offsetY);
      case FlyDirection.left:
        return Offset(-hx, 0);
      case FlyDirection.right:
        return Offset(hx, 0);
      case FlyDirection.upLeft:
        return Offset(-hx, -offsetY);
      case FlyDirection.upRight:
        return Offset(hx, -offsetY);
      case FlyDirection.downLeft:
        return Offset(-hx, offsetY);
      case FlyDirection.downRight:
        return Offset(hx, offsetY);
      case FlyDirection.start:
      case FlyDirection.end:
      case FlyDirection.upStart:
      case FlyDirection.upEnd:
      case FlyDirection.downStart:
      case FlyDirection.downEnd:
        // Unreachable — [resolve] always returns a physical direction.
        return Offset.zero;
    }
  }
}

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
    this.swipeThreshold = 200.0,
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

  /// Called when a card is tapped, with that card's index.
  ///
  /// Both the front card and any visible peek card behind it are tappable.
  /// Where they overlap, the topmost card wins.
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
  /// Positive = toward [Directionality] end (right in LTR, left in RTL).
  /// Negative = toward start.
  final double peekOffsetX;

  /// Tilt angle of the peeking card in radians.
  final double peekTiltAngle;

  /// Direction the front card flies when dismissed.
  ///
  /// Use [FlyDirection.start] / [FlyDirection.end] to follow [Directionality]:
  /// a card that sits on the start edge flies toward the end edge, and the
  /// mapping flips automatically in RTL.
  ///
  /// See [FlyDirection] for vertical, horizontal, diagonal, and directional
  /// options.
  final FlyDirection flyDirection;

  /// Minimum swipe velocity (px/s) that commits on release, like a fling.
  /// Lower = more sensitive. Defaults to 200.
  final double swipeThreshold;

  /// Whether the carousel auto-advances on a timer.
  final bool autoPlay;

  /// Whether the dot indicator is visible.
  final bool isDotIndicatorEnabled;

  /// The maximum number of cards visible in the stack at once.
  final int visibleCount;

  /// Whether the carousel wraps at the ends.
  ///
  /// `true` (default) — the same item list is reused: after the last card
  /// comes the first, without duplicating items in memory.
  /// `false` — a bounded list stops on the last item and rubber-bands.
  final bool loop;

  /// The index of the card shown on first render. Clamped to valid range.
  final int initialIndex;

  // ── Drag scrubbing ────────────────────────────────────────────────────────

  /// Whether dragging the card scrubs the animation interactively.
  final bool dragEnabled;

  /// Fraction of travel (see drag extent) at which a release commits.
  /// Combined with [swipeThreshold] so a short, fast fling still advances.
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
  /// `false` — back **rewinds** the forward dismiss: the card that flew off
  ///   swipes back in from the same [flyDirection] edge, and the current
  ///   card sinks into the peek slot.
  final bool reverseOnBack;

  // ── Exit offsets ──────────────────────────────────────────────────────────

  /// How far (px) the card travels on Y during a vertical or diagonal exit.
  /// Also used as the horizontal travel distance when [flyExitOffsetX] is `0`.
  /// Default 500.
  final double flyExitOffsetY;

  /// How far (px) the card travels on X during exit.
  ///
  /// For [FlyDirection.up] / [FlyDirection.down] this is optional horizontal
  /// drift (default `0` = straight).
  /// For horizontal and diagonal directions this is the primary X travel
  /// distance; when `0`, [flyExitOffsetY] is used instead.
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
  /// True when back uses a rewind: the dismissed card flies back in from
  /// [FlyDirection], while the current card sinks into the peek slot.
  bool _goingBackward = false;
  Timer? _timer;

  // ── Reactive index ────────────────────────────────────────────────────────
  late final ValueNotifier<int> _indexNotifier;
  /// Rebuilds stack layers without replacing the GestureDetector.
  final ValueNotifier<int> _layersTick = ValueNotifier(0);
  void _refreshLayers() => _layersTick.value++;

  int _cycleIndex(int i) {
    final n = widget.items.length;
    if (n <= 0) return 0;
    return (i % n + n) % n;
  }

  /// Peek / neighbour index, or `null` when [loop] is off and [offset] is
  /// outside the generated list.
  int? _indexAtOffset(int offset) {
    final i = _currentIndex + offset;
    if (widget.loop) return _cycleIndex(i);
    if (i < 0 || i >= widget.items.length) return null;
    return i;
  }

  // ── Bounds helpers ────────────────────────────────────────────────────────
  bool get _canGoNext => widget.loop || _currentIndex < widget.items.length - 1;
  bool get _canGoPrevious => widget.loop || _currentIndex > 0;

  Offset get _exitOffset => widget.flyDirection.resolveExitOffset(
        offsetX: widget.flyExitOffsetX,
        offsetY: widget.flyExitOffsetY,
        textDirection: _textDirection,
      );

  /// Pixel distance that maps 1:1 onto the 0–1 animation so the front card
  /// tracks the finger instead of racing ahead along a longer fly path.
  double get _dragExtent {
    final exit = _exitOffset;
    final travel = math.max(exit.dx.abs(), exit.dy.abs());
    final floor = _cardWidth <= 1 ? 1.0 : _cardWidth * 0.5;
    return math.max(travel, floor);
  }

  /// Snappier than ScrollPhysics default so the next card is ready sooner.
  static final SpringDescription _kSettleSpring =
      SpringDescription.withDampingRatio(
    mass: 0.4,
    stiffness: 240.0,
    ratio: 1.05,
  );

  int _motionEpoch = 0;

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
  bool _pendingCommit = false;
  bool _pendingForward = true;
  double _accumulatedDragX = 0;
  int? _activePointer;
  Offset? _downPosition;
  VelocityTracker? _velocityTracker;
  bool _pointerMoved = false;
  bool _swipeStartReported = false;
  int? _pressedCardIndex;
  bool _signalGesture = false;
  Offset _signalPosition = Offset.zero;
  Timer? _scrollEndTimer;
  DateTime? _ignoreScrollUntil;
  // Set from build() so drag handlers can read it without a BuildContext.
  double _dirFactor = 1.0;
  double _cardWidth = 300.0;
  TextDirection _textDirection = TextDirection.ltr;

  // ── Auto-play pause / resume ──────────────────────────────────────────────
  Timer? _resumeTimer;

  // ── Helper: fire index change notifications ───────────────────────────────
  void _notifyIndexChange() {
    _indexNotifier.value = _currentIndex;
    widget.onIndexChanged?.call(_currentIndex);
  }

  void _commitIndex(bool forward) {
    if (widget.items.isEmpty) return;
    if (forward) {
      if (!_canGoNext) return;
      _currentIndex = widget.loop
          ? (_currentIndex + 1) % widget.items.length
          : _currentIndex + 1;
    } else {
      if (!_canGoPrevious) return;
      _currentIndex = widget.loop
          ? (_currentIndex - 1 + widget.items.length) % widget.items.length
          : _currentIndex - 1;
    }
    _isReversing = false;
    _goingBackward = false;
    _pendingCommit = false;
    _notifyIndexChange();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Directionality.of(context);
    if (next == _textDirection) return;
    _textDirection = next;
    if (!_isAnimating && !_isDragging) {
      _buildTweens();
    }
  }

  // ── Tween builders ────────────────────────────────────────────────────────

  /// Forward tweens — current card flies away, next card rises from peek.
  ///
  /// [scrubbing] uses linear curves so the card tracks the finger. Easing is
  /// reserved for timer/button advances; combining it with a spring makes
  /// swipes feel laggy and disconnected.
  void _buildTweens({bool scrubbing = false}) {
    final exit = _exitOffset;
    final flyCurve = scrubbing ? Curves.linear : widget.flyCurve;
    final riseCurve = scrubbing ? Curves.linear : widget.riseCurve;
    final scaleCurve = scrubbing ? Curves.linear : widget.flyScaleCurve;
    final Curve opacityCurve = scrubbing
        ? Curves.linear
        : Interval(
            widget.flyOpacityInterval.begin,
            widget.flyOpacityInterval.end,
            curve: widget.flyOpacityCurve,
          );

    _flyOffsetY = Tween<double>(begin: 0, end: exit.dy).animate(
      CurvedAnimation(parent: _flyController, curve: flyCurve),
    );
    _flyOffsetX = Tween<double>(begin: 0, end: exit.dx).animate(
      CurvedAnimation(parent: _flyController, curve: flyCurve),
    );
    _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _flyController, curve: opacityCurve),
    );
    _flyScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _flyController, curve: scaleCurve),
    );

    _riseOffsetY = Tween<double>(begin: widget.peekOffsetY, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseOffsetX = Tween<double>(begin: widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseTilt = Tween<double>(begin: widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
  }

  /// Reverse tweens — current card sinks to peek, previous card slides in from above.
  void _buildReverseTweens({bool scrubbing = false}) {
    final sinkCurve =
        scrubbing ? Curves.linear : widget.reverseSinkCurve;
    final riseCurve =
        scrubbing ? Curves.linear : widget.reverseRiseCurve;

    _flyOffsetY = Tween<double>(begin: 0, end: widget.peekOffsetY).animate(
      CurvedAnimation(parent: _flyController, curve: sinkCurve),
    );
    _flyOffsetX = Tween<double>(begin: 0, end: 0).animate(_flyController);
    _flyOpacity = Tween<double>(begin: 1, end: 1).animate(_flyController);
    _flyScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _flyController, curve: sinkCurve),
    );

    _riseOffsetY =
        Tween<double>(begin: -widget.peekOffsetY * 3, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseOffsetX = Tween<double>(begin: -widget.peekOffsetX, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseTilt = Tween<double>(begin: -widget.peekTiltAngle, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
    _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: riseCurve),
    );
  }

  /// Rewind of a forward dismiss: the previous card flies back in from the
  /// same edge it left, and the current card sinks into the peek slot.
  void _buildFlyBackTweens({bool scrubbing = false}) {
    final exit = _exitOffset;
    final sinkCurve = scrubbing ? Curves.linear : widget.reverseSinkCurve;
    final returnCurve = scrubbing ? Curves.linear : widget.flyCurve.flipped;
    final scaleCurve = scrubbing ? Curves.linear : widget.flyScaleCurve.flipped;

    _flyOffsetY = Tween<double>(begin: 0, end: widget.peekOffsetY).animate(
      CurvedAnimation(parent: _flyController, curve: sinkCurve),
    );
    _flyOffsetX = Tween<double>(begin: 0, end: 0).animate(_flyController);
    _flyOpacity = Tween<double>(begin: 1, end: 1).animate(_flyController);
    _flyScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _flyController, curve: sinkCurve),
    );

    _riseOffsetX = Tween<double>(begin: exit.dx, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: returnCurve),
    );
    _riseOffsetY = Tween<double>(begin: exit.dy, end: 0).animate(
      CurvedAnimation(parent: _riseController, curve: returnCurve),
    );
    _riseTilt = Tween<double>(begin: 0, end: 0).animate(_riseController);
    _riseScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: scaleCurve),
    );
  }

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
    _scrollEndTimer?.cancel();
    _indexNotifier.dispose();
    _layersTick.dispose();
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
    if (!_canGoNext) {
      if (!widget.loop) _timer?.cancel();
      return;
    }
    if (!fromTimer) _pauseAutoPlayForInteraction();
    _isAnimating = true;
    final epoch = ++_motionEpoch;
    _goingBackward = false;
    _pendingCommit = true;
    _pendingForward = true;
    _buildTweens();
    setState(() => _isReversing = false);
    _flyController.reset();
    _riseController.reset();
    try {
      await Future.wait([
        _flyController.forward(),
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted || epoch != _motionEpoch) {
            return Future<void>.value();
          }
          return _riseController.forward();
        }),
      ]);
    } on TickerCanceled {
      return;
    }
    if (!mounted || epoch != _motionEpoch) return;
    _pendingCommit = false;
    setState(() => _commitIndex(true));
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
  }

  Future<void> _retreat() async {
    if (_isAnimating || _isDragging || widget.items.length <= 1) return;
    if (!_canGoPrevious) return;
    _pauseAutoPlayForInteraction();
    _isAnimating = true;
    final epoch = ++_motionEpoch;
    _pendingCommit = true;
    _pendingForward = false;
    if (widget.reverseOnBack) {
      _goingBackward = false;
      _buildReverseTweens();
    } else {
      _goingBackward = true;
      _buildFlyBackTweens();
    }
    setState(() => _isReversing = true);
    _flyController.reset();
    _riseController.reset();
    try {
      await Future.wait([
        _riseController.forward(),
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted || epoch != _motionEpoch) {
            return Future<void>.value();
          }
          return _flyController.forward();
        }),
      ]);
    } on TickerCanceled {
      return;
    }
    if (!mounted || epoch != _motionEpoch) return;
    _pendingCommit = false;
    setState(() => _commitIndex(false));
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
      _goingBackward = false;
    });
    _notifyIndexChange();
  }

  /// Forward: next card. Reverse: previous card. Falls back to current when
  /// [loop] is off and there is no neighbour.
  int get _nextIndex =>
      _indexAtOffset(_isReversing ? -1 : 1) ?? _currentIndex;

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
    double stackWidth,
  ) {
    Widget tappable(Widget card, int index) {
      if (widget.onCardTap == null) return card;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _pressedCardIndex = index,
        child: card,
      );
    }

    final int n = widget.items.length;
    if (n == 0) return [];
    if (n == 1) {
      return [tappable(_CardShell(child: widget.items[0]), 0)];
    }

    // Peek slots only exist for real items. When [loop] is off, do not wrap
    // to the first card after the last one.
    final int peekCount =
        (widget.visibleCount - 1).clamp(1, widget.visibleCount - 1);
    final List<Widget> layers = [];

    /// Places a card in stack space with [offsetX]/[offsetY] so hit-testing
    /// matches the visible peek strip. [Transform.translate] keeps its layout
    /// bounds at the origin, which made the peek untappable.
    Widget positionCard({
      required double offsetX,
      required double offsetY,
      required Widget child,
    }) {
      final centered = widget.cardAlignment == CrossAxisAlignment.center;
      final pinEnd =
          !centered && _textDirection == TextDirection.rtl;
      return Positioned(
        top: offsetY,
        left: pinEnd
            ? null
            : (centered ? (stackWidth - cardWidth) / 2 + offsetX : offsetX),
        right: pinEnd ? -offsetX : null,
        width: cardWidth,
        height: cardHeight,
        child: child,
      );
    }

    Widget buildCardState(
        int actualIndex, double effectiveI, double opacity, Widget cachedCard) {
      final offsetY = effectiveI * widget.peekOffsetY;
      final offsetX = effectiveI * widget.peekOffsetX * dirFactor;
      final tilt = effectiveI * widget.peekTiltAngle * dirFactor;
      final scale = 1.0 - (0.07 * effectiveI);

      Widget card = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..rotateZ(tilt),
        child: Transform.scale(
          scale: scale,
          child: cachedCard,
        ),
      );

      if (opacity < 1.0) {
        card = Opacity(opacity: opacity, child: card);
      }
      card = IgnorePointer(ignoring: opacity < 0.05, child: card);

      return positionCard(
        offsetX: offsetX,
        offsetY: offsetY,
        child: card,
      );
    }

    if (!_isReversing) {
      // Always keep the extra back slot mounted (opacity 0 at rest) so a
      // swipe can fade it in without a setState that would reset the gesture.
      final int maxK = peekCount + 1;

      for (int k = maxK; k >= 1; k--) {
        final int? idx = _indexAtOffset(k);
        if (idx == null) continue;
        // Skip a wrapped extra slot that would duplicate the front card.
        if (widget.loop && k > peekCount && idx == _currentIndex) continue;
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
            key: ValueKey('peek-$k-$idx'),
            animation: _riseController,
            builder: (context, child) {
              // Controller already carries the curve / spring — don't ease twice.
              final curveT = _riseController.value;
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
          key: ValueKey('front-$_currentIndex'),
          animation: _flyController,
          builder: (context, child) {
            return positionCard(
              offsetX: 0,
              offsetY: 0,
              child: Transform.translate(
                offset: Offset(_flyOffsetX.value, _flyOffsetY.value),
                child: Transform.scale(
                  scale: _flyScale.value,
                  child: IgnorePointer(
                    ignoring: _flyOpacity.value < 0.05,
                    child: Opacity(
                      opacity: _flyOpacity.value,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: cachedFront,
        ),
      );
    } else {
      // Reverse animation
      for (int k = peekCount; k >= 0; k--) {
        final int? idx = _indexAtOffset(k);
        if (idx == null) continue;
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
              final curveT = _flyController.value;
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
            if (_goingBackward) {
              return Transform.translate(
                offset: Offset(_riseOffsetX.value, _riseOffsetY.value),
                child: Transform.scale(
                  scale: _riseScale.value,
                  child: child,
                ),
              );
            }
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

  bool get _dragBlocked {
    if (!_dragDirectionDetermined) return false;
    return (_dragDirectionForward && !_canGoNext) ||
        (!_dragDirectionForward && !_canGoPrevious);
  }

  /// Maps finger travel onto 0–1. At the ends, tension so the card still
  /// moves a little instead of going dead.
  double _scrubFraction(double absDrag) {
    final raw = absDrag / _dragExtent;
    if (!_dragBlocked) return raw.clamp(0.0, 1.0);
    if (raw <= 0) return 0;
    return raw / (1.0 + raw);
  }

  void _clearPointer() {
    _activePointer = null;
    _downPosition = null;
    _velocityTracker = null;
    _pointerMoved = false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _scrollEndTimer?.cancel();
    _scrollEndTimer = null;
    if (_activePointer != null) return;
    _signalGesture = false;
    _activePointer = event.pointer;
    _downPosition = event.position;
    _pointerMoved = false;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _onDragStart(DragStartDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
    ));
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    if (_downPosition != null &&
        (event.position - _downPosition!).distance > 4) {
      _pointerMoved = true;
    }
    _onDragUpdate(DragUpdateDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      delta: Offset(event.delta.dx, 0),
      primaryDelta: event.delta.dx,
    ));
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final velocity =
        _velocityTracker?.getVelocity() ?? Velocity.zero;
    final dxVel = velocity.pixelsPerSecond.dx;
    final down = _downPosition;
    final isTap = !_pointerMoved &&
        !_dragDirectionDetermined &&
        down != null &&
        (event.position - down).distance < 12;
    final tappedIndex = _pressedCardIndex;
    _clearPointer();
    _pressedCardIndex = null;

    if (isTap) {
      if (_isDragging && !_dragDirectionDetermined) {
        _isDragging = false;
        _swipeStartReported = false;
        widget.onSwipeEnd?.call();
      }
      widget.onCardTap?.call(
        tappedIndex ?? (_isReversing ? _nextIndex : _currentIndex),
      );
      return;
    }

    _onDragEnd(DragEndDetails(
      velocity: Velocity(pixelsPerSecond: Offset(dxVel, 0)),
      primaryVelocity: dxVel,
    ));
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _clearPointer();
    _onDragCancel();
  }

  /// Maps wheel / trackpad scroll onto the same axis as a finger swipe.
  /// Positive scroll (wheel down, content right) becomes a leftward drag so
  /// it advances — matching [Scrollable] / PageView.
  double _scrollDeltaToPointerDx(Offset scrollDelta) {
    final dominant = scrollDelta.dx.abs() >= scrollDelta.dy.abs()
        ? scrollDelta.dx
        : scrollDelta.dy;
    return -dominant;
  }

  void _ensureSignalDrag(Offset position, Duration timeStamp) {
    if (_isDragging) return;
    _signalGesture = true;
    _signalPosition = position;
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.trackpad)
      ..addPosition(timeStamp, position);
    _onDragStart(DragStartDetails(globalPosition: position));
  }

  void _applySignalDx(double dx, Offset position, Duration timeStamp) {
    _signalPosition = Offset(_signalPosition.dx + dx, _signalPosition.dy);
    _velocityTracker?.addPosition(timeStamp, _signalPosition);
    _onDragUpdate(DragUpdateDetails(
      globalPosition: position,
      delta: Offset(dx, 0),
      primaryDelta: dx,
    ));
  }

  void _finishSignalGesture() {
    _scrollEndTimer?.cancel();
    _scrollEndTimer = null;
    if (!_isDragging) {
      _signalGesture = false;
      return;
    }
    final dxVel = _velocityTracker?.getVelocity().pixelsPerSecond.dx ?? 0.0;
    _signalGesture = false;
    _velocityTracker = null;
    _onDragEnd(DragEndDetails(
      velocity: Velocity(pixelsPerSecond: Offset(dxVel, 0)),
      primaryVelocity: dxVel,
    ));
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!widget.dragEnabled || widget.items.length <= 1) return;
    if (_activePointer != null && !_signalGesture) return;
    final until = _ignoreScrollUntil;
    if (until != null && DateTime.now().isBefore(until)) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (!mounted) return;
      if (resolved is! PointerScrollEvent) return;
      _handlePointerScroll(resolved);
    });
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final dx = _scrollDeltaToPointerDx(event.scrollDelta);
    if (dx == 0) return;

    final notch = event.kind == PointerDeviceKind.mouse &&
        event.scrollDelta.distance >= 20 &&
        !_isDragging;

    if (notch) {
      _ensureSignalDrag(event.position, event.timeStamp);
      _applySignalDx(
        dx.sign * _dragExtent * (widget.dragCommitThreshold + 0.15),
        event.position,
        event.timeStamp,
      );
      _finishSignalGesture();
      return;
    }

    _ensureSignalDrag(event.position, event.timeStamp);
    _applySignalDx(dx, event.position, event.timeStamp);
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(
      const Duration(milliseconds: 40),
      _finishSignalGesture,
    );
  }

  void _onPanZoomStart(PointerPanZoomStartEvent event) {
    if (!widget.dragEnabled || widget.items.length <= 1) return;
    if (_activePointer != null && !_signalGesture) return;
    _scrollEndTimer?.cancel();
    _activePointer = event.pointer;
    _signalGesture = true;
    _signalPosition = event.position;
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.trackpad)
      ..addPosition(event.timeStamp, event.position);
    _onDragStart(DragStartDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
    ));
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (!_signalGesture) return;
    if (_activePointer != null && event.pointer != _activePointer) return;
    _applySignalDx(event.panDelta.dx, event.position, event.timeStamp);
  }

  void _onPanZoomEnd(PointerPanZoomEndEvent event) {
    if (!_signalGesture) return;
    if (_activePointer != null && event.pointer != _activePointer) return;
    _activePointer = null;
    _finishSignalGesture();
    _ignoreScrollUntil = DateTime.now().add(const Duration(milliseconds: 80));
  }

  void _onDragStart(DragStartDetails _) {
    if (!widget.dragEnabled || widget.items.length <= 1) return;
    if (_isDragging) return;
    _swipeStartReported = false;
    _pauseAutoPlayForInteraction();

    if (_isAnimating) {
      final commitNow = _pendingCommit;
      final commitForward = _pendingForward;
      _motionEpoch++;
      _flyController.stop();
      _riseController.stop();
      _isAnimating = false;

      if (commitNow) {
        // Finish the previous card immediately so this gesture owns the next.
        widget.onSwipeEnd?.call();
        _commitIndex(commitForward);
        _flyController.reset();
        _riseController.reset();
        _buildTweens(scrubbing: true);
        _refreshLayers();
        _isDragging = true;
        _dragDirectionDetermined = false;
        _accumulatedDragX = 0;
        return;
      }

      _isDragging = true;
      _dragDirectionDetermined = true;
      final t = _flyController.value.clamp(0.0, 1.0);
      _riseController.value = t;
      if (_dragDirectionForward) {
        _buildTweens(scrubbing: true);
        _accumulatedDragX = -t * _dragExtent;
      } else {
        if (widget.reverseOnBack) {
          _buildReverseTweens(scrubbing: true);
        } else {
          _buildFlyBackTweens(scrubbing: true);
        }
        _accumulatedDragX = t * _dragExtent;
      }
      _reportSwipeStart();
      return;
    }

    _isDragging = true;
    _dragDirectionDetermined = false;
    _accumulatedDragX = 0;
  }

  void _reportSwipeStart() {
    if (_swipeStartReported) return;
    _swipeStartReported = true;
    widget.onSwipeStart?.call();
  }

  void _lockDragDirection(bool forward) {
    final wasReversing = _isReversing;
    final wasBackward = _goingBackward;
    _dragDirectionForward = forward;
    if (forward) {
      _goingBackward = false;
      _isReversing = false;
      _buildTweens(scrubbing: true);
    } else if (widget.reverseOnBack) {
      _goingBackward = false;
      _isReversing = true;
      _buildReverseTweens(scrubbing: true);
    } else {
      _goingBackward = true;
      _isReversing = true;
      _buildFlyBackTweens(scrubbing: true);
    }
    _dragDirectionDetermined = true;
    if (_isReversing != wasReversing || _goingBackward != wasBackward) {
      _refreshLayers();
    }
    _reportSwipeStart();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    _accumulatedDragX += details.delta.dx * _dirFactor;

    if (!_dragDirectionDetermined) {
      if (_accumulatedDragX.abs() < 1.0) return;
      _lockDragDirection(_accumulatedDragX < 0);
    } else {
      final nowForward = _accumulatedDragX < 0;
      if (nowForward != _dragDirectionForward &&
          _accumulatedDragX.abs() > 2) {
        _lockDragDirection(nowForward);
      }
    }

    if (!_dragDirectionDetermined) return;

    final fraction = _scrubFraction(_accumulatedDragX.abs());
    _flyController.value = fraction;
    _riseController.value = fraction;
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!_isDragging) return;
    if (!_dragDirectionDetermined) {
      _isDragging = false;
      _swipeStartReported = false;
      widget.onSwipeEnd?.call();
      return;
    }

    final pxVel = (details.primaryVelocity ?? 0) * _dirFactor;
    // Fraction grows with |drag| in both directions, so back-swipe velocity
    // must be flipped or the spring fights the fling.
    final controllerVel =
        (_dragDirectionForward ? -pxVel : pxVel) / _dragExtent;
    final fraction = _flyController.value;
    final continueFling = _dragDirectionForward ? pxVel < 0 : pxVel > 0;
    final fastFling =
        continueFling && pxVel.abs() > widget.swipeThreshold;
    final shouldCommit = !_dragBlocked &&
        (fraction >= widget.dragCommitThreshold ||
            (fastFling && fraction > 0.02));

    _isDragging = false;
    _dragDirectionDetermined = false;
    _isAnimating = true;
    _pendingCommit = shouldCommit;
    _pendingForward = _dragDirectionForward;
    final epoch = ++_motionEpoch;
    final endValue = shouldCommit ? 1.0 : 0.0;
    final almostDone = shouldCommit
        ? fraction >= 0.85
        : fraction <= 0.12;

    try {
      if (almostDone) {
        _flyController.value = endValue;
        _riseController.value = endValue;
      } else {
        await Future.wait([
          _flyController.animateWith(
            ScrollSpringSimulation(
              _kSettleSpring,
              _flyController.value,
              endValue,
              controllerVel,
            ),
          ),
          _riseController.animateWith(
            ScrollSpringSimulation(
              _kSettleSpring,
              _riseController.value,
              endValue,
              controllerVel,
            ),
          ),
        ]);
      }
    } on TickerCanceled {
      return;
    }

    if (!mounted || epoch != _motionEpoch) return;
    if (_pendingCommit) {
      _commitIndex(_pendingForward);
      _refreshLayers();
    } else {
      _isReversing = false;
      _goingBackward = false;
      _refreshLayers();
    }

    widget.onSwipeEnd?.call();
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
    _pendingCommit = false;
    _swipeStartReported = false;
  }

  void _onDragCancel() {
    if (!_isDragging) return;
    if (_dragDirectionDetermined) {
      _onDragEnd(DragEndDetails());
      return;
    }
    _isDragging = false;
    _dragDirectionDetermined = false;
    _goingBackward = false;
    _swipeStartReported = false;
    setState(() => _isReversing = false);
    widget.onSwipeEnd?.call();
    _buildTweens();
    _flyController.reset();
    _riseController.reset();
    _isAnimating = false;
    _refreshLayers();
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
        final int peekCount = (widget.visibleCount - 1)
            .clamp(1, widget.items.length > 1 ? widget.items.length - 1 : 1);

        // Keep peekOffsetX == 0 identical to the old tight layout. Otherwise
        // shrink the card so the peek strip sits inside this box's hit target.
        final peekReserveX = widget.peekOffsetX == 0.0
            ? 0.0
            : widget.peekOffsetX.abs() * peekCount;
        final availableWidth =
            math.max(0.0, constraints.maxWidth - peekReserveX);
        final cardWidth = availableWidth * widget.cardWidthFactor;
        _cardWidth = cardWidth;
        final cardHeight = widget.cardHeight;

        // Resolve start alignment to the correct physical side.
        final Alignment stackAlignment;
        if (widget.cardAlignment == CrossAxisAlignment.center) {
          stackAlignment = Alignment.topCenter;
        } else {
          stackAlignment = isRTL ? Alignment.topRight : Alignment.topLeft;
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: cardHeight + (widget.peekOffsetY * peekCount) + 16,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            onPointerSignal: _onPointerSignal,
            onPointerPanZoomStart: _onPanZoomStart,
            onPointerPanZoomUpdate: _onPanZoomUpdate,
            onPointerPanZoomEnd: _onPanZoomEnd,
            child: ValueListenableBuilder<int>(
              valueListenable: _layersTick,
              builder: (context, _, __) {
                return Stack(
                  alignment: stackAlignment,
                  clipBehavior: Clip.none,
                  children: [
                    ..._buildCardLayers(
                      cardWidth,
                      cardHeight,
                      _dirFactor,
                      constraints.maxWidth,
                    ),
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
                );
              },
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

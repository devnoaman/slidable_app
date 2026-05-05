// import 'dart:async';
// import 'package:flutter/material.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// /// Which direction the front card flies when it is dismissed.
// enum FlyDirection { up, down }

// // ─────────────────────────────────────────────────────────────────────────────
// // StackedCarouselController
// // ─────────────────────────────────────────────────────────────────────────────

// /// External controller for [StackedCarousel].
// ///
// /// Create one in a [StatefulWidget], pass it to [StackedCarousel.controller],
// /// and call [next], [previous], or [jumpTo] from anywhere.
// ///
// /// ```dart
// /// final _controller = StackedCarouselController();
// ///
// /// // in build:
// /// StackedCarousel(controller: _controller, items: ...)
// ///
// /// // elsewhere:
// /// _controller.next();
// /// ```
// class StackedCarouselController {
//   _StackedCarouselState? _state;

//   void _attach(_StackedCarouselState s) => _state = s;
//   void _detach() => _state = null;

//   /// Advance to the next card (same as auto-advance).
//   void next() => _state?._advance();

//   /// Go back to the previous card.
//   void previous() => _state?._retreat();

//   /// Jump directly to [index] without animation.
//   void jumpTo(int index) => _state?._jumpTo(index);

//   /// The currently visible card index.
//   int get currentIndex => _state?._currentIndex ?? 0;

//   /// Total number of cards.
//   int get itemCount => _state?.widget.items.length ?? 0;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // StackedCarousel widget
// // ─────────────────────────────────────────────────────────────────────────────

// class StackedCarousel extends StatefulWidget {
//   const StackedCarousel({
//     super.key,
//     required this.items,
//     this.controller,
//     this.onCardTap,
//     this.autoPlayInterval = const Duration(seconds: 3),
//     this.animationDuration = const Duration(milliseconds: 600),
//     this.peekOffsetY = 28.0,
//     this.peekOffsetX = 0.0,
//     this.peekTiltAngle = 0.12,
//     this.cardWidthFactor = 1.0,
//     this.cardHeight = 420.0,
//     this.cardAlignment = CrossAxisAlignment.center,
//     this.flyDirection = FlyDirection.up,
//     this.swipeThreshold = 300.0,
//     this.autoPlay = true,
//   });

//   /// Optional external controller — use it to call [next], [previous], [jumpTo].
//   final StackedCarouselController? controller;

//   /// Called when a card is tapped, with the tapped card's index.
//   final ValueChanged<int>? onCardTap;

//   final List<Widget> items;
//   final Duration autoPlayInterval;
//   final Duration animationDuration;

//   /// Fraction of the parent width used by each card (0.0 – 1.0).
//   /// e.g. 0.85 = 85 % of the available width.
//   final double cardWidthFactor;

//   /// Explicit card height in logical pixels.
//   /// Independent of width — set both freely.
//   final double cardHeight;

//   /// Horizontal alignment of the card stack within the carousel's full width.
//   /// [CrossAxisAlignment.start] = left-aligned.
//   /// [CrossAxisAlignment.center] = centred (default).
//   final CrossAxisAlignment cardAlignment;

//   /// How many pixels the bottom (peeking) card is offset on the Y-axis.
//   final double peekOffsetY;

//   /// How many pixels the bottom (peeking) card is offset on the X-axis.
//   /// Positive = right, negative = left.
//   final double peekOffsetX;

//   /// Tilt angle of the peeking card in radians.
//   final double peekTiltAngle;

//   /// Direction the front card flies when dismissed.
//   final FlyDirection flyDirection;

//   /// Minimum horizontal swipe velocity (px/s) to trigger navigation.
//   /// Lower = more sensitive. Defaults to 300.
//   final double swipeThreshold;

//   /// Whether the carousel auto-advances.
//   final bool autoPlay;

//   @override
//   State<StackedCarousel> createState() => _StackedCarouselState();
// }

// class _StackedCarouselState extends State<StackedCarousel>
//     with TickerProviderStateMixin {
//   int _currentIndex = 0;
//   bool _isAnimating = false;
//   bool _isReversing = false; // true while _retreat() animation runs
//   Timer? _timer;

//   // Controller that drives the "fly-away" of the front card.
//   late AnimationController _flyController;
//   late Animation<double> _flyOffsetY;
//   late Animation<double> _flyOpacity;
//   late Animation<double> _flyScale;

//   // Controller that drives the peeking card rising into position.
//   late AnimationController _riseController;
//   late Animation<double> _riseOffsetY;
//   late Animation<double> _riseOffsetX;
//   late Animation<double> _riseTilt;
//   late Animation<double> _riseScale;

//   @override
//   void initState() {
//     super.initState();
//     widget.controller?._attach(this);

//     _flyController = AnimationController(
//       vsync: this,
//       duration: widget.animationDuration,
//     );
//     _riseController = AnimationController(
//       vsync: this,
//       duration: widget.animationDuration,
//     );

//     _buildTweens();

//     if (widget.autoPlay && widget.items.length > 1) {
//       _startTimer();
//     }
//   }

//   /// Forward tweens — current card flies away, next card rises from peek.
//   void _buildTweens() {
//     final double flySign =
//         widget.flyDirection == FlyDirection.up ? -1.0 : 1.0;

//     // Current card flies off-screen.
//     _flyOffsetY = Tween<double>(begin: 0, end: flySign * 500).animate(
//       CurvedAnimation(parent: _flyController, curve: Curves.easeInBack),
//     );
//     _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
//       CurvedAnimation(
//         parent: _flyController,
//         curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
//       ),
//     );
//     _flyScale = Tween<double>(begin: 1.0, end: 0.85).animate(
//       CurvedAnimation(parent: _flyController, curve: Curves.easeIn),
//     );

//     // Next card rises from peek position.
//     _riseOffsetY = Tween<double>(begin: widget.peekOffsetY, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseOffsetX = Tween<double>(begin: widget.peekOffsetX, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseTilt = Tween<double>(begin: widget.peekTiltAngle, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//   }

//   /// Reverse tweens — current card sinks to peek, previous card slides in from above.
//   void _buildReverseTweens() {
//     // Current card sinks down to peek position (stays visible).
//     _flyOffsetY = Tween<double>(begin: 0, end: widget.peekOffsetY).animate(
//       CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic),
//     );
//     _flyOpacity = Tween<double>(begin: 1, end: 1).animate(_flyController);
//     _flyScale = Tween<double>(begin: 1.0, end: 0.93).animate(
//       CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic),
//     );

//     // Previous card slides in from above with mirrored offsets.
//     _riseOffsetY =
//         Tween<double>(begin: -widget.peekOffsetY * 3, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseOffsetX =
//         Tween<double>(begin: -widget.peekOffsetX, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseTilt = Tween<double>(begin: -widget.peekTiltAngle, end: 0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//     _riseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
//       CurvedAnimation(parent: _riseController, curve: Curves.easeOutCubic),
//     );
//   }

//   @override
//   void didUpdateWidget(StackedCarousel oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Re-attach if the controller instance changed.
//     if (oldWidget.controller != widget.controller) {
//       oldWidget.controller?._detach();
//       widget.controller?._attach(this);
//     }
//     // Rebuild tweens whenever any param that feeds into them changes.
//     if (oldWidget.peekOffsetX != widget.peekOffsetX ||
//         oldWidget.peekOffsetY != widget.peekOffsetY ||
//         oldWidget.peekTiltAngle != widget.peekTiltAngle ||
//         oldWidget.flyDirection != widget.flyDirection ||
//         oldWidget.animationDuration != widget.animationDuration) {
//       _flyController.duration = widget.animationDuration;
//       _riseController.duration = widget.animationDuration;
//       _buildTweens();
//     }
//     // Restart timer if autoPlay settings changed.
//     if (oldWidget.autoPlay != widget.autoPlay ||
//         oldWidget.autoPlayInterval != widget.autoPlayInterval) {
//       _timer?.cancel();
//       if (widget.autoPlay && widget.items.length > 1) _startTimer();
//     }
//   }

//   void _startTimer() {
//     _timer?.cancel();
//     _timer = Timer.periodic(widget.autoPlayInterval, (_) => _advance());
//   }

//   Future<void> _advance() async {
//     if (_isAnimating || widget.items.length <= 1) return;
//     _isAnimating = true;
//     _buildTweens(); // ensure forward tweens
//     setState(() => _isReversing = false);
//     _flyController.reset();
//     _riseController.reset();
//     await Future.wait([
//       _flyController.forward(),
//       Future.delayed(
//         const Duration(milliseconds: 80),
//         () => _riseController.forward(),
//       ),
//     ]);
//     setState(() {
//       _currentIndex = (_currentIndex + 1) % widget.items.length;
//     });
//     _flyController.reset();
//     _riseController.reset();
//     _isAnimating = false;
//   }

//   Future<void> _retreat() async {
//     if (_isAnimating || widget.items.length <= 1) return;
//     _isAnimating = true;

//     // Build reverse tweens and reset controllers BEFORE setState.
//     // This ensures that when the widget first renders with _isReversing=true,
//     // the incoming previous card is already at its "above" start position
//     // and doesn't flash at the peek position first.
//     _buildReverseTweens();
//     _flyController.reset();
//     _riseController.reset();

//     // Now reveal the previous card in the peek slot — it starts above the stack.
//     setState(() => _isReversing = true);

//     await Future.wait([
//       _riseController.forward(), // incoming card slides in from above
//       Future.delayed(
//         const Duration(milliseconds: 80),
//         () => _flyController.forward(), // current card sinks slightly later
//       ),
//     ]);
//     setState(() {
//       _currentIndex =
//           (_currentIndex - 1 + widget.items.length) % widget.items.length;
//       _isReversing = false;
//     });
//     _buildTweens(); // restore forward tweens
//     _flyController.reset();
//     _riseController.reset();
//     _isAnimating = false;
//   }

//   void _jumpTo(int index) {
//     if (index == _currentIndex) return;
//     if (_isAnimating) return;
//     setState(() {
//       _currentIndex = index.clamp(0, widget.items.length - 1);
//     });
//   }

//   /// Forward: next card (index+1). Reverse: previous card (index-1).
//   int get _nextIndex => _isReversing
//       ? (_currentIndex - 1 + widget.items.length) % widget.items.length
//       : (_currentIndex + 1) % widget.items.length;

//   @override
//   void dispose() {
//     widget.controller?._detach();
//     _timer?.cancel();
//     _flyController.dispose();
//     _riseController.dispose();
//     super.dispose();
//   }

//   /// Builds the two animated card widgets in the correct Z order.
//   ///
//   /// Forward  → peek card behind (Z=0), current card on top (Z=1).
//   /// Reverse  → current card behind (Z=0), incoming previous card on top (Z=1).
//   List<Widget> _buildCardLayers(double cardWidth, double cardHeight) {
//     // Wrap a card widget with a tap detector that fires onCardTap(index).
//     Widget tappable(Widget card, int index) {
//       final cb = widget.onCardTap;
//       if (cb == null) return card;
//       return GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => cb(index),
//         child: card,
//       );
//     }

//     final Widget peekCard = widget.items.length > 1
//         ? AnimatedBuilder(
//             animation: _riseController,
//             builder: (context, child) {
//               return Positioned(
//                 top: _riseOffsetY.value,
//                 child: Transform.translate(
//                   offset: Offset(_riseOffsetX.value, 0),
//                   child: Transform(
//                     alignment: Alignment.bottomCenter,
//                     transform: Matrix4.identity()..rotateZ(_riseTilt.value),
//                     child: Transform.scale(
//                       scale: _riseScale.value,
//                       child: SizedBox(
//                           width: cardWidth, height: cardHeight, child: child),
//                     ),
//                   ),
//                 ),
//               );
//             },
//             child: tappable(
//               _CardShell(child: widget.items[_nextIndex]),
//               _nextIndex,
//             ),
//           )
//         : const SizedBox.shrink();

//     final Widget currentCard = AnimatedBuilder(
//       animation: _flyController,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, _flyOffsetY.value),
//           child: Transform.scale(
//             scale: _flyScale.value,
//             child: Opacity(
//               opacity: _flyOpacity.value,
//               child: SizedBox(
//                   width: cardWidth, height: cardHeight, child: child),
//             ),
//           ),
//         );
//       },
//       child: tappable(
//         _CardShell(child: widget.items[_currentIndex]),
//         _currentIndex,
//       ),
//     );

//     // Reversing: incoming card on top so it slides over the sinking current card.
//     return _isReversing
//         ? [currentCard, peekCard]
//         : [peekCard, currentCard];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final cardWidth = constraints.maxWidth * widget.cardWidthFactor;
//         final cardHeight = widget.cardHeight;

//         return SizedBox(
//           width: constraints.maxWidth,
//           // Extra height so the peeking card is visible below.
//           height: cardHeight + widget.peekOffsetY + 16,
//           child: GestureDetector(
//             // onTap removed: individual cards handle their own taps via onCardTap.
//             onHorizontalDragEnd: (details) {
//               final velocity = details.primaryVelocity ?? 0;
//               if (velocity < -widget.swipeThreshold) {
//                 _advance(); // swipe left → next
//               } else if (velocity > widget.swipeThreshold) {
//                 _retreat(); // swipe right → previous
//               }
//             },
//             child: Stack(
//               alignment: widget.cardAlignment == CrossAxisAlignment.start
//                   ? Alignment.topLeft
//                   : Alignment.topCenter,
//               clipBehavior: Clip.none,
//               children: [
//                 // Build the two animated card layers.
//                 // Forward: peeking card is BEHIND (Z=0), current card is ON TOP (Z=1).
//                 // Reverse: incoming previous card is ON TOP (Z=1), sinking current is BEHIND (Z=0).
//                 ..._buildCardLayers(cardWidth, cardHeight),

//                 // ── Dot indicators ────────────────────────────────────────────
//                 Positioned(
//                   bottom: 0,
//                   child: _DotsIndicator(
//                     count: widget.items.length,
//                     current: _currentIndex,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Card shell — rounded shadow container.
// // ─────────────────────────────────────────────────────────────────────────────
// class _CardShell extends StatelessWidget {
//   const _CardShell({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.22),
//             blurRadius: 24,
//             offset: const Offset(0, 12),
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Dot indicators.
// // ─────────────────────────────────────────────────────────────────────────────
// class _DotsIndicator extends StatelessWidget {
//   const _DotsIndicator({required this.count, required this.current});
//   final int count;
//   final int current;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(count, (i) {
//         final active = i == current;
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           width: active ? 22 : 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: active ? Colors.white : Colors.white38,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         );
//       }),
//     );
//   }
// }

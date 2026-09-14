import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_carousel/stacked_carousel.dart';

void main() {
  testWidgets('StackedCarousel renders with single item', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StackedCarousel(
            items: [SizedBox(width: 100, height: 100, child: Text('Card 0'))],
          ),
        ),
      ),
    );
    expect(find.text('Card 0'), findsOneWidget);
  });

  testWidgets('StackedCarousel renders multiple items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StackedCarousel(
            autoPlay: false,
            visibleCount: 2,
            items: [
              SizedBox(key: Key('c0'), width: 100, height: 100),
              SizedBox(key: Key('c1'), width: 100, height: 100),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('c0')), findsOneWidget);
  });

  test('StackedCarouselController reports currentIndex 0 when detached', () {
    final ctrl = StackedCarouselController();
    expect(ctrl.currentIndex, 0);
    expect(ctrl.itemCount, 0);
  });

  group('FlyDirection.resolveExitOffset', () {
    test('up and down keep optional X drift', () {
      expect(
        FlyDirection.up.resolveExitOffset(offsetX: 10, offsetY: 500),
        const Offset(10, -500),
      );
      expect(
        FlyDirection.down.resolveExitOffset(offsetX: 10, offsetY: 500),
        const Offset(10, 500),
      );
    });

    test('left and right fall back to Y when X is 0', () {
      expect(
        FlyDirection.left.resolveExitOffset(offsetX: 0, offsetY: 500),
        const Offset(-500, 0),
      );
      expect(
        FlyDirection.right.resolveExitOffset(offsetX: 0, offsetY: 500),
        const Offset(500, 0),
      );
    });

    test('left and right use abs(X) when X is set', () {
      expect(
        FlyDirection.left.resolveExitOffset(offsetX: 200, offsetY: 500),
        const Offset(-200, 0),
      );
      expect(
        FlyDirection.right.resolveExitOffset(offsetX: -200, offsetY: 500),
        const Offset(200, 0),
      );
    });

    test('start and end follow Directionality', () {
      expect(
        FlyDirection.end.resolve(TextDirection.ltr),
        FlyDirection.right,
      );
      expect(
        FlyDirection.end.resolve(TextDirection.rtl),
        FlyDirection.left,
      );
      expect(
        FlyDirection.start.resolve(TextDirection.ltr),
        FlyDirection.left,
      );
      expect(
        FlyDirection.start.resolve(TextDirection.rtl),
        FlyDirection.right,
      );
      expect(
        FlyDirection.end.resolveExitOffset(
          offsetX: 0,
          offsetY: 500,
          textDirection: TextDirection.rtl,
        ),
        const Offset(-500, 0),
      );
      expect(
        FlyDirection.start.resolveExitOffset(
          offsetX: 0,
          offsetY: 500,
          textDirection: TextDirection.rtl,
        ),
        const Offset(500, 0),
      );
    });

    test('diagonals combine both axes', () {
      expect(
        FlyDirection.upLeft.resolveExitOffset(offsetX: 0, offsetY: 500),
        const Offset(-500, -500),
      );
      expect(
        FlyDirection.upRight.resolveExitOffset(offsetX: 120, offsetY: 500),
        const Offset(120, -500),
      );
      expect(
        FlyDirection.downLeft.resolveExitOffset(offsetX: 0, offsetY: 400),
        const Offset(-400, 400),
      );
      expect(
        FlyDirection.downRight.resolveExitOffset(offsetX: 80, offsetY: 400),
        const Offset(80, 400),
      );
    });
  });

  testWidgets('FlyDirection.end flips with RTL Directionality', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: StackedCarousel(
              autoPlay: false,
              flyDirection: FlyDirection.end,
              visibleCount: 2,
              items: [
                SizedBox(key: Key('c0'), width: 100, height: 100),
                SizedBox(key: Key('c1'), width: 100, height: 100),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('c0')), findsOneWidget);
  });

  testWidgets('StackedCarousel builds with each fly direction', (tester) async {
    for (final direction in FlyDirection.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StackedCarousel(
              autoPlay: false,
              flyDirection: direction,
              visibleCount: 2,
              items: const [
                SizedBox(key: Key('c0'), width: 100, height: 100),
                SizedBox(key: Key('c1'), width: 100, height: 100),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('c0')), findsOneWidget, reason: '$direction');
    }
  });
}

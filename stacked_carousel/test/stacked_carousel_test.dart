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
}

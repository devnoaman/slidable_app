# stacked_carousel

A Flutter package providing an auto-animated stacked carousel widget where the next card peeks from behind the current one, slightly tilted — with full gesture, controller, and layout control.

## Features

- 🃏 **Stacked peek effect** — the next card shows behind the current one with configurable Y/X offset and tilt
- 🔄 **Auto-advance** — configurable timer-based playback
- 👆 **Swipe gestures** — swipe left for next, swipe right for previous (mirrored animation)
- 🎮 **External controller** — `StackedCarouselController` with `next()`, `previous()`, `jumpTo(index)`
- 🎯 **Tap callback** — `onCardTap(index)` fired per card (front & peek)
- ↕️ **Fly direction** — dismissed cards can fly up, down, left, right, or diagonally — or `start` / `end` to follow `Directionality`
- 📐 **Full layout control** — independent `cardWidthFactor`, `cardHeight`, and `cardAlignment`

## Getting started

```yaml
dependencies:
  stacked_carousel: ^1.1.0
```

## Usage

### Basic

```dart
import 'package:stacked_carousel/stacked_carousel.dart';

StackedCarousel(
  items: [
    Container(color: Colors.blue),
    Container(color: Colors.red),
    Container(color: Colors.green),
  ],
)
```

### With controller & callbacks

```dart
final _controller = StackedCarouselController();

StackedCarousel(
  controller: _controller,
  items: myCards,
  cardWidthFactor: 0.85,       // 85% of available width
  cardHeight: 380,             // explicit height in pixels
  cardAlignment: CrossAxisAlignment.start,
  peekOffsetY: 20,             // peek card 20 px below
  peekOffsetX: 30,             // peek card 30 px to the right
  peekTiltAngle: 0.10,         // tilt in radians
  flyDirection: FlyDirection.end, // start/end follow Directionality; left/right are physical
  swipeThreshold: 300,         // px/s to trigger swipe
  autoPlay: true,
  autoPlayInterval: const Duration(seconds: 4),
  onCardTap: (index) => print('Tapped card $index'),
)

// Control from anywhere:
_controller.next();
_controller.previous();
_controller.jumpTo(2);
print(_controller.currentIndex);
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `items` | `List<Widget>` | required | Cards to display |
| `controller` | `StackedCarouselController?` | `null` | External controller |
| `onCardTap` | `ValueChanged<int>?` | `null` | Tap callback with card index |
| `cardWidthFactor` | `double` | `1.0` | Width as fraction of parent |
| `cardHeight` | `double` | `420` | Explicit height in px |
| `cardAlignment` | `CrossAxisAlignment` | `.center` | Horizontal alignment |
| `peekOffsetY` | `double` | `28` | Peek card Y offset in px |
| `peekOffsetX` | `double` | `0` | Peek card X offset in px |
| `peekTiltAngle` | `double` | `0.12` | Peek card tilt in radians |
| `flyDirection` | `FlyDirection` | `.up` | Dismissed card fly direction. `start` / `end` follow `Directionality` |
| `swipeThreshold` | `double` | `300` | Min swipe velocity in px/s |
| `autoPlay` | `bool` | `true` | Auto-advance on timer |
| `autoPlayInterval` | `Duration` | `3s` | Interval between advances |
| `animationDuration` | `Duration` | `600ms` | Transition duration |

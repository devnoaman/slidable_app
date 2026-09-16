## 1.1.0

* `FlyDirection` now supports `left`, `right`, diagonals, and directional `start` / `end` values that follow `Directionality` (RTL flips them). Horizontal travel falls back to `flyExitOffsetY` when `flyExitOffsetX` is `0`.
* `autoPlayDirection` (`start` / `end`) chooses whether the timer walks toward the first or last card. Default is `end` (next).
* Swipe tracking is 1:1 with the finger; release uses Flutter's scroll spring (fling + snap). Drag can catch an in-flight card.

## 1.0.0

* Initial release.
* `StackedCarousel` widget with stacked peek effect, auto-play, swipe gestures.
* `StackedCarouselController` with `next()`, `previous()`, `jumpTo()`.
* `onCardTap(index)` callback.
* `FlyDirection` enum (`up` / `down`).
* Full layout control: `cardWidthFactor`, `cardHeight`, `cardAlignment`.

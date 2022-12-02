import 'package:flutter/widgets.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import 'package:snapping_sheet_2/src/sheet_size_calculator.dart';

class ScrollControllerOverride extends StatefulWidget {
  final SheetSizeCalculator sizeCalculator;
  final ScrollController scrollController;
  final SheetLocation sheetLocation;
  final Widget child;

  final bool Function({
    required double biggestSnapPos,
    required double smallestSnapPos,
    required double currentPos,
    required DragUpdateDetails? details,
    required DragDirection? currentDragDirection,
  })? allowScrolling;
  final Function(DragUpdateDetails) dragUpdate;
  final VoidCallback dragEnd;
  final double currentPosition;
  final SnappingCalculator snappingCalculator;
  final Axis axis;

  ScrollControllerOverride({
    required this.sizeCalculator,
    required this.scrollController,
    required this.allowScrolling,
    required this.dragUpdate,
    required this.dragEnd,
    required this.currentPosition,
    required this.snappingCalculator,
    required this.child,
    required this.sheetLocation,
    required this.axis,
  });

  @override
  _ScrollControllerOverrideState createState() =>
      _ScrollControllerOverrideState();
}

class _ScrollControllerOverrideState extends State<ScrollControllerOverride> {
  DragUpdateDetails? _lastDragUpdate;
  DragDirection? _currentDragDirection;
  double _currentLockPosition = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.removeListener(_onScrollUpdate);
    widget.scrollController.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollUpdate);
    super.dispose();
  }

  void _onScrollUpdate() {
    if (!_allowScrolling) _lockScrollPosition(widget.scrollController);
  }

  void _overrideScroll(DragUpdateDetails dragUpdateDetails) {
    if (!_allowScrolling) widget.dragUpdate(dragUpdateDetails);
  }

  void _setLockPosition() {
    if (_currentDragDirection == DragDirection.up &&
            widget.sheetLocation == SheetLocation.below ||
        _currentDragDirection == DragDirection.down &&
            widget.sheetLocation == SheetLocation.above) {
      _currentLockPosition = widget.scrollController.position.pixels;
    } else {
      _currentLockPosition = 0;
    }
  }

  bool get _allowScrolling {
    if (widget.allowScrolling != null) {
      return widget.allowScrolling!.call(
        biggestSnapPos: _biggestSnapPos,
        smallestSnapPos: _smallestSnapPos,
        currentPos: widget.currentPosition,
        details: _lastDragUpdate,
        currentDragDirection: _currentDragDirection,
      );
    }
    if (widget.sheetLocation == SheetLocation.below) {
      if (_currentDragDirection == DragDirection.up) {
        if (widget.currentPosition >= _biggestSnapPos)
          return true;
        else
          return false;
      }
      if (_currentDragDirection == DragDirection.down) {
        if (widget.scrollController.position.pixels > 0) return true;
        if (widget.currentPosition <= _smallestSnapPos)
          return true;
        else
          return false;
      }
    }

    if (widget.sheetLocation == SheetLocation.above) {
      if (_currentDragDirection == DragDirection.down) {
        if (widget.currentPosition <= _smallestSnapPos) {
          return true;
        } else
          return false;
      }
      if (_currentDragDirection == DragDirection.up) {
        if (widget.scrollController.position.pixels > 0) return true;
        if (widget.currentPosition >= _biggestSnapPos)
          return true;
        else
          return false;
      }
    }

    return false;
  }

  double get _biggestSnapPos =>
      widget.snappingCalculator.getBiggestPositionPixels();
  double get _smallestSnapPos =>
      widget.snappingCalculator.getSmallestPositionPixels();

  void _lockScrollPosition(ScrollController controller) {
    controller.position.setPixels(_currentLockPosition);
  }

  void _setDragDirection(double dragAmount) {
    this._currentDragDirection =
        dragAmount > 0 ? DragDirection.down : DragDirection.up;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (dragEvent) {
        final dragValue = widget.axis == Axis.horizontal
            ? -dragEvent.delta.dx
            : dragEvent.delta.dy;
        Offset delta;
        double primaryDelta;
        if (widget.axis == Axis.horizontal) {
          delta = Offset(dragEvent.delta.dx, 0);
          primaryDelta = -dragEvent.delta.dx;
        } else {
          delta = Offset(0, dragEvent.delta.dy);
          primaryDelta = dragEvent.delta.dy;
        }
        _setDragDirection(dragValue);
        _setLockPosition();
        _lastDragUpdate = DragUpdateDetails(
          sourceTimeStamp: dragEvent.timeStamp,
          delta: delta,
          primaryDelta: primaryDelta,
          globalPosition: dragEvent.position,
          localPosition: dragEvent.localPosition,
        );
        _overrideScroll(_lastDragUpdate!);
      },
      onPointerUp: (_) {
        widget.dragEnd();
      },
      child: widget.child,
    );
  }
}

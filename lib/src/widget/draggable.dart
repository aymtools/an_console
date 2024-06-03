import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingDraggableButton extends StatefulWidget {
  final Offset? initOffset;
  final Widget child;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final String? sharedPreferencesKEY;

  const FloatingDraggableButton(
      {super.key,
      this.initOffset,
      required this.child,
      this.onTap,
      this.onLongPress,
      this.sharedPreferencesKEY});

  @override
  State<FloatingDraggableButton> createState() =>
      _FloatingDraggableButtonState();
}

class _FloatingDraggableButtonState extends State<FloatingDraggableButton> {
  final GlobalKey _key = GlobalKey();
  late Offset _offset;
  late Offset _maxOffset;
  Offset? _offsetDown;

  bool _isDragging = false;
  int lastDown = 0;

  SharedPreferences? _sp;

  @override
  void initState() {
    super.initState();
    _offset = widget.initOffset ?? Offset.zero;

    void initMax() {
      try {
        final parentSize = WidgetsBinding.instance.renderView.size;
        final currSize = _key.currentContext?.size;
        final Offset size = currSize == null
            ? Offset(parentSize.width, parentSize.height)
            : Offset(parentSize.width - currSize.width,
                parentSize.height - currSize.height);
        if (currSize != null) {
          if ((_offset == Offset.zero && widget.initOffset == null) ||
              (_offset.dx > parentSize.width ||
                  _offset.dy > parentSize.height)) {
            final paddingRight = MediaQuery.of(context).padding.right;
            _offset = Offset(parentSize.width - currSize.width - paddingRight,
                parentSize.height * 3 / 5);
          }
          setState(() {
            _maxOffset = size;
          });
        }
      } catch (e, st) {}
    }

    SharedPreferences.getInstance().then((value) {
      _sp = value;
      WidgetsBinding.instance.addPostFrameCallback((_) => initMax());
      if (widget.sharedPreferencesKEY == null) return;
      final w = _sp?.getDouble(
              '${widget.sharedPreferencesKEY ?? ''}FloatingDraggableButtonX') ??
          _offset.dx;
      final h = _sp?.getDouble(
              '${widget.sharedPreferencesKEY ?? ''}FloatingDraggableButtonY') ??
          _offset.dy;

      setState(() {
        _offset = Offset(w, h);
      });
    });
  }

  void _updateMax() {
    final parentSize = WidgetsBinding.instance.renderView.size;
    final currSize = _key.currentContext?.size;
    final Offset size = currSize == null
        ? Offset(parentSize.width, parentSize.height)
        : Offset(parentSize.width - currSize.width,
            parentSize.height - currSize.height);
    _maxOffset = size;
  }

  void _updatePosition(Offset move) {
    var newOffset = _offset + move;

    newOffset = Offset(
      max(min(newOffset.dx, _maxOffset.dx), 0.0),
      max(min(newOffset.dy, _maxOffset.dy), kToolbarHeight),
    );

    setState(() {
      _offset = newOffset;
    });
  }

  void _dragEnd() {
    if (widget.sharedPreferencesKEY == null) return;
    _sp?.setDouble(
        '${widget.sharedPreferencesKEY ?? ''}FloatingDraggableButtonX',
        _offset.dx);
    _sp?.setDouble(
        '${widget.sharedPreferencesKEY ?? ''}FloatingDraggableButtonY',
        _offset.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Listener(
        onPointerDown: (event) {
          _offsetDown = event.position;
          lastDown = DateTime.now().millisecondsSinceEpoch;
          _updateMax();
        },
        onPointerMove: (event) {
          if (_offsetDown == null) return;
          if (!_isDragging) {
            var p = event.position;
            if ((p.dx - _offsetDown!.dx).abs() < 5 ||
                (p.dy - _offsetDown!.dy).abs() < 5) return;
          }
          _updatePosition(event.delta);
          setState(() {
            _isDragging = true;
          });
        },
        onPointerUp: (event) {
          if (_isDragging) {
            _dragEnd();
            setState(() {
              _isDragging = false;
            });
          } else {
            if (DateTime.now().millisecondsSinceEpoch - lastDown > 500 &&
                widget.onLongPress != null) {
              widget.onLongPress?.call();
            } else {
              widget.onTap?.call();
            }
          }
          _offsetDown = null;
        },
        child: Container(key: _key, child: widget.child),
      ),
    );
  }
}

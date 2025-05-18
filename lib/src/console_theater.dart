import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

//form flutter sdk 3.7.12 packages\flutter\lib\src\widgets\overlay.dart

/// Special version of a [Stack], that doesn't layout and render the first
/// [skipCount] children.
///
/// The first [skipCount] children are considered "offstage".
class ConsoleTheatre extends MultiChildRenderObjectWidget {
  const ConsoleTheatre({
    super.key,
    this.skipCount = 0,
    this.clipBehavior = Clip.hardEdge,
    super.children,
  })  : assert(skipCount >= 0),
        assert(children.length >= skipCount);

  final int skipCount;

  final Clip clipBehavior;

  @override
  MultiChildRenderObjectElement createElement() => _TheatreElement(this);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _RenderTheatre(
      skipCount: skipCount,
      textDirection: Directionality.of(context),
      clipBehavior: clipBehavior,
    );
  }

  // ignore: library_private_types_in_public_api
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderTheatre)
      ..skipCount = skipCount
      ..textDirection = Directionality.of(context)
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('skipCount', skipCount));
  }
}

class _TheatreElement extends MultiChildRenderObjectElement {
  _TheatreElement(ConsoleTheatre super.widget);

  @override
  _RenderTheatre get renderObject => super.renderObject as _RenderTheatre;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final ConsoleTheatre theatre = widget as ConsoleTheatre;
    assert(children.length >= theatre.skipCount);
    children.skip(theatre.skipCount).forEach(visitor);
  }
}

class _RenderTheatre extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, StackParentData> {
  _RenderTheatre({
    List<RenderBox>? children,
    required TextDirection textDirection,
    int skipCount = 0,
    Clip clipBehavior = Clip.hardEdge,
  })  : assert(skipCount >= 0),
        _textDirection = textDirection,
        _skipCount = skipCount,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  Alignment? _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null) {
      return;
    }
    _resolvedAlignment = AlignmentDirectional.topStart.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  int get skipCount => _skipCount;
  int _skipCount;

  set skipCount(int value) {
    if (_skipCount != value) {
      _skipCount = value;
      markNeedsLayout();
    }
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  RenderBox? get _firstOnstageChild {
    if (skipCount == super.childCount) {
      return null;
    }
    RenderBox? child = super.firstChild;
    for (int toSkip = skipCount; toSkip > 0; toSkip--) {
      final StackParentData childParentData =
          child!.parentData! as StackParentData;
      child = childParentData.nextSibling;
      assert(child != null);
    }
    return child;
  }

  RenderBox? get _lastOnstageChild =>
      skipCount == super.childCount ? null : lastChild;

  int get _onstageChildCount => childCount - skipCount;

  @override
  double computeMinIntrinsicWidth(double height) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild,
        (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild,
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild,
        (RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild,
        (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    double? result;
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      assert(!child.debugNeedsLayout);
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      double? candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += childParentData.offset.dy;
        if (result != null) {
          result = math.min(result, candidate);
        } else {
          result = candidate;
        }
      }
      child = childParentData.nextSibling;
    }
    return result;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(constraints.biggest.isFinite);
    return constraints.biggest;
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;

    if (_onstageChildCount == 0) {
      return;
    }

    _resolve();
    assert(_resolvedAlignment != null);

    // Same BoxConstraints as used by RenderStack for StackFit.expand.
    final BoxConstraints nonPositionedConstraints =
        BoxConstraints.tight(constraints.biggest);

    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;

      if (!childParentData.isPositioned) {
        child.layout(nonPositionedConstraints, parentUsesSize: true);
        childParentData.offset =
            _resolvedAlignment!.alongOffset(size - child.size as Offset);
      } else {
        _hasVisualOverflow = RenderStack.layoutPositionedChild(
                child, childParentData, size, _resolvedAlignment!) ||
            _hasVisualOverflow;
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = _lastOnstageChild;
    for (int i = 0; i < _onstageChildCount; i++) {
      assert(child != null);
      final StackParentData childParentData =
          child!.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @protected
  void paintStack(PaintingContext context, Offset offset) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintStack,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      paintStack(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      visitor(child);
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasVisualOverflow ? Offset.zero & size : null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('skipCount', skipCount));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> offstageChildren = <DiagnosticsNode>[];
    final List<DiagnosticsNode> onstageChildren = <DiagnosticsNode>[];

    int count = 1;
    bool onstage = false;
    RenderBox? child = firstChild;
    final RenderBox? firstOnstageChild = _firstOnstageChild;
    while (child != null) {
      if (child == firstOnstageChild) {
        onstage = true;
        count = 1;
      }

      if (onstage) {
        onstageChildren.add(
          child.toDiagnosticsNode(
            name: 'onstage $count',
          ),
        );
      } else {
        offstageChildren.add(
          child.toDiagnosticsNode(
            name: 'offstage $count',
            style: DiagnosticsTreeStyle.offstage,
          ),
        );
      }

      final StackParentData childParentData =
          child.parentData! as StackParentData;
      child = childParentData.nextSibling;
      count += 1;
    }

    return <DiagnosticsNode>[
      ...onstageChildren,
      if (offstageChildren.isNotEmpty)
        ...offstageChildren
      else
        DiagnosticsNode.message(
          'no offstage children',
          style: DiagnosticsTreeStyle.offstage,
        ),
    ];
  }
}

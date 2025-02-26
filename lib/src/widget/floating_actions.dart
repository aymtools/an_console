import 'package:flutter/material.dart';

/// 仅用在AnConsole中的自定义控制台 为控制台增加一系列悬浮按钮 会自动联动滑动隐藏
class FloatingActions extends StatefulWidget {
  /// 内容
  final Widget child;

  /// 构建是默认是否展示
  final bool initShowFloating;

  /// 构建悬浮内容
  final Widget Function(BuildContext) floatingActionsBuilder;

  const FloatingActions(
      {super.key,
      required this.child,
      this.initShowFloating = true,
      required this.floatingActionsBuilder});

  /// 默认放置在右下角
  factory FloatingActions.bottomRight({
    Key? key,
    required Widget child,
    bool initShowFloating = true,
    required List<Widget> actions,
    double actionSeparatorSize = 10,
    double positionedBottom = 44,
    double positionedRight = 24,
  }) {
    return FloatingActions(
        key: key,
        initShowFloating: initShowFloating,
        floatingActionsBuilder: (_) => Positioned(
              bottom: positionedBottom,
              right: positionedRight,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _childList(
                      actions, SizedBox(height: actionSeparatorSize)),
                ),
              ),
              //value ? child! : SizedBox.shrink(),
            ),
        child: child);
  }

  /// 默认放置在右上角
  factory FloatingActions.topRight({
    Key? key,
    required Widget child,
    bool initShowFloating = true,
    required List<Widget> actions,
    double actionSeparatorSize = 10,
    double positionedTop = 44,
    double positionedRight = 24,
  }) {
    return FloatingActions(
        key: key,
        initShowFloating: initShowFloating,
        floatingActionsBuilder: (_) => Positioned(
              top: positionedTop,
              right: positionedRight,
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _childList(
                      actions, SizedBox(height: actionSeparatorSize)),
                ),
              ),
              //value ? child! : SizedBox.shrink(),
            ),
        child: child);
  }

  @override
  State<FloatingActions> createState() => _FloatingActionsState();
}

class _FloatingActionsState extends State<FloatingActions> {
  double position = 0.0;
  double sensitivityFactor = 20.0;

  late ValueNotifier<bool> showFloating =
      ValueNotifier(widget.initShowFloating);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification.metrics.axis == Axis.horizontal) return false;
            if (notification.metrics.pixels - position >= sensitivityFactor) {
              position = notification.metrics.pixels;
              showFloating.value = false;
            } else if (position - notification.metrics.pixels >=
                sensitivityFactor) {
              position = notification.metrics.pixels;
              showFloating.value = true;
            }
            return false;
          },
          child: widget.child,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: showFloating,
          builder: (context, value, child) => value
              ? widget.floatingActionsBuilder(context)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

List<Widget> _childList(List<Widget> children, Widget separator) {
  List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    result.add(separator);
  }
  if (result.isNotEmpty) result.removeLast();
  return result;
}

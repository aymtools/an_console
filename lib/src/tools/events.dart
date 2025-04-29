import 'dart:collection';

import 'package:an_console/an_console.dart';
import 'package:an_console/src/widget/change_notifier_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

/// 定义定长的事件管理器
class EventManager<E> with ChangeNotifier {
  final int _bufferSize;

  late final ListQueue<E> _buffer = ListQueue(_bufferSize);

  EventManager({int? bufferSize})
      : _bufferSize = bufferSize == null || bufferSize < 10 ? 500 : bufferSize;

  List<E> get buffers => _buffer.toList(growable: false);

  void addEvent(E event) {
    while (_buffer.length >= _bufferSize) {
      _buffer.removeLast();
    }
    _buffer.addFirst(event);
    notifyListeners();
  }

  void clear() {
    _buffer.clear();
    notifyListeners();
  }
}

/// 对定长 的事件管理器的默认控制台实现
class EventManagerConsole<T> extends StatefulWidget {
  final EventManager<T> manager;
  final int multipleWith;
  final Widget Function(BuildContext context, int position, T event)
      eventBuilder;
  final double eventSeparatorPadding;
  final List<Widget> bottomRightFloatingActions;

  const EventManagerConsole({
    super.key,
    required this.manager,
    required this.eventBuilder,
    int? multipleWith,
    double? eventSeparatorPadding,
    this.bottomRightFloatingActions = const <Widget>[],
  })  : multipleWith =
            multipleWith == null || multipleWith < 1 ? 1 : multipleWith,
        eventSeparatorPadding = eventSeparatorPadding ?? 12;

  @override
  State<EventManagerConsole<T>> createState() => _EventManagerConsoleState<T>();
}

class _EventManagerConsoleState<T> extends State<EventManagerConsole<T>> {
  late final LinkedScrollControllerGroup _controllers =
      LinkedScrollControllerGroup();

  @override
  Widget build(BuildContext context) {
    final width = widget.multipleWith <= 1
        ? 0.0
        : MediaQuery.of(context).size.width * widget.multipleWith;
    Widget result = ChangeNotifierBuilder<EventManager<T>>(
      changeNotifier: widget.manager,
      builder: (_, logs, __) {
        final data = logs.buffers;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            final item = data.elementAt(index);
            return width == 0.0
                ? widget.eventBuilder(context, index, item)
                : SingleChildScrollView(
                    controller: _controllers.addAndGet(),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: widget.eventBuilder(context, index, item),
                    ),
                  );
          },
          separatorBuilder: (context, _) => Padding(
              padding: EdgeInsets.only(top: widget.eventSeparatorPadding)),
          itemCount: data.length,
        );
      },
    );
    if (widget.bottomRightFloatingActions.isNotEmpty) {
      result = FloatingActions.bottomRight(
        actions: widget.bottomRightFloatingActions,
        child: result,
      );
    }
    return result;
  }
}

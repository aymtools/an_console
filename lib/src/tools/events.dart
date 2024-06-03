import 'dart:collection';

import 'package:an_console/src/console.dart';
import 'package:an_console/src/widget/change_notifier_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class EventManager<E> with ChangeNotifier {
  final int _bufferSize;

  late final ListQueue<E> _buffer = ListQueue(_bufferSize);

  EventManager({int? bufferSize})
      : _bufferSize = bufferSize == null || bufferSize < 10 ? 500 : bufferSize;

  List<E> get buffers => _buffer.toList(growable: false);

  void addEvent(E event) {
    if (!AnConsole.instance.isEnable) return;
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

class EventManagerConsole<T> extends StatefulWidget {
  final EventManager<T> manager;
  final int multipleWith;
  final Widget Function(BuildContext context, int position, T event)
      eventBuilder;

  const EventManagerConsole({
    super.key,
    required this.manager,
    required this.eventBuilder,
    int? multipleWith,
  }) : multipleWith =
            multipleWith == null || multipleWith < 1 ? 1 : multipleWith;

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
    return ChangeNotifierBuilder<EventManager<T>>(
      changeNotifier: widget.manager,
      builder: (_, logs, __) {
        final data = logs._buffer;
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
          separatorBuilder: (context, _) =>
              const Padding(padding: EdgeInsets.only(top: 12)),
          itemCount: data.length,
        );
      },
    );
  }
}

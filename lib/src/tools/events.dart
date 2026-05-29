import 'dart:async';
import 'dart:collection';

import 'package:an_console/an_console.dart';
import 'package:an_console/src/widget/change_notifier_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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



final _defaultFilterNotifier = ValueNotifier((_) => true);

ValueNotifier<bool Function(T)> _filterNotifier<T>(
    bool Function(T)? filter, ValueNotifier<bool Function(T)>? filterNotifier) {
  if (filterNotifier != null) {
    return filterNotifier;
  } else if (filter != null) {
    return ValueNotifier(filter);
  } else {
    return _defaultFilterNotifier;
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
  final ValueNotifier<bool Function(T)> filterNotifier;
  final bool showClean;
  final bool showSave;
  final String? saveLogFileType;
  final FutureOr<String> Function(T event)? saveLogConvert;

   EventManagerConsole({
    super.key,
    required this.manager,
    required this.eventBuilder,
    int? multipleWith,
    double? eventSeparatorPadding,
    this.bottomRightFloatingActions = const <Widget>[],
    bool Function(T)? filter,
    ValueNotifier<bool Function(T)>? filterNotifier,
    this.showClean = false,
    this.showSave = false,
    this.saveLogFileType,
    this.saveLogConvert,
  })  : multipleWith = multipleWith == null || multipleWith < 1 ? 1 : multipleWith,
        eventSeparatorPadding = eventSeparatorPadding ?? 12,
        filterNotifier = _filterNotifier(filter, filterNotifier);


  @override
  State<EventManagerConsole<T>> createState() => _EventManagerConsoleState<T>();
}

class _EventManagerConsoleState<T> extends State<EventManagerConsole<T>> {
  late final LinkedScrollControllerGroup _controllers = LinkedScrollControllerGroup();

  void _changer() {
    try {
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    widget.manager.addListener(_changer);
    widget.filterNotifier.addListener(_changer);
  }

  @override
  void didUpdateWidget(covariant EventManagerConsole<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manager != oldWidget.manager) {
      oldWidget.manager.removeListener(_changer);
      widget.manager.addListener(_changer);
    }
    if (widget.filterNotifier != oldWidget.filterNotifier) {
      oldWidget.filterNotifier.removeListener(_changer);
      widget.filterNotifier.addListener(_changer);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.manager.removeListener(_changer);
    widget.filterNotifier.removeListener(_changer);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.multipleWith <= 1 ? 0.0 : MediaQuery.of(context).size.width * widget.multipleWith;
    final filter = widget.filterNotifier.value;
    final data = widget.manager.buffers.where(filter);

    Widget result = ListView.separated(
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
      separatorBuilder: (context, _) => Padding(padding: EdgeInsets.only(top: widget.eventSeparatorPadding)),
      itemCount: data.length,
    );

    final actions = [...widget.bottomRightFloatingActions];
    if (widget.showClean) {
      actions.add(FloatingActionButton.small(
        onPressed: () => widget.manager.clear(),
        child: Icon(Icons.cleaning_services_sharp),
      ));
    }
    if (widget.showSave) {
      actions.add(FloatingActionButton.small(
        onPressed: () async {
          final path = await widget.manager.saveEventsToFile(
            logFile: widget.saveLogFileType,
            convert: widget.saveLogConvert,
          );
          if (path.isNotEmpty) {
            AnConsole.showToast('Save success to $path');
          }
        },
        child: Icon(Icons.save_sharp),
      ));
    }
    if (actions.isNotEmpty) {
      result = FloatingActions.bottomRight(
        actions: actions,
        child: result,
      );
    }
    return result;
  }
}

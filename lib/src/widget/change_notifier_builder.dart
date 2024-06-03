import 'package:flutter/widgets.dart';

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  final T changeNotifier;
  final Widget Function(BuildContext, T, Widget? child) builder;
  final Widget? child;

  const ChangeNotifierBuilder(
      {super.key,
      required this.changeNotifier,
      required this.builder,
      this.child});

  @override
  State<ChangeNotifierBuilder<T>> createState() =>
      _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier>
    extends State<ChangeNotifierBuilder<T>> {
  void _changer() {
    try {
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    widget.changeNotifier.addListener(_changer);
  }

  @override
  void didUpdateWidget(covariant ChangeNotifierBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeNotifier != oldWidget.changeNotifier) {
      oldWidget.changeNotifier.removeListener(_changer);
      widget.changeNotifier.addListener(_changer);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.changeNotifier.removeListener(_changer);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.changeNotifier, widget.child);
  }
}

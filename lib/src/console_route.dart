part of 'console.dart';

class _ConsoleRouteManager with ChangeNotifier {
  final List<_ConsoleRoute> _routes = [];

  _ConsoleRouteManager._() {
    _routes.add(_MainConsoleRoute());
  }

  static final _ConsoleRouteManager _instance = _ConsoleRouteManager._();

  void addRoute(_ConsoleRoute route) {
    if (route is _ConsoleRouteBottomSheet) {
      route.onDismiss = () {
        _routes.remove(route);
        notifyListeners();
      };
    }
    _routes.add(route);
    notifyListeners();
  }

  void removeRoute(_ConsoleRoute route) {
    _routes.remove(route);
    notifyListeners();
  }

  void _notify() => notifyListeners();

  Future<bool> _willPop() async {
    if (_routes.length > 1) {
      _routes.removeLast();
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<T?> push<T>(String title, Widget content) {
    final route = _ConsoleRoutePage<T>(
        name: title, title: Text(title, maxLines: 1), content: content);
    addRoute(route);
    return route.completer.future;
  }

  void pop([dynamic result]) {
    if (_routes.length > 1) {
      final r = _routes.removeLast();
      if (result != null) {
        r.completer.complete(result);
      }
      notifyListeners();
    }
  }

  /// 自定义对话框
  /// * [onTapOk] 返回值为[null] 时表示只需要移除route 不反悔任何内容
  Future<T> showCustomDialog<T>({
    String? title,
    required Widget content,
    String? okLabel,
    T? Function()? onTapOk,
    String? cancelLabel,
    T? Function()? onTapCancel,
  }) {
    late final _ConsoleRouteDialog<T> route;
    route = _ConsoleRouteDialog(
        name: title ?? '',
        title: title == null || title.isEmpty ? null : Text(title, maxLines: 1),
        content: content,
        actions: <TextButton>[
          if (cancelLabel != null)
            TextButton(
              onPressed: () {
                T? r = onTapCancel?.call();
                removeRoute(route);
                if (r != null) {
                  route.completer.complete(r);
                }
              },
              child: Text(cancelLabel),
            ),
          if (okLabel != null)
            TextButton(
              onPressed: () {
                T? r = onTapOk?.call();
                removeRoute(route);
                if (r != null) {
                  route.completer.complete(r);
                }
              },
              child: Text(okLabel),
            ),
        ]);
    addRoute(route);
    return route.completer.future.then((value) => value as T);
  }

  Future<({int index, T option})> showOptionSelect<T>({
    String? title,
    required Iterable<T> options,
    required String Function(int index, T option) displayToStr,
    T? selected,
    int? selectedIndex,
    String? cancel,
  }) {
    assert(options.isNotEmpty);

    late final _ConsoleRouteBottomSheet<({int index, T option})> route;
    Widget content = ListView.builder(
      itemCount: options.length,
      itemBuilder: (_, index) {
        final op = options.elementAt(index);

        return ListTile(
          onTap: () {
            removeRoute(route);
            route.completer.complete((index: index, option: op));
          },
          leading: Icon(
            index == selectedIndex || op == selected
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            color:
                index == selectedIndex || op == selected ? Colors.blue : null,
          ),
          title: Text(displayToStr(index, op)),
        );
      },
    );
    if (cancel?.isNotEmpty == true) {
      content = Column(
        children: [
          Expanded(child: content),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: OutlinedButton(
                onPressed: () => removeRoute(route),
                child: Text(cancel!),
              ),
            ),
          ),
        ],
      );
    }

    route = _ConsoleRouteBottomSheet(
        name: title ?? '',
        title: title == null || title.isEmpty ? null : Text(title, maxLines: 1),
        content: Expanded(
          child: content,
        ),
        onDismiss: () {
          removeRoute(route);
        });
    addRoute(route);
    return route.completer.future
        .then<({int index, T option})>((value) => value!);
  }

  Future<List<T>> showOptionMultiSelect<T>({
    String? title,
    required Iterable<T> options,
    required String Function(T option) displayToStr,
    Iterable<T>? selected,
    required String confirmLabel,
  }) {
    assert(options.isNotEmpty);
    late final _ConsoleRouteBottomSheet<List<T>> route;
    route = _ConsoleRouteBottomSheet(
        name: title ?? '',
        title: title == null || title.isEmpty ? null : Text(title, maxLines: 1),
        content: _OptionMultiSelect<T>(
          options: options,
          displayToStr: displayToStr,
          selected: selected ?? <T>[],
          confirmLabel: confirmLabel,
          confirm: (data) {
            removeRoute(route);
            route.completer.complete(data);
          },
        ),
        onDismiss: () {
          removeRoute(route);
        });
    addRoute(route);
    return route.completer.future
        .then((value) => value ?? selected?.toList() ?? <T>[]);
  }
}

abstract class ConsoleRoute {
  final String name;
  final bool opaque;

  ConsoleRoute({this.name = '', required this.opaque});

  Widget get content;
}

abstract class _ConsoleRoute<T> extends ConsoleRoute {
  final Widget? title;
  @override
  final Widget content;
  final Completer<T?> completer = Completer();

  _ConsoleRoute({
    super.name,
    required this.title,
    required this.content,
    required super.opaque,
  });

  Widget? _cache;

  Widget _buildAndCache() {
    _cache ??= RepaintBoundary(child: build());
    return _cache!;
  }

  Widget build();
}

class _ConsoleRoutePage<T> extends _ConsoleRoute<T> {
  _ConsoleRoutePage({
    super.name,
    required Widget super.title,
    required super.content,
  }) : super(opaque: false);

  @override
  Widget build() {
    return _ConsoleRoutePageWidget(
      title: title!,
      content: Builder(
        builder: (context) =>
            AnConsole.instance._consoleRouteBuilder(context, -1, this),
      ),
    );
  }
}

class _ConsoleRouteDialog<T> extends _ConsoleRoute<T> {
  final List<TextButton> actions;

  _ConsoleRouteDialog(
      {super.name,
      super.title,
      required Widget content,
      this.actions = const <TextButton>[]})
      : super(
          opaque: true,
          content: _ConsoleRouteDialogContent(
            content: content,
            actions: actions,
          ),
        );

  @override
  Widget build() {
    return _ConsoleRouteDialogWidget(route: this);
  }
}

class _ConsoleRouteBottomSheet<T> extends _ConsoleRoute<T> {
  void Function()? onDismiss;

  _ConsoleRouteBottomSheet(
      {super.name, super.title, required super.content, this.onDismiss})
      : super(opaque: true);

  @override
  Widget build() {
    return _ConsoleRouteBottomSheetWidget(route: this);
  }
}

int _lastTabIndex = 0;

class _MainConsoleRoute extends _ConsoleRoute {
  _MainConsoleRoute()
      : super(
            name: 'AnConsole.main',
            title: const SizedBox.shrink(),
            content: _ConsoleRouteMainWidget(),
            opaque: false);

  @override
  Widget build() {
    final consoles = AnConsole.instance._routes;

    if (_lastTabIndex > 0) {
      _lastTabIndex = _lastTabIndex >= consoles.length ? 0 : _lastTabIndex;
    }

    return DefaultTabController(
      length: consoles.length,
      initialIndex: _lastTabIndex,
      child: Builder(
        builder: (context) =>
            AnConsole.instance._consoleRouteBuilder(context, -1, this),
      ),
    );
  }

  @override
  Widget _buildAndCache() {
    return RepaintBoundary(child: build());
  }
}

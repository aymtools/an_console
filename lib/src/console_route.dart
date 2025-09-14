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

  Future<bool> showConfirm({
    String? title,
    required String content,
    String? okLabel,
    String? cancelLabel,
  }) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(AnConsole.instance._navigator!.context);

    okLabel ??= localizations.okButtonLabel;
    cancelLabel ??= localizations.cancelButtonLabel;

    late final _ConsoleRouteDialog<bool> route;
    route = _ConsoleRouteDialog(
        name: title ?? '',
        title: title == null || title.isEmpty ? null : Text(title, maxLines: 1),
        content: Text(content),
        actions: <TextButton>[
          TextButton(
            onPressed: () {
              removeRoute(route);
              route.completer.complete(false);
            },
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () {
              removeRoute(route);
              route.completer.complete(true);
            },
            child: Text(okLabel),
          ),
        ]);
    addRoute(route);
    return route.completer.future.then((value) => value ?? false);
  }

  Future<T> showOptionSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    T? selected,
    String? cancel,
  }) {
    assert(options.isNotEmpty);

    late final _ConsoleRouteBottomSheet<T> route;
    Widget content = ListView.builder(
      itemCount: options.length,
      itemBuilder: (_, index) => ListTile(
        onTap: () {
          removeRoute(route);
          route.completer.complete(options[index]);
        },
        leading: Icon(
          options[index] == selected
              ? Icons.check_box_outlined
              : Icons.check_box_outline_blank,
          color: options[index] == selected ? Colors.blue : null,
        ),
        title: Text(displayToStr(options[index])),
      ),
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
    return route.completer.future.then<T>((value) => value!);
  }

  Future<List<T>> showOptionMultiSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    List<T>? selected,
    String? confirmLabel,
  }) {
    if (confirmLabel == null || confirmLabel.isEmpty) {
      final MaterialLocalizations localizations =
          MaterialLocalizations.of(AnConsole.instance._navigator!.context);
      confirmLabel = localizations.okButtonLabel;
    }
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
    return route.completer.future.then((value) => value ?? selected ?? <T>[]);
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
      _lastTabIndex = consoles.length >= _lastTabIndex ? 0 : _lastTabIndex;
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

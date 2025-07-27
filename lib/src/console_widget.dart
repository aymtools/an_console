part of 'console.dart';

class _ConsoleWidget extends StatelessWidget {
  const _ConsoleWidget();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;
    return Container(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 2.0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: SafeArea(
              top: false,
              bottom: false,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  padding: mediaQuery.padding.copyWith(top: 0),
                  // textScaleFactor: 1.0,
                  // textScaler: TextScaler.noScaling,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ChangeNotifierBuilder<_ConsoleRouteManager>(
                        changeNotifier: _ConsoleRouteManager._instance,
                        builder: (_, data, __) {
                          return ConsoleTheatre(
                            skipCount: 0,
                            children: data._routes
                                .map((e) => e._buildAndCache())
                                .toList(),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 6,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        right: false,
                        child: GestureDetector(
                          onTap: () => AnConsole
                              .instance._overlayController?._willPop
                              .call(),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 6,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        left: false,
                        child: GestureDetector(
                          onTap: () => AnConsole
                              .instance._overlayController?.callClose
                              .call(),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.close,
                            size: 22,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                    const _ConsoleToast(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final route =
        _ConsoleRoutePage<T>(title: Text(title, maxLines: 1), content: content);
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

abstract class _ConsoleRoute<T> {
  final Widget? title;
  final Widget content;
  final bool opaque;
  final Completer<T?> completer = Completer();

  _ConsoleRoute({
    required this.title,
    required this.content,
    this.opaque = false,
  });

  Widget? _cache;

  Widget _buildAndCache() => _cache ??= build();

  Widget build();
}

class _MainConsoleRoute extends _ConsoleRoute {
  _MainConsoleRoute()
      : super(title: const SizedBox.shrink(), content: const SizedBox.shrink());

  @override
  Widget build() {
    return const RepaintBoundary(child: _ConsoleRouteMainWidget());
  }
}

class _ConsoleRoutePage<T> extends _ConsoleRoute<T> {
  _ConsoleRoutePage({required Widget super.title, required super.content});

  @override
  Widget build() {
    return RepaintBoundary(child: _ConsoleRoutePageWidget(route: this));
  }
}

class _ConsoleRouteDialog<T> extends _ConsoleRoute<T> {
  final List<TextButton> actions;

  _ConsoleRouteDialog(
      {super.title,
      required super.content,
      this.actions = const <TextButton>[]});

  @override
  Widget build() {
    return RepaintBoundary(child: _ConsoleRouteDialogWidget(route: this));
  }
}

class _ConsoleRouteBottomSheet<T> extends _ConsoleRoute<T> {
  void Function()? onDismiss;

  _ConsoleRouteBottomSheet(
      {super.title, required super.content, this.onDismiss});

  @override
  Widget build() {
    return RepaintBoundary(child: _ConsoleRouteBottomSheetWidget(route: this));
  }
}

class _ConsoleRouteMainWidget extends StatefulWidget {
  const _ConsoleRouteMainWidget();

  @override
  State<_ConsoleRouteMainWidget> createState() =>
      _ConsoleRouteMainWidgetState();
}

int _lastTabIndex = 0;

class _ConsoleRouteMainWidgetState extends State<_ConsoleRouteMainWidget>
    with TickerProviderStateMixin {
  late final TabController _controller;

  late final _ConsoleRoute _mainRoute;

  @override
  void initState() {
    super.initState();

    final consoles = AnConsole.instance._routes;

    _lastTabIndex = consoles.length >= _lastTabIndex ? 0 : _lastTabIndex;

    _controller = TabController(
        length: consoles.length,
        vsync: this,
        animationDuration: Duration.zero,
        initialIndex: _lastTabIndex);

    _controller.addListener(() => _lastTabIndex = _controller.index);

    Widget title = ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => _controller.index = index,
        child: Center(
          child: ChangeNotifierBuilder<TabController>(
            changeNotifier: _controller,
            builder: (_, controller, __) => DefaultTextStyle.merge(
              style: TextStyle(
                  color: controller.index == index ? Colors.blue : null),
              maxLines: 1,
              child: consoles[index].title!,
            ),
          ),
        ),
      ),
      separatorBuilder: (_, __) =>
          const Padding(padding: EdgeInsets.only(left: 12)),
      itemCount: consoles.length,
    );

    Widget content = consoles.isEmpty
        ? Container()
        : TabBarView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: consoles
                .map((e) =>
                    _KeepAliveWrapper(child: RepaintBoundary(child: e.content)))
                .toList(growable: false),
          );
    _mainRoute = _ConsoleRoutePage(title: title, content: content);
  }

  @override
  Widget build(BuildContext context) {
    return _ConsoleRoutePageWidget(route: _mainRoute);
  }
}

class _ConsoleRoutePageWidget extends StatelessWidget {
  final _ConsoleRoute route;

  const _ConsoleRoutePageWidget({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 46),
              child: DefaultTextStyle(
                style: TextStyle(
                    fontSize: 18,
                    height: 1,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
                child: SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: route.title,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: route.content,
          ),
        ],
      ),
    );
  }
}

class _BaseRouteDialogWidget extends StatelessWidget {
  final Widget? title;
  final Widget content;

  const _BaseRouteDialogWidget({this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextStyle? defaultTitleStyle = theme.useMaterial3
        ? theme.textTheme.headlineMedium
        : theme.textTheme.titleLarge;

    final titleStyle = theme.dialogTheme.titleTextStyle ?? defaultTitleStyle;

    final contentStyle =
        theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          DefaultTextStyle.merge(
            style: titleStyle,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: title!,
                  ),
                  Container(
                    height: 0.5,
                    color: Theme.of(context).dividerColor,
                  ),
                ],
              ),
            ),
          ),
        DefaultTextStyle.merge(
          style: contentStyle,
          child: content,
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

class _ConsoleRouteDialogWidget extends StatelessWidget {
  final _ConsoleRouteDialog route;

  const _ConsoleRouteDialogWidget({required this.route});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    Widget content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(child: route.content),
    );
    if (route.actions.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              constraints: const BoxConstraints(
                minHeight: 120,
              ),
              child: content),
          Container(
            height: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IntrinsicHeight(
                child: Row(
                  children: _childList(
                    route.actions.map((e) => Expanded(child: e)).toList(),
                    Container(
                      width: 0.5,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const ModalBarrier(
          color: Colors.black54,
          dismissible: false,
          // onDismiss: () => onDismiss?.call(),
        ),
        Center(
          child: Container(
            constraints: BoxConstraints(
              minWidth: min(size.width - 48, 280),
              minHeight: min((size.height * 4 / 5) - 48, 150),
              maxWidth: size.width - 48,
              maxHeight: (size.height * 4 / 5) - 48,
            ),
            color: backgroundColor,
            child: _BaseRouteDialogWidget(title: route.title, content: content),
          ),
        ),
      ],
    );
  }
}

class _ConsoleRouteBottomSheetWidget extends StatelessWidget {
  final _ConsoleRouteBottomSheet route;

  const _ConsoleRouteBottomSheetWidget({required this.route});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final backgroundColor = theme.bottomSheetTheme.modalBackgroundColor ??
        theme.scaffoldBackgroundColor;

    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black54,
          dismissible: route.onDismiss != null,
          onDismiss: () => route.onDismiss?.call(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              minHeight: 100,
              maxHeight: size.height * 2 / 3,
            ),
            width: double.infinity,
            color: backgroundColor,
            child: _BaseRouteDialogWidget(
                title: route.title, content: route.content),
          ),
        ),
      ],
    );
  }
}

class _OptionMultiSelect<T> extends StatefulWidget {
  final List<T> options;
  final String Function(T option) displayToStr;
  final List<T> selected;
  final String confirmLabel;
  final void Function(List<T> selected) confirm;

  const _OptionMultiSelect({
    super.key,
    required this.options,
    required this.displayToStr,
    required this.selected,
    required this.confirmLabel,
    required this.confirm,
  });

  @override
  State<_OptionMultiSelect<T>> createState() => _OptionMultiSelectState<T>();
}

class _OptionMultiSelectState<T> extends State<_OptionMultiSelect<T>> {
  late Set<T> selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.options.length,
              itemBuilder: (_, index) {
                final data = widget.options[index];
                return ListTile(
                  onTap: () {
                    if (selected.contains(data)) {
                      selected.remove(data);
                    } else {
                      selected.add(data);
                    }
                    setState(() {});
                  },
                  leading: Icon(
                    selected.contains(data)
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: selected.contains(data) ? Colors.blue : null,
                  ),
                  title: Text(widget.displayToStr(data)),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => widget.confirm(selected.toList()),
                child: Text(widget.confirmLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

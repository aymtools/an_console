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
                child: Builder(
                  builder: (context) => AnConsole.instance
                      ._consolesBuilder(context, const _Consoles()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Consoles extends StatelessWidget {
  const _Consoles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ChangeNotifierBuilder<_ConsoleRouteManager>(
            changeNotifier: _ConsoleRouteManager._instance,
            builder: (_, data, __) {
              return ConsoleTheatre(
                skipCount: 0,
                children: data._routes.map((e) => e._buildAndCache()).toList(),
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
              onTap: () =>
                  AnConsole.instance._overlayController?._willPop.call(),
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
              onTap: () =>
                  AnConsole.instance._overlayController?.callClose.call(),
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
    );
  }
}

class _ConsoleRoutePageWidget extends StatelessWidget {
  final Widget title;
  final Widget content;

  const _ConsoleRoutePageWidget({required this.title, required this.content});

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
                    child: title,
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
            child: content,
          ),
        ],
      ),
    );
  }
}

class _ConsoleRouteMainWidget extends StatefulWidget {
  const _ConsoleRouteMainWidget();

  @override
  State<_ConsoleRouteMainWidget> createState() =>
      _ConsoleRouteMainWidgetState();
}

class _ConsoleRouteMainWidgetState extends State<_ConsoleRouteMainWidget>
    with TickerProviderStateMixin {
  bool _isNotFirstBuild = false;

  void _notify() {
    if (_isNotFirstBuild) return;
    _isNotFirstBuild = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        _ConsoleRouteManager._instance.notifyListeners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final consoles = AnConsole.instance._routes;

    Widget title = ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => controller.index = index,
        child: Center(
          child: ChangeNotifierBuilder<TabController>(
            changeNotifier: controller,
            builder: (_, controller, __) => DefaultTextStyle.merge(
              style: TextStyle(
                  color: controller.index == index ? Colors.blue : null),
              maxLines: 1,
              child: (consoles[index] as _ConsoleRoute).title!,
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
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: consoles
                .mapIndexed(
                  (index, e) => _KeepAliveWrapper(
                    child: RepaintBoundary(
                      child: Builder(
                        builder: (context) {
                          return AnConsole.instance
                              ._consoleRouteBuilder(context, index, e);
                        },
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );

    _notify();

    return _ConsoleRoutePageWidget(title: title, content: content);
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
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final contentStyle = theme.dialogTheme.contentTextStyle ??
                theme.textTheme.bodyMedium;
            return DefaultTextStyle.merge(
              style: contentStyle,
              child: content,
            );
          },
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
            child: _BaseRouteDialogWidget(
                title: route.title,
                content: Builder(
                    builder: (context) => AnConsole.instance
                        ._consoleRouteBuilder(context, -1, route))),
          ),
        ),
      ],
    );
  }
}

class _ConsoleRouteDialogContent extends StatelessWidget {
  final Widget content;
  final List<Widget> actions;

  const _ConsoleRouteDialogContent(
      {required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    Widget result = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(child: content),
    );
    if (actions.isNotEmpty) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              constraints: const BoxConstraints(
                minHeight: 120,
              ),
              child: result),
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
                    actions.map((e) => Expanded(child: e)).toList(),
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
    return result;
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
              title: route.title,
              content: Builder(
                  builder: (context) => AnConsole.instance
                      ._consoleRouteBuilder(context, -1, route)),
            ),
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

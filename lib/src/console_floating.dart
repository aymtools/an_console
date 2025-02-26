part of 'console.dart';

class _ConsoleFloatingButton extends StatelessWidget {
  final ValueNotifier<bool> toolsStatus;

  const _ConsoleFloatingButton({required this.toolsStatus});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FloatingDraggableButton(
      sharedPreferencesKEY: 'AnConsole',
      initOffset: Offset(size.width - MediaQuery.of(context).padding.right - 57,
          size.height * 3 / 4),
      onTap: () {
        if (AnConsole.instance._overlayController != null) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        final overlay = navigator.overlay!;
        Zone.root.fork().run(() {
          late OverlayEntry overlayEntry;
          late ConsoleOverlayController controller;
          controller = ConsoleOverlayController(
            callClose: () {
              try {
                AnConsole.instance._overlayController = null;
                AnConsole.instance._onBackPressedDispatcher
                    .removerWillPopCallback(controller._willPop);
                overlayEntry.remove();
              } catch (_) {}
            },
          );
          AnConsole.instance._overlayController = controller;
          AnConsole.instance._onBackPressedDispatcher
              .addWillPopCallback(controller._willPop);

          overlayEntry =
              OverlayEntry(builder: (context) => const _ConsoleWidget());
          overlay.insert(overlayEntry);
        });
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: toolsStatus,
        builder: (context, value, child) {
          return value != true
              ? const Material(
                  type: MaterialType.transparency,
                  child: SizedBox.shrink(),
                )
              : child!;
        },
        child: SizedBox(
          width: 45,
          height: 45,
          child: Material(
            color: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            elevation: 2.0,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: const Center(
              child: Icon(
                Icons.bug_report_rounded,
                color: Colors.blue,
                size: 41,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

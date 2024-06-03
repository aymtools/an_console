part of 'console.dart';

class _ConsoleToastQueue with ChangeNotifier {
  static final _ConsoleToastQueue instance = _ConsoleToastQueue();

  String? message;
  Timer? timer;

  void showToast(String message) {
    this.message = message;
    pool();
  }

  void pool() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    if (message != null) {
      timer = Timer(const Duration(seconds: 2), () {
        message = null;
        pool();
      });
    }
    notifyListeners();
  }
}

class _ConsoleToast extends StatelessWidget {
  const _ConsoleToast({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: SafeArea(
          top: false,
          bottom: false,
          child: IgnorePointer(
            child: ChangeNotifierBuilder<_ConsoleToastQueue>(
                changeNotifier: _ConsoleToastQueue.instance,
                builder: (_, data, __) {
                  if (data.message == null || data.message!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      margin: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                      padding: const EdgeInsets.all(12),
                      child: DefaultTextStyle(
                          style: (Theme.of(context).textTheme.bodyMedium ??
                                  const TextStyle(fontSize: 14))
                              .copyWith(color: Colors.white),
                          child: Text(data.message!)),
                    ),
                  );
                }),
          ),
        ),
      ),
    );
  }
}

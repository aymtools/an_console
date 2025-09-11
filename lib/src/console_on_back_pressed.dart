part of 'console.dart';

class _OnBackPressedDispatcher with WidgetsBindingObserver {
  Future<bool> Function()? _willPop;
  final List<Future<bool> Function()> _willPops = [];

  void addWillPopCallback(Future<bool> Function() callback) {
    _willPops.add(callback);
  }

  void removerWillPopCallback(Future<bool> Function() callback) {
    _willPops.remove(callback);
  }

  _OnBackPressedDispatcher();

  @override
  Future<bool> didPopRoute() async {
    if (_willPops.isNotEmpty) {
      for (var fun in _willPops.reversed) {
        if (await fun.call() == true) {
          return true;
        }
      }
    }

    if (_willPop == null) return false;
    return !(await _willPop!());
  }
}

_OnBackPressedDispatcher? _hookedOnBackPressedDispatcher;

void _hookOnBackPressed() {
  if (_hookedOnBackPressedDispatcher != null) return;
  try {
    final dispatcher = _OnBackPressedDispatcher();
    WidgetsBinding.instance.addObserver(dispatcher);
    _hookedOnBackPressedDispatcher = dispatcher;
    _willShow();
  } catch (_) {}
}

ValueNotifier<bool> _toolsStatus = ValueNotifier(AnConsole.instance._isEnable);

OverlayEntry? _btnConsole;

OverlayEntry _createFloatingButton() {
  return OverlayEntry(
      builder: (BuildContext c) =>
          _ConsoleFloatingButton(toolsStatus: _toolsStatus));
}

bool _willShowing = false;

void _willShow() {
  if (_willShowing) return;
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _willShowing = false;
      if (!_toolsStatus.value) return;
      if (_btnConsole == null) {
        _btnConsole = _createFloatingButton();
        var navigator = AnConsole.instance._navigator;
        if (navigator == null) {
          navigator = WidgetsBinding.instance.rootElement!
              .findStateForChildren<NavigatorState>();
          AnConsole.instance._navigator = navigator;
        }
        navigator?.overlay!.insert(_btnConsole!);
      }
    });
    _willShowing = true;
  } catch (_) {}
}

void _show() {
  if (_toolsStatus.value) return;
  _toolsStatus.value = true;
  if (_btnConsole == null) {
    _willShow();
  }
}

void _hide() {
  _toolsStatus.value = false;
}

extension on Element {
  T? findStateForChildren<T extends State>() => _findStateForChildren(this);

  T? _findStateForChildren<T extends State>(Element element) {
    if (element is StatefulElement && element.state is T) {
      return element.state as T;
    }
    T? target;
    element.visitChildElements((e) => target ??= _findStateForChildren(e));
    return target;
  }
}

//
// class ConsoleNavigatorObserver extends NavigatorTopRouteChangeObserver {
//   //某些路由下不展示的过滤器
//   final List<RoutePredicate> _fitter = [];
//
//   final ValueNotifier<bool> _toolsStatus = ValueNotifier(false);
//
//   final List<_ConsoleRoute> _routes = [];
//
//   //
//   // final _OnBackPressedDispatcher _onBackPressedDispatcher =
//   //     _OnBackPressedDispatcher();
//
//   ConsoleNavigatorObserver._() {
//     // WidgetsBinding.instance.addObserver(_onBackPressedDispatcher);
//   }
//
//   static final ConsoleNavigatorObserver _instance =
//       ConsoleNavigatorObserver._();
//
//   void _addConsole(_ConsoleRoute route) {
//     _routes.add(route);
//   }
//
//   @override
//   void onTopRouteChange(Route? route) {
//     if (!AnConsole.instance.isEnable) return;
//     if (route is ModalBottomSheetRoute || route is DialogRoute) {
//       _toolsStatus.value = false;
//     } else if (route?.settings != null && _fitter.any((e) => e.call(route!))) {
//       _toolsStatus.value = false;
//     } else if (route?.settings != null) {
//       _toolsStatus.value = true;
//       if (_btnConsole == null && _routes.isNotEmpty) {
//         _btnConsole = _createFloatingButton();
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_btnConsole != null) {
//             navigator?.overlay?.insert(_btnConsole!);
//           }
//         });
//       }
//     }
//   }
//
//   OverlayEntry? _btnConsole;
//
//   OverlayEntry _createFloatingButton() {
//     return OverlayEntry(
//         builder: (BuildContext c) =>
//             _ConsoleFloatingButton(toolsStatus: _toolsStatus));
//   }
// }

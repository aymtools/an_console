import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'console_theater.dart';
import 'widget/change_notifier_builder.dart';
import 'widget/draggable.dart';

part 'console_floating.dart';
part 'console_on_back_pressed.dart';
part 'console_toast.dart';
part 'console_widget.dart';

class AnConsole {
  AnConsole._() {
    _hookOnBackPressed();
  }

  static final AnConsole _instance = AnConsole._();

  static AnConsole get instance => _instance;

  ConsoleOverlayController? _overlayController;

  // late final ConsoleNavigatorObserver _consoleObserver =
  //     ConsoleNavigatorObserver._instance;

  late final _OnBackPressedDispatcher _onBackPressedDispatcher =
      _hookedOnBackPressedDispatcher!;

  // late final ProxyManagerNavigatorObserver _navigatorObserver =
  //     ProxyManagerNavigatorObserver()..addObserver(_consoleObserver);

  // ProxyManagerNavigatorObserver get navigatorObserver {
  //   _hookOnBackPressed();
  //   return _navigatorObserver;
  // }

  final List<_ConsoleRoute> _routes = [];

  NavigatorState? _navigator;

  void addConsole(String title, Widget content) {
    _hookOnBackPressed();
    final route =
        _ConsoleRoutePage(title: Text(title, maxLines: 1), content: content);
    _routes.add(route);
  }

  // void addNotShowUpRoute(RoutePredicate predicate) {
  //   _hookOnBackPressed();
  //   // _doNotShowUp.add(predicate);
  //   _consoleObserver._fitter.add(predicate);
  // }

  bool _isEnable = () {
    bool flag = false;
    assert(() {
      flag = true;
      return true;
    }());
    return flag;
  }();

  bool get isEnable => _isEnable;

  /// 工具的模式 1:一直启用 2:一直不启用  other:非release下启用
  set floatingMode(int mode) {
    switch (mode) {
      case 1:
        _isEnable = true;
        break;
      case 2:
        _isEnable = false;
        break;
      default:
        _isEnable = false;
        assert(() {
          _isEnable = true;
          return true;
        }());
    }
    if (_isEnable) {
      _show();
    } else {
      _hide();
    }
  }

  static Future<T?> push<T>(String title, Widget content) {
    _assert();
    return _ConsoleRouteManager._instance.push(title, content);
  }

  static void pop([dynamic result]) {
    _assert();
    _ConsoleRouteManager._instance.pop(result);
  }

  static Future<bool> showConfirm({
    String? title,
    required String content,
    String? okLabel,
    String? cancelLabel,
  }) {
    _assert();
    return _ConsoleRouteManager._instance.showConfirm(
        title: title,
        content: content,
        okLabel: okLabel,
        cancelLabel: cancelLabel);
  }

  static void showToast(String message) {
    _assert();
    _ConsoleToastQueue.instance.showToast(message);
  }

  static Future<T> showOptionSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    T? selected,
    String? cancel,
  }) {
    _assert();
    return _ConsoleRouteManager._instance.showOptionSelect(
        title: title,
        options: options,
        displayToStr: displayToStr,
        selected: selected,
        cancel: cancel);
  }

  static Future<List<T>> showOptionMultiSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    List<T>? selected,
    String? confirmLabel,
  }) {
    _assert();
    return _ConsoleRouteManager._instance.showOptionMultiSelect(
        title: title,
        options: options,
        displayToStr: displayToStr,
        selected: selected,
        confirmLabel: confirmLabel);
  }

  static void _assert() {
    assert(instance.isEnable && instance._navigator != null);
  }
}

class ConsoleOverlayController {
  final void Function() callClose;

  Future<bool> _willPop() async {
    if (await _ConsoleRouteManager._instance._willPop()) {
      callClose();
      return false;
    }
    return true;
  }

  ConsoleOverlayController({required this.callClose});
}

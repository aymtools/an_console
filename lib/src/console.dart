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

/// 自定义控制台
class AnConsole {
  AnConsole._() {
    _hookOnBackPressed();
  }

  static final AnConsole _instance = AnConsole._();

  /// 全局唯一
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

  /// 新增一个自定义控制台
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

  /// 全局控制 可用性
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

  /// 跳转到新的页面
  static Future<T?> push<T>(String title, Widget content) {
    _assert();
    return _ConsoleRouteManager._instance.push(title, content);
  }

  /// 弹出最顶层页面
  static void pop([dynamic result]) {
    _assert();
    _ConsoleRouteManager._instance.pop(result);
  }

  /// 展示一个对话框 不影响路由内容 库中独立的
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

  /// 展示一个toast消息 不影响应用的toast 库中独立的
  static void showToast(String message) {
    _assert();
    _ConsoleToastQueue.instance.showToast(message);
  }

  /// 展示一个列表选择器  不影响路由内容 库中独立的
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

  /// 展示一个多选的列表选择器  不影响路由内容 库中独立的
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

/// 对控制台的overlay的控制器
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

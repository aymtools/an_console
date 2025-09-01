import 'dart:async';

import 'package:flutter/widgets.dart';

class FileBrowser extends StatelessWidget {
  final FutureOr<String> path;

  /// 构建右下角的悬浮按钮
  final List<Widget> Function(
      BuildContext context, String path, void Function() callRefresh)? actions;

  /// 点击文件时
  final void Function(dynamic file, void Function() callRefresh)? onPressFile;

  /// 长按时处理 包含 文件 和 文件夹
  final void Function(dynamic entity, void Function() callRefresh)? onLongPress;

  /// 排序或过滤函数
  final FutureOr<List> Function(List)? sortOrFilter;

  const FileBrowser(
      {super.key,
      required this.path,
      this.actions,
      this.onPressFile,
      this.onLongPress,
      this.sortOrFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('unsupported'),
    );
  }
}

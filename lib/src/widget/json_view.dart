import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

/// json 节点类型
enum NodeType {
  listStart,
  listIndex,
  listEnd,
  mapStart,
  mapKey,
  mapEnd,
  value,
}

/// json nodes 树形结构
class JsonNodes {
  int _maxLevel = 0;
  final List<JTreeNode> nodes;

  int get maxLevel => _maxLevel;
  final JTreeNode rootTreeNode;

  JsonNodes(this.nodes, this.rootTreeNode);
}

/// 一个节点
class JTreeNode {
  JTreeNode? _parent;

  JTreeNode get parent => _parent!;

  bool get isRoot => _parent == null;

  final List<JTreeNode> _children = [];

  bool get hasChild => _children.isEmpty;

  List<JTreeNode> get children => List.of(_children, growable: false);

  final String path;
  final int level;
  final NodeType type;
  final dynamic value;

  JTreeNode._(this.path, this.level, this.type, this.value);

  factory JTreeNode.root({required NodeType type, required dynamic value}) {
    final r = JTreeNode._('', 0, type, value);
    return r;
  }

  JTreeNode makeChild(
      {required String path,
      required NodeType type,
      required dynamic value,
      bool add = true}) {
    final r = JTreeNode._(path, add ? level + 1 : level, type, value);
    r._parent = this;
    if (add) _children.add(r);
    return r;
  }

  String get absolutePath {
    JTreeNode? n = this;
    String r = '';
    do {
      r = '${n!.path}.$r';
      n = n._parent;
    } while (n != null);
    if (r.endsWith('.')) {
      r.substring(0, r.length - 1);
    }
    return r;
  }
}

// int _maxLevel = -1;
// late JTreeNode _node;

JsonNodes _parsing(dynamic json) {
  if (json is String &&
      (json.trim().startsWith('{') || json.trim().startsWith('['))) {
    return _parsing(jsonDecode(json));
  } else if (isPrimitive(json)) {
    return JsonNodes([], JTreeNode.root(type: NodeType.value, value: json));
  }
  List<JTreeNode> result = [];
  late JTreeNode node;
  if (json is List) {
    node = JTreeNode.root(type: NodeType.listStart, value: json);
    result.add(node);
    result.addAll(_jlist(node, json));
  } else if (json is Map) {
    node = JTreeNode.root(type: NodeType.mapStart, value: json);
    result.add(node);
    result.addAll(_jmap(node, json));
  } else {
    throw 'not json';
  }
  JsonNodes jsonNodes = JsonNodes(result, node);
  int maxLevel = result.fold(
      -1, (pre, element) => pre < element.level ? element.level : pre);
  jsonNodes._maxLevel = maxLevel;
  return jsonNodes;
}

List<JTreeNode> _jp(JTreeNode node, dynamic json) {
  // if (json == null) {
  //   return 'Null';
  // } else
  if (json is List) {
    return _jlist(node, json);
  } else if (json is Map) {
    return _jmap(node, json);
  }

  List<JTreeNode> result = [];
  return result;
}

List<JTreeNode> _jmap(JTreeNode node, Map json) {
  List<JTreeNode> result = [];
  // level++;
  // if (_maxLevel < level) {
  //   _maxLevel = level;
  // }

  json.forEach((key, value) {
    node = node.makeChild(
        path: '$key', type: NodeType.mapKey, value: MapEntry(key, value));
    // result.add(JsonNode(level, NodeType.mapKey, MapEntry(key, value), _node));
    result.add(node);
    if (!isPrimitive(value)) {
      result.addAll(_jp(node, value));
    }
    node = node.parent;
  });
  if (result.isNotEmpty) {
    result.add(node.makeChild(
        path: '', type: NodeType.mapEnd, value: '}', add: false));
  }
  return result;
}

List<JTreeNode> _jlist(JTreeNode node, List<dynamic> json) {
  List<JTreeNode> result = [];
  // level++;
  // if (_maxLevel < level) {
  //   _maxLevel = level;
  // }

  // if (json.isNotEmpty) {
  //   // result.add(LJN(level, JT.listStart, '['));
  // }
  json.forEachIndexed((index, value) {
    node = node.makeChild(
        path: '[$index]',
        type: NodeType.listIndex,
        value: MapEntry(index, value));
    result.add(node);
    if (!isPrimitive(value)) {
      result.addAll(_jp(node, value));
    }
    node = node.parent;
  });
  if (result.isNotEmpty) {
    result.add(node.makeChild(
        path: '', type: NodeType.listEnd, value: ']', add: false));
  }
  return result;
}

/// 是否是基础类似
bool isPrimitive(dynamic value) {
  return value is double || value is int || value is String || value is bool;
}

Future<JsonNodes> _defJsonParser(
        json, JsonNodes Function(dynamic json) parsing) =>
    compute(parsing, json);

/// 构建一个json展示的widget
class JsonView extends StatefulWidget {
  static Future<JsonNodes> Function(
      dynamic, JsonNodes Function(dynamic) parsing) jsonParser = _defJsonParser;

  final dynamic json;
  final bool sliver;

  final Widget Function(BuildContext context, JsonNodes nodes)? builder;

  const JsonView({super.key, required this.json})
      : sliver = false,
        builder = null;

  /// 构建为Sliver
  const JsonView.sliver({super.key, required this.json})
      : sliver = true,
        builder = null;

  /// 自定义节点展示
  const JsonView.custom(
      {super.key,
      required this.json,
      required this.sliver,
      required Widget Function(BuildContext context, JsonNodes nodes)
          this.builder});

  @override
  State<JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> {
  late LinkedScrollControllerGroup _controllers = LinkedScrollControllerGroup();

  late Future<JsonNodes> jsonNodes;
  dynamic jsonStr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseJson(widget.json);
  }

  @override
  void didUpdateWidget(covariant JsonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.json != oldWidget.json) {
      // _controllers
      _controllers = LinkedScrollControllerGroup();
      _parseJson(widget.json);
    }
  }

  _parseJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == this.jsonStr) return;
    this.jsonStr = jsonStr;
    jsonNodes = JsonView.jsonParser(jsonStr, _parsing);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JsonNodes>(
        future: jsonNodes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final r = Center(
              child:
                  Text(snapshot.error?.toString() ?? 'computeJsonView error'),
            );
            return widget.sliver ? SliverToBoxAdapter(child: r) : r;
          } else if (snapshot.hasData) {
            final data = snapshot.requireData;
            if (widget.builder != null) {
              return widget.builder!(context, data);
            }
            return _buildJsonV(data);
            // return JsonView.map(snapshot.data!);
          } else {
            const r = Center(child: CircularProgressIndicator());
            return widget.sliver ? const SliverToBoxAdapter(child: r) : r;
          }
        });
  }

  Widget _buildJsonV(JsonNodes jsonNodes) {
    // int maxLevel = jsonNodes.maxLevel;
    double defWidth = MediaQuery.of(context).size.width;
    if (defWidth < 400) {
      defWidth = defWidth * 2;
    }

    Widget itemBuilder(BuildContext context, int index) {
      final node = jsonNodes.nodes[index];
      return JsonNodeBuilder(
          node: node, controllers: _controllers, defWidth: defWidth);
    }

    return widget.sliver
        ? SliverList(
            key: ValueKey(widget.json),
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: jsonNodes.nodes.length,
            ),
          )
        : ListView.builder(
            itemBuilder: itemBuilder,
            itemCount: jsonNodes.nodes.length,
          );
  }
}

/// 节点Build
class JsonNodeBuilder extends StatefulWidget {
  final JTreeNode node;
  final LinkedScrollControllerGroup controllers;
  final double defWidth;

  const JsonNodeBuilder(
      {super.key,
      required this.node,
      required this.controllers,
      required this.defWidth});

  @override
  State<JsonNodeBuilder> createState() => _JsonNodeBuilderState();
}

class _JsonNodeBuilderState extends State<JsonNodeBuilder> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controllers.addAndGet();
  }

  @override
  void didUpdateWidget(covariant JsonNodeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllers != oldWidget.controllers) {
      _controller = widget.controllers.addAndGet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    Widget result;
    switch (node.type) {
      case NodeType.listStart:
        result = const Text('[');
        break;
      case NodeType.listIndex:
        MapEntry<int, dynamic> data = node.value;
        final value = data.value;
        result = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[${data.key}]'),
            const Text(' : '),
            if (isPrimitive(value))
              Expanded(child: Text(value is String ? '"$value"' : '$value')),
            if (value is Map) const Text('{'),
            if (value is List) const Text('['),
          ],
        );
        break;
      case NodeType.listEnd:
        result = const Text(']');
        break;
      case NodeType.mapStart:
        result = const Text('{');
        break;
      case NodeType.mapKey:
        MapEntry data = node.value;
        final value = data.value;
        result = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${data.key}"'),
            const Text(' : '),
            if (isPrimitive(value))
              Expanded(child: Text(value is String ? '"$value"' : '$value')),
            if (value is Map) Text('{${value.isEmpty ? '}' : ''}'),
            if (value is List) Text('[${value.isEmpty ? ']' : ''}'),
          ],
        );
        break;
      case NodeType.mapEnd:
        result = const Text('}');
        break;
      case NodeType.value:
        final value = node.value;
        result = Text(value is String ? '"$value"' : '$value');
        break;
    }
    return SingleChildScrollView(
      key: ValueKey(_controller),
      scrollDirection: Axis.horizontal,
      controller: _controller,
      child: SizedBox(
        width: widget.defWidth,
        child: Padding(
          padding: EdgeInsets.only(left: 12.0 * node.level),
          child: result,
        ),
      ),
    );
  }
}

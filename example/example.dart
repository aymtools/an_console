import 'package:an_console/an_console.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugConfig extends StatelessWidget {
  const DebugConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('可以存放一些配置控制'),
    );
  }
}

class DebugDemo extends StatelessWidget {
  const DebugDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              AnConsole.push(
                'Demo2',
                DebugDemo2(
                  param: 'hello',
                ),
              );
            },
            child: Text('跳转页面'),
          ),
          TextButton(
            onPressed: () {
              AnConsole.showToast('你点我干什么' * 5);
            },
            child: Text('Toast'),
          ),
          TextButton(
            onPressed: () async {
              final select = await AnConsole.showConfirm(
                title: '提示',
                content: '这里是Confirm的说明',
              );
              if (select) {
                AnConsole.showToast('你选择了确认按钮');
              } else {
                AnConsole.showToast('你选择了取消按钮');
              }
            },
            child: Text('Confirm'),
          ),
          TextButton(
            onPressed: () async {
              final select = await AnConsole.showOptionSelect<String>(
                title: '请选择',
                options: [
                  '12111111',
                  '222222',
                  '33333333333',
                  '44444444444',
                  '5555555',
                  '66',
                  '7777777',
                ],
                displayToStr: (option) => option,
              );

              AnConsole.showToast('你选择了$select');
            },
            child: Text('OptionSelectSimple'),
          ),
          TextButton(
            onPressed: () async {
              final select = await AnConsole.showOptionSelect<String>(
                  title: '请选择',
                  options: [
                    '12111111',
                    '222222',
                    '33333333333',
                    '44444444444',
                    '5555555',
                    '66',
                    '7777777',
                  ],
                  displayToStr: (option) => option,
                  cancel: '取消',
                  selected: '5555555');

              AnConsole.showToast('你选择了$select');
            },
            child: Text('OptionSelect'),
          ),
          TextButton(
            onPressed: () async {
              final select = await AnConsole.showOptionMultiSelect<String>(
                  title: '请选择',
                  options: [
                    '12111111',
                    '222222',
                    '33333333333',
                    '44444444444',
                    '5555555',
                    '66',
                    '7777777',
                  ],
                  displayToStr: (option) => option,
                  selected: ['12111111', '44444444444'],
                  confirmLabel: '确定');

              AnConsole.showToast('你选择了$select');
            },
            child: Text('OptionMulti'),
          ),
        ],
      ),
    );
  }
}

class DebugDemo2 extends StatelessWidget {
  final String param;

  const DebugDemo2({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('这是跳转的页面,构造函数传入参数:$param'),
    );
  }
}

class SharedPreferencesViewer extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const SharedPreferencesViewer({super.key, required this.sharedPreferences});

  @override
  State<SharedPreferencesViewer> createState() =>
      _SharedPreferencesViewerState();
}

class _SharedPreferencesViewerState extends State<SharedPreferencesViewer> {
  @override
  Widget build(BuildContext context) {
    final keys = widget.sharedPreferences.getKeys().toList();
    return ListView.separated(
        itemBuilder: (_, index) {
          final key = keys[index];
          final value = widget.sharedPreferences.get(key);
          return ListTile(
            title: Text(key),
            subtitle: Text(value.toString()),
            onTap: () async {
              final select = await AnConsole.showConfirm(content: '是否要删除$key？');
              if (select) {
                await widget.sharedPreferences.remove(key);
                setState(() {});
              }
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: keys.length);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //必须在WidgetsFlutterBinding.ensureInitialized 之后使用
  AnConsole.instance.addConsole('Conf', DebugConfig());
  AnConsole.instance.addConsole('DebugDemo', DebugDemo());

  runApp(const MyApp());

  //放在runApp之后也可以
  SharedPreferences.getInstance().then((sp) => AnConsole.instance
      .addConsole('SP', SharedPreferencesViewer(sharedPreferences: sp)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnConsole Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AnConsole Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

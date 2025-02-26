A developer can fully customize the console content, which can be used to display logs on the UI,
serve as an app configuration center, and more functionalities.

```dart

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //必须在WidgetsFlutterBinding.ensureInitialized 之后使用
  AnConsole.instance.addConsole('Conf', DebugConfig());
  AnConsole.instance.addConsole('DebugDemo', DebugDemo());

  runApp(const MyApp());

  //放在runApp之后也可以
}
```

See [example](https://github.com/aymtools/an_console/blob/master/example/) for detailed test
case.

## Additional information

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/an_console/issues):


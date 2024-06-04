A developer can fully customize the console content, which can be used to display logs on the UI,
serve as an app configuration center, and more functionalities.

```dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //必须在WidgetsFlutterBinding.ensureInitialized 之后使用
  AnConsole.instance.addConsole('Conf', DebugConfig());
  AnConsole.instance.addConsole('DebugDemo', DebugDemo());
  // 加入任何你自定义的widget，并且给他一个title

  runApp(const MyApp());

  //放在runApp之后也可以
}


```

See [example](https://github.com/aymtools/an_console/blob/master/example/) for detailed test
case.

## Additional information

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/an_console/issues):


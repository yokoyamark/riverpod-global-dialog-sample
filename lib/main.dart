import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dialogs/dialog_presenter.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Global Dialog Sample',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      routerConfig: router,
      // ダイアログを表示する唯一の場所。Router の外に常設する
      builder: (context, child) =>
          DialogPresenter(child: child ?? const SizedBox.shrink()),
    );
  }
}

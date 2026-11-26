import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug/dialog_queue_panel.dart';
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
      // 漢字を日本語グリフで描画するためにロケールを固定する（Han 統合対策）
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // ダイアログを表示する唯一の場所。Router の外に常設する
      builder: (context, child) => DialogPresenter(
        child: Column(
          children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            // 【デモ用】キューの中身を見せるパネル。Navigator の外なので
            // ダイアログに覆われない
            const DialogQueuePanel(),
          ],
        ),
      ),
    );
  }
}

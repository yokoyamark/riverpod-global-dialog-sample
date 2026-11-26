import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug/dialog_queue_panel.dart';
import 'dialogs/dialog_presenter.dart';
import 'dialogs/dialog_request.dart';
import 'dialogs/dialog_slot_notifier.dart';
import 'router.dart';

void main() {
  final container = ProviderContainer();
  // 起動直後、DialogPresenter も Navigator もまだ無いうちに依頼する例。
  // DialogPresenter ができたところで拾われて表示される
  container
      .read(dialogSlotProvider.notifier)
      .request(
        MessageDialogRequest.info(
          key: 'app.launch',
          title: '起動時のお知らせ',
          message: '画面ができる前に依頼したお知らせです。',
        ),
      );
  runApp(UncontrolledProviderScope(container: container, child: const App()));
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

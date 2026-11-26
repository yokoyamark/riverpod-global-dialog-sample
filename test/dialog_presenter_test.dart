import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_global_dialog_sample/dialogs/dialog_request.dart';
import 'package:riverpod_global_dialog_sample/dialogs/dialog_slot_notifier.dart';
import 'package:riverpod_global_dialog_sample/main.dart';
import 'package:riverpod_global_dialog_sample/router.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    router.go('/');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();
  }

  void request(DialogRequest r) =>
      container.read(dialogSlotProvider.notifier).request(r);

  testWidgets('表示中に来た依頼は、閉じたあとに出る', (tester) async {
    await pumpApp(tester);

    request(MessageDialogRequest.info(key: 'a', message: 'A'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);

    // 表示に入った時点で枠は空いているので、normal でも保留される
    request(MessageDialogRequest.info(key: 'b', message: 'B'));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('critical は保留中の依頼より先に出て、押しのけた依頼もあとで出る', (tester) async {
    await pumpApp(tester);

    request(MessageDialogRequest.info(key: 'a', message: 'A'));
    await tester.pumpAndSettle();
    request(MessageDialogRequest.info(key: 'b', message: 'B'));
    request(
      MessageDialogRequest.info(
        key: 'c',
        message: 'C',
        priority: DialogPriority.critical,
      ),
    );

    for (final expected in ['A', 'C', 'B']) {
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      await tester.tap(find.text('閉じる'));
    }
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('依頼した画面を閉じてもダイアログは出る', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(find.text('詳細画面へ'), 100);
    await tester.tap(find.text('詳細画面へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存して戻る'));
    await tester.pumpAndSettle();

    expect(find.text('Global Dialog Sample'), findsOneWidget);
    expect(find.text('詳細画面で保存しました'), findsOneWidget);
  });

  testWidgets('リトライが失敗すると、同じ key で再び出る', (tester) async {
    await pumpApp(tester);
    var attempts = 0;

    late Future<void> Function() load;
    load = () async {
      attempts++;
      request(
        ErrorDialogRequest(
          key: 'load',
          title: '失敗',
          message: '$attempts 回目',
          onRetry: load,
        ),
      );
    };
    await load();
    await tester.pumpAndSettle();
    expect(find.text('1 回目'), findsOneWidget);

    await tester.tap(find.text('リトライ'));
    await tester.pumpAndSettle();
    expect(find.text('2 回目'), findsOneWidget);
  });

  testWidgets('critical でも表示中のダイアログは押しのけない', (tester) async {
    await pumpApp(tester);

    request(MessageDialogRequest.info(key: 'a', message: 'A'));
    await tester.pumpAndSettle();
    request(
      MessageDialogRequest.info(
        key: 'b',
        message: 'B',
        priority: DialogPriority.critical,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
  });

  // 強制アップデートはアプリを使わせないのが目的なので、閉じられるのを待たない
  testWidgets('blocking は表示中のダイアログを取り除いて出す', (tester) async {
    await pumpApp(tester);

    var closed = false;
    request(
      MessageDialogRequest.info(
        key: 'a',
        message: 'A',
        onClose: () => closed = true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);

    request(
      ForceUpdateDialogRequest(key: 'force', message: 'FORCE', onUpdate: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
    expect(find.text('FORCE'), findsOneWidget);
    // ボタンが押されたわけではないので、コールバックは呼ばない
    expect(closed, isFalse);
  });

  testWidgets('カウントダウンのあと、表示中のダイアログが強制アップデートに置き換わる', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(find.text('強制アップデート（5秒後）'), 100);
    await tester.tap(find.text('強制アップデート（5秒後）'));
    await tester.pumpAndSettle();
    expect(find.text('5 秒後に強制アップデートが来ます'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('4 秒後に強制アップデートが来ます'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.textContaining('秒後に強制アップデート'), findsNothing);
    expect(find.text('アップデートが必要です'), findsOneWidget);
  });

  testWidgets('同時に依頼したダイアログは来た順に1件ずつ出る', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('3件同時に依頼'));
    for (final expected in ['お知らせ 1', 'お知らせ 2', 'お知らせ 3']) {
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('閉じる'));
    }
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  // 表示前の1イベントループの間に critical が割り込んでも、同じ依頼を2回出さない
  testWidgets('同時に積んだ critical と normal は優先度順に1回ずつ出る', (tester) async {
    await pumpApp(tester);

    for (final (key, priority) in [
      ('n1', DialogPriority.normal),
      ('c2', DialogPriority.critical),
      ('n3', DialogPriority.normal),
      ('c4', DialogPriority.critical),
      ('n5', DialogPriority.normal),
    ]) {
      request(
        MessageDialogRequest.info(key: key, message: key, priority: priority),
      );
    }

    for (final expected in ['c2', 'c4', 'n1', 'n3', 'n5']) {
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      await tester.tap(find.text('閉じる'));
    }
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  // listen は値が変わったときにしか呼ばれないので、DialogPresenter が
  // できる前から積まれていた依頼を取りこぼさないこと
  testWidgets('起動前に積まれていた依頼も出る', (tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    request(MessageDialogRequest.info(key: 'boot', message: 'BOOT'));

    router.go('/');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();
    expect(find.text('BOOT'), findsOneWidget);
  });

  testWidgets('ダイアログのボタンから積んだ依頼は、閉じたあとに出る', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('ダイアログから次のダイアログ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('保存しました'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

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
}

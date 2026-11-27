import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dialogs/dialog_request.dart';
import '../dialogs/dialog_slot_notifier.dart';
import '../data/article_repository.dart';
import 'home_notifier.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = ref.read(dialogSlotProvider.notifier);
    final home = ref.read(homeNotifierProvider.notifier);

    void showResult(String text) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Global Dialog Sample')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoTile(
            title: '確認ダイアログ',
            subtitle: 'BuildContext を渡さずに依頼する',
            onTap: () => slot.request(
              MessageDialogRequest.confirm(
                key: 'home.confirm',
                message: '保存しますか？',
                onOk: () => showResult('OK が押されました'),
              ),
            ),
          ),
          _DemoTile(
            title: 'ダイアログから次のダイアログ',
            subtitle: 'OK のコールバックで依頼した完了ダイアログが、閉じたあとに出る',
            onTap: () => slot.request(
              MessageDialogRequest.confirm(
                key: 'home.chain.confirm',
                message: '保存しますか？',
                onOk: () => slot.request(
                  MessageDialogRequest.info(
                    key: 'home.chain.done',
                    message: '保存しました',
                  ),
                ),
              ),
            ),
          ),
          _DemoTile(
            title: '3件同時に依頼',
            subtitle: '待ち列に積まれ、発生した順に1件ずつ出る',
            onTap: () {
              for (var i = 1; i <= 3; i++) {
                slot.request(
                  MessageDialogRequest.info(
                    key: 'home.multi.$i',
                    message: 'お知らせ $i',
                  ),
                );
              }
            },
          ),
          _DemoTile(
            title: '優先度の混ざった5件を依頼',
            subtitle: '待ち列は critical が前、同じ優先度どうしは発生した順に並ぶ',
            onTap: () {
              const priorities = [
                DialogPriority.normal,
                DialogPriority.critical,
                DialogPriority.normal,
                DialogPriority.critical,
                DialogPriority.normal,
              ];
              for (final (i, priority) in priorities.indexed) {
                slot.request(
                  MessageDialogRequest.info(
                    key: 'home.mixed.${i + 1}',
                    message: '${i + 1}件目に依頼（${priority.name}）',
                    priority: priority,
                  ),
                );
              }
            },
          ),
          _DemoTile(
            title: '同じ key で3回依頼',
            subtitle: '同じ原因なので積み増さない',
            onTap: () {
              for (var i = 0; i < 3; i++) {
                slot.request(
                  MessageDialogRequest.info(
                    key: 'home.duplicated',
                    message: '同じ key の依頼は1件だけ出ます',
                  ),
                );
              }
            },
          ),
          _DemoTile(
            title: '読み込み（2回失敗してから成功）',
            subtitle: 'リトライ付きのエラーダイアログ',
            onTap: () {
              ref.read(articleRepositoryProvider).failNext(2);
              home.load();
            },
          ),
          _DemoTile(
            title: '割り込み',
            subtitle: '表示中・保留中のお知らせがある所へ critical が発生する',
            onTap: () async {
              slot.request(
                MessageDialogRequest.info(
                  key: 'home.interrupt.1',
                  message:
                      'お知らせ 1（表示中）\n\n'
                      '1秒ごとに、お知らせ 2（normal）とセッション切れ（critical）が'
                      '積まれます。下のパネルの動きを見てから閉じてください。',
                ),
              );
              // 1件ずつ間を空けて積み、パネルで枠と待ち列の変化を追えるようにする
              await Future<void>.delayed(const Duration(seconds: 1));
              slot.request(
                MessageDialogRequest.info(
                  key: 'home.interrupt.2',
                  message: 'お知らせ 2（critical に押しのけられて後回しになった）',
                ),
              );
              await Future<void>.delayed(const Duration(seconds: 1));
              home.onUnauthorized();
            },
          ),
          _DemoTile(
            title: '強制アップデート',
            subtitle: 'blocking。以降の依頼はすべて捨てられる',
            onTap: home.onForceUpdateRequired,
          ),
          _DemoTile(
            title: '強制アップデート（5秒後）',
            subtitle: '表示中の normal ダイアログを取り除いて blocking が出る',
            onTap: home.scheduleForceUpdate,
          ),
          _DemoTile(
            title: '詳細画面へ',
            subtitle: '依頼した画面が消えてもダイアログは出る',
            onTap: () => context.go('/detail'),
          ),
          _DemoTile(
            title: '詳細画面2へ',
            subtitle: 'critical のボタンで画面を閉じても、残りの依頼は出る',
            onTap: () => context.go('/detail2'),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

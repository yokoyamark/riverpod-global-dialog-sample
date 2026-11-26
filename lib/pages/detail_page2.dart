import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dialogs/dialog_request.dart';
import '../dialogs/dialog_slot_notifier.dart';

/// critical と normal をまとめて積み、critical のボタンで画面を閉じる例。
///
/// 画面を閉じても、待ち列に残った依頼は DialogPresenter が順に出す。
class DetailPage2 extends ConsumerWidget {
  const DetailPage2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void requestAll() {
      final slot = ref.read(dialogSlotProvider.notifier);
      const priorities = [
        DialogPriority.normal,
        DialogPriority.critical,
        DialogPriority.normal,
        DialogPriority.critical,
        DialogPriority.normal,
      ];
      for (final (i, priority) in priorities.indexed) {
        final key = 'detail2.${i + 1}';
        slot.request(
          priority == DialogPriority.critical
              ? MessageDialogRequest(
                  key: key,
                  title: '${i + 1}件目（critical）',
                  message: 'ボタンを押すと詳細画面2を閉じます。',
                  priority: priority,
                  canPop: false,
                  actions: [
                    DialogAction(
                      label: '画面を閉じる',
                      onPressed: () {
                        // 2件目の critical では、もう画面が閉じていることがある
                        if (context.mounted) context.pop();
                      },
                    ),
                  ],
                )
              : MessageDialogRequest.info(
                  key: key,
                  message: '${i + 1}件目（normal）',
                ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('詳細2')),
      body: Center(
        child: FilledButton(
          onPressed: requestAll,
          child: const Text('critical と normal を5件依頼'),
        ),
      ),
    );
  }
}

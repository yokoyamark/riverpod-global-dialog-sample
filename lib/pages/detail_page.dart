import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dialogs/dialog_request.dart';
import '../dialogs/dialog_slot_notifier.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('詳細')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            // 依頼してすぐ画面を閉じる。showDialog(context: context) だと
            // この context はもう使えないが、表示は Router の外にいる
            // DialogPresenter が行うので影響を受けない
            ref
                .read(dialogSlotProvider.notifier)
                .request(
                  MessageDialogRequest.info(
                    key: 'detail.saved',
                    message: '詳細画面で保存しました',
                  ),
                );
            context.pop();
          },
          child: const Text('保存して戻る'),
        ),
      ),
    );
  }
}

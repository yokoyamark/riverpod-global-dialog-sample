import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/dialog_request.dart';
import 'dialog_queue_snapshot.dart';

/// 【デモ用】表示中・枠・待ち列を画面下部に出すパネル。
///
/// Navigator の外に置くので、ダイアログのバリアに覆われずに見える。
class DialogQueuePanel extends ConsumerWidget {
  const DialogQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dialogQueueSnapshotProvider);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('ダイアログのキュー', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  if (snapshot.blocked)
                    Text(
                      'blocking 受付後: 以降の依頼は捨てる',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _Row(label: '表示中', requests: [?snapshot.presented]),
              _Row(label: '枠', requests: [?snapshot.slot]),
              _Row(label: '待ち列', requests: snapshot.waiting),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.requests});

  final String label;
  final List<DialogRequest> requests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: SizedBox(
              height: 28,
              child: requests.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '（空）',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: requests.length,
                      separatorBuilder: (_, _) =>
                          const Icon(Icons.chevron_right, size: 16),
                      itemBuilder: (_, index) =>
                          _RequestChip(request: requests[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestChip extends StatelessWidget {
  const _RequestChip({required this.request});

  final DialogRequest request;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.priority) {
      DialogPriority.normal => Colors.blueGrey,
      DialogPriority.critical => Colors.orange,
      DialogPriority.blocking => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${request.key}  ${request.priority.name}',
        style: TextStyle(fontSize: 12, color: color.shade900),
      ),
    );
  }
}

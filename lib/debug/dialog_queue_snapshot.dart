import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/dialog_request.dart';

/// 【デモ用】キューの中身を画面に出すためのスナップショット。
///
/// 待ち列は [DialogSlotNotifier] の内部に持っていて state には出ていないので、
/// 可視化のためだけにここへ写す。ダイアログの表示の判断には使わない。
@immutable
class DialogQueueSnapshot {
  const DialogQueueSnapshot({
    this.presented,
    this.slot,
    this.waiting = const [],
    this.blocked = false,
  });

  /// DialogPresenter が表示中の依頼
  final DialogRequest? presented;

  /// dialogSlotProvider の state（次に出す依頼）
  final DialogRequest? slot;

  /// 枠の次に出す依頼。先頭から順に出る
  final List<DialogRequest> waiting;

  /// blocking を受けて、以降の依頼を捨てているか
  final bool blocked;

  DialogQueueSnapshot copyWith({
    ValueGetter<DialogRequest?>? presented,
    ValueGetter<DialogRequest?>? slot,
    List<DialogRequest>? waiting,
    bool? blocked,
  }) {
    return DialogQueueSnapshot(
      presented: presented != null ? presented() : this.presented,
      slot: slot != null ? slot() : this.slot,
      waiting: waiting ?? this.waiting,
      blocked: blocked ?? this.blocked,
    );
  }
}

/// 【デモ用】キューの可視化専用の provider。
///
/// サンプルで dialogSlotProvider の動きを見せるためだけに置いている。実アプリに
/// 持ち込む必要はなく、ダイアログの仕組み自体はこれが無くても動く。
final dialogQueueSnapshotProvider =
    NotifierProvider<DialogQueueSnapshotNotifier, DialogQueueSnapshot>(
      DialogQueueSnapshotNotifier.new,
    );

/// 【デモ用】[dialogQueueSnapshotProvider] の Notifier。
class DialogQueueSnapshotNotifier extends Notifier<DialogQueueSnapshot> {
  @override
  DialogQueueSnapshot build() => const DialogQueueSnapshot();

  void updateQueue({
    required DialogRequest? slot,
    required List<DialogRequest> waiting,
    required bool blocked,
  }) {
    state = state.copyWith(
      slot: () => slot,
      waiting: List.unmodifiable(waiting),
      blocked: blocked,
    );
  }

  void updatePresented(DialogRequest? presented) {
    state = state.copyWith(presented: () => presented);
  }
}

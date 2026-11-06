import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dialog_request.dart';

final dialogSlotProvider = NotifierProvider<DialogSlotNotifier, DialogRequest?>(
  DialogSlotNotifier.new,
);

/// ダイアログの表示枠。同時にはひとつだけ保持する。
///
/// 依頼を積む（Producer）側はここへ request するだけで、表示中かどうかや
/// 画面が前面かどうかを気にしなくてよい。表示（Consumer）は DialogPresenter が
/// 一手に引き受ける。
class DialogSlotNotifier extends Notifier<DialogRequest?> {
  /// [DialogPriority.blocking] を受けたか。一度立つと以降どの依頼も受け付けない
  bool _blocked = false;

  /// 枠の次に出す依頼。優先度の高い順、同じ優先度なら来た順に並べる。
  ///
  /// 枠が埋まっているときに来た依頼と、[DialogPriority.critical] に
  /// 押しのけられた依頼がここに入る。捨てると、その依頼の onRetry /
  /// onDismiss が呼ばれないまま消える。それが唯一の出口になっている依頼も
  /// あるので、枠が空いたら順に出す。
  final List<DialogRequest> _waiting = [];

  @override
  DialogRequest? build() => null;

  /// 表示を依頼する。
  ///
  /// 枠が埋まっているときは待ち列に積み、先着から順に出す。同じ
  /// [DialogRequest.key] の依頼は同じ原因なので、枠でも待ち列でも積み増さない。
  /// [DialogPriority.critical] 以上だけが割り込み、同じ優先度どうしは来た順に
  /// 出す（先に起きた失敗のほうが根本原因であることが多いため）。
  /// [DialogPriority.blocking] のあとはどの依頼も捨てる。
  void request(DialogRequest request) {
    if (_blocked) {
      debugPrint('DialogSlot: blocked, dropped $request');
      return;
    }
    if (request.priority == DialogPriority.blocking) {
      debugPrint('DialogSlot: blocking $request');
      _blocked = true;
      // 以降どれも出さないので、待っている依頼は持っておかない
      _waiting.clear();
      state = request;
      return;
    }

    final current = state;
    if (current == null) {
      state = request;
      return;
    }
    if (current.key == request.key ||
        _waiting.any((waiting) => waiting.key == request.key)) {
      debugPrint('DialogSlot: duplicated $request');
      return;
    }
    // 枠と待ち列をひと続きの列とみなし、自分より優先度の低い依頼の前に入れる
    final queue = [current, ..._waiting];
    final index = queue.indexWhere(
      (queued) => queued.priority.index < request.priority.index,
    );
    queue.insert(index == -1 ? queue.length : index, request);
    debugPrint('DialogSlot: queued $request');
    state = queue.first;
    _waiting
      ..clear()
      ..addAll(queue.skip(1));
  }

  /// 依頼を取り下げる。
  ///
  /// 取り下げまでの間に別の依頼へ差し替わっていることがあるので、いま入って
  /// いる依頼が取り下げ対象と同じときだけ空にする。blocking は取り下げない。
  void dismiss(String key) {
    if (_blocked) return;
    if (state?.key != key) return;
    // 待っている依頼があれば、それを次に出す
    state = _waiting.isEmpty ? null : _waiting.removeAt(0);
  }
}

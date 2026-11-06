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

  /// [DialogPriority.critical] に押しのけられた依頼。
  ///
  /// 捨てると、その依頼の onRetry / onDismiss が呼ばれないまま消える。
  /// それが唯一の出口になっている依頼もあるので、押しのけた依頼が閉じたあとに
  /// 順に出す。
  final List<DialogRequest> _deferred = [];

  @override
  DialogRequest? build() => null;

  /// 表示を依頼する。
  ///
  /// 枠が埋まっているときは先着を優先する。同じ [DialogRequest.key] の依頼は
  /// 同じ原因なので積み増さず、[DialogPriority.critical] 以上だけが押しのける。
  ///
  /// 表示されるなら true（同じ key の依頼が保留中のときも、そちらが出るので
  /// true）。捨てたときは false。
  bool request(DialogRequest request) {
    if (_blocked) {
      debugPrint('DialogSlot: blocked, dropped $request');
      return false;
    }
    if (request.priority == DialogPriority.blocking) {
      debugPrint('DialogSlot: blocking $request');
      _blocked = true;
      state = request;
      return true;
    }

    final current = state;
    if (current != null) {
      if (current.key == request.key) {
        debugPrint('DialogSlot: duplicated $request');
        return true;
      }
      if (request.priority == DialogPriority.normal) {
        debugPrint('DialogSlot: dropped $request (pending $current)');
        return false;
      }
      debugPrint('DialogSlot: replaced $current with $request');
      _deferred.insert(0, current);
    }
    state = request;
    return true;
  }

  /// 依頼を取り下げる。
  ///
  /// 取り下げまでの間に別の依頼へ差し替わっていることがあるので、いま入って
  /// いる依頼が取り下げ対象と同じときだけ空にする。blocking は取り下げない。
  void dismiss(String key) {
    if (_blocked) return;
    if (state?.key != key) return;
    // 押しのけられていた依頼があれば、それを次に出す
    state = _deferred.isEmpty ? null : _deferred.removeAt(0);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/dialog_request.dart';
import '../dialogs/dialog_slot_notifier.dart';

// UI の外にいる Producer の例。BuildContext を持たなくてもダイアログを依頼できる。

/// 何回か失敗してから成功する読み込み
final articleRepositoryProvider = Provider((ref) => FakeArticleRepository());

class FakeArticleRepository {
  int _remainingFailures = 0;

  /// 次の [fetch] から [count] 回失敗させる
  void failNext(int count) => _remainingFailures = count;

  Future<String> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_remainingFailures > 0) {
      _remainingFailures--;
      throw Exception('通信に失敗しました（残り $_remainingFailures 回失敗します）');
    }
    return '記事の本文';
  }
}

/// API が 401 を返したときなど、セッション切れを通知する
final sessionServiceProvider = Provider(SessionService.new);

class SessionService {
  SessionService(this._ref);

  final Ref _ref;

  static const dialogKey = 'session.expired';

  void onUnauthorized() {
    _ref
        .read(dialogSlotProvider.notifier)
        .request(
          ErrorDialogRequest(
            key: dialogKey,
            title: 'セッションが切れました',
            message: 'もう一度ログインしてください。',
            priority: DialogPriority.critical,
          ),
        );
  }
}

/// 起動時のバージョンチェックなど
final appVersionServiceProvider = Provider(AppVersionService.new);

class AppVersionService {
  AppVersionService(this._ref);

  final Ref _ref;

  static const dialogKey = 'app.forceUpdate';

  void onForceUpdateRequired() {
    _ref
        .read(dialogSlotProvider.notifier)
        .request(
          ForceUpdateDialogRequest(
            key: dialogKey,
            message: '新しいバージョンをインストールしてください。',
            onUpdate: () {
              // 実アプリではストアを開く
            },
          ),
        );
  }

  static const countdownDialogKey = 'app.forceUpdateCountdown';

  /// [seconds] 秒数えてから強制アップデートを出す。
  ///
  /// 数えている間は normal のダイアログを出しておく。blocking が来ると、
  /// 表示中のダイアログは閉じられるのを待たずに取り除かれる。
  void scheduleForceUpdate({int seconds = 5}) {
    final remaining = ValueNotifier(seconds);
    final requested = _ref
        .read(dialogSlotProvider.notifier)
        .request(
          MessageDialogRequest.info(
            key: countdownDialogKey,
            message: '',
            content: ValueListenableBuilder(
              valueListenable: remaining,
              builder: (context, value, _) => Text('$value 秒後に強制アップデートが来ます'),
            ),
          ),
        );
    if (!requested) return;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining.value--;
      if (remaining.value > 0) return;
      timer.cancel();
      onForceUpdateRequired();
    });
  }
}

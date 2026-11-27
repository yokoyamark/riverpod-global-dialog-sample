import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/article_repository.dart';
import '../dialogs/dialog_request.dart';
import '../dialogs/dialog_slot_notifier.dart';

/// ホーム画面の状態と処理を持つ Notifier。
///
/// Widget の外にいる Producer の例。BuildContext を持たなくてもダイアログを依頼できる。
/// state は読み込んだ本文。
final homeNotifierProvider = NotifierProvider<HomeNotifier, String?>(
  HomeNotifier.new,
);

class HomeNotifier extends Notifier<String?> {
  static const loadKey = 'home.load';
  static const sessionExpiredKey = 'session.expired';
  static const forceUpdateKey = 'app.forceUpdate';
  static const countdownKey = 'app.forceUpdateCountdown';

  @override
  String? build() => null;

  DialogSlotNotifier get _slot => ref.read(dialogSlotProvider.notifier);

  /// 本文を読み込む。失敗したらリトライ付きのエラーダイアログを依頼する
  Future<void> load() async {
    try {
      final body = await ref.read(articleRepositoryProvider).fetch();
      if (!ref.mounted) return;
      state = body;
      _slot.request(
        MessageDialogRequest.info(key: loadKey, message: '読み込めました: $body'),
      );
    } on Exception catch (e) {
      if (!ref.mounted) return;
      // リトライがまた失敗しても、表示に入った時点で枠は空いているので、
      // 同じ key でも落とされない
      _slot.request(
        ErrorDialogRequest(
          key: loadKey,
          title: '読み込みに失敗しました',
          message: '$e',
          onRetry: load,
        ),
      );
    }
  }

  /// API が 401 を返したときなど、セッション切れを知らせる
  void onUnauthorized() {
    _slot.request(
      ErrorDialogRequest(
        key: sessionExpiredKey,
        title: 'セッションが切れました',
        message: 'もう一度ログインしてください。',
        priority: DialogPriority.critical,
      ),
    );
  }

  /// バージョンチェックで強制アップデートが必要だと分かったとき
  void onForceUpdateRequired() {
    _slot.request(
      ForceUpdateDialogRequest(
        key: forceUpdateKey,
        message: '新しいバージョンをインストールしてください。',
        onUpdate: () {
          // 実アプリではストアを開く
        },
      ),
    );
  }

  /// [seconds] 秒数えてから強制アップデートを出す。
  ///
  /// 数えている間は normal のダイアログを出しておく。blocking の依頼が発生すると、
  /// 表示中のダイアログは閉じられるのを待たずに取り除かれる。
  void scheduleForceUpdate({int seconds = 5}) {
    final remaining = ValueNotifier(seconds);
    _slot.request(
      MessageDialogRequest.info(
        key: countdownKey,
        message: '',
        content: ValueListenableBuilder(
          valueListenable: remaining,
          builder: (context, value, _) => Text('$value 秒後に強制アップデートが発生します'),
        ),
      ),
    );
    Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining.value--;
      if (remaining.value > 0) return;
      timer.cancel();
      onForceUpdateRequired();
    });
  }
}

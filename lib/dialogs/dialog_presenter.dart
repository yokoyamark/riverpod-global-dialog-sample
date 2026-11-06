import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router.dart';
import 'dialog_request.dart';
import 'dialog_slot_notifier.dart';

part 'dialog_presenter_views.dart';

/// [dialogSlotProvider] に積まれた依頼を表示する唯一の場所（Consumer）。
///
/// MaterialApp.router の builder に常設する。builder の context は
/// go_router の Navigator より上にあるため、この context から Navigator は
/// 辿れない。表示には [rootNavigatorKey] の context を使う。
class DialogPresenter extends ConsumerStatefulWidget {
  const DialogPresenter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DialogPresenter> createState() => _DialogPresenterState();
}

class _DialogPresenterState extends ConsumerState<DialogPresenter> {
  /// 表示中に次の依頼が来ても二重に showDialog しないためのフラグ
  bool _showing = false;

  /// 表示中の依頼と、それを出している route。route は表示されてから知らされる
  DialogRequest? _presented;
  Route<dynamic>? _presentedRoute;

  /// Navigator がまだ無いときに、表示をやり直すためのタイマー
  Timer? _retryTimer;

  static const _navigatorPollInterval = Duration(milliseconds: 100);

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DialogRequest?>(dialogSlotProvider, (previous, next) {
      if (next == null) return;
      _schedulePreemption();
      unawaited(_pump());
    });
    return widget.child;
  }

  /// 枠が空になるまで、依頼を1件ずつ表示する
  Future<void> _pump() async {
    if (_showing) return;
    _showing = true;
    try {
      while (true) {
        final request = ref.read(dialogSlotProvider);
        if (request == null) return;

        // 依頼が積まれたのが build 中のことがあるので、その場で route を
        // push せず1イベントループ遅らせる
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;

        final navigatorContext = rootNavigatorKey.currentContext;
        if (navigatorContext == null || !navigatorContext.mounted) {
          // Navigator がまだ無い。枠が埋まっている間に来た依頼は待ち列に
          // 入るだけで state が変わらず listen も呼ばれないので、少し待って
          // 自分で出し直す
          _retryTimer?.cancel();
          _retryTimer = Timer(_navigatorPollInterval, () {
            if (mounted) unawaited(_pump());
          });
          return;
        }

        // 表示に入る時点で枠を空ける。表示中に積まれた依頼は枠に残り、
        // 閉じたあとループの次の周で出す
        ref.read(dialogSlotProvider.notifier).dismiss(request.key);

        _presented = request;
        try {
          await _show(navigatorContext, request);
        } finally {
          _presented = null;
          _presentedRoute = null;
        }
      }
    } finally {
      _showing = false;
    }
  }

  void _onRoute(Route<dynamic> route) {
    _presentedRoute = route;
    // route が知らされる前に blocking が来ていることがある
    _schedulePreemption();
  }

  /// blocking の依頼が待っていたら、表示中のダイアログを取り除く。
  ///
  /// 強制アップデートはアプリを使わせないのが目的なので、表示中のダイアログが
  /// 閉じられるのを待たない。取り除いたダイアログは出し直さない（以降どの
  /// 依頼も出さないため）。ボタンが押されたわけではないので onDismiss などの
  /// コールバックは呼ばない。
  ///
  /// critical は表示中のダイアログを押しのけない。読んでいるダイアログが
  /// 消えて後で出直すのはわかりにくいため。
  ///
  /// 依頼は build 中に積まれることがあり、route はダイアログの build 中に
  /// 知らされるので、Navigator の操作は1イベントループ遅らせる。
  void _schedulePreemption() {
    unawaited(
      Future(() {
        if (!mounted) return;
        final route = _presentedRoute;
        if (route == null || !route.isActive) return;
        if (_presented?.priority == DialogPriority.blocking) return;
        final pending = ref.read(dialogSlotProvider);
        if (pending?.priority != DialogPriority.blocking) return;
        debugPrint('DialogPresenter: preempted $_presented by $pending');
        // 取り除くと route の Future が完了し、_pump が blocking を出す
        route.navigator?.removeRoute(route);
      }),
    );
  }

  Future<void> _show(BuildContext context, DialogRequest request) {
    return switch (request) {
      MessageDialogRequest() => _showMessageDialog(context, request, _onRoute),
      ErrorDialogRequest() => _showErrorDialog(context, request, _onRoute),
      ForceUpdateDialogRequest() => _showForceUpdateDialog(
        context,
        request,
        _onRoute,
      ),
    };
  }
}

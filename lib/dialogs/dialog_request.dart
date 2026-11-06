import 'package:flutter/material.dart';

/// 保留中の依頼をどこまで押しのけるか。
enum DialogPriority {
  /// 割り込まず、来た順に待つ
  normal,

  /// 保留中の依頼を押しのける（セッション切れなど放置できないもの）
  critical,

  /// 何よりも強い。これが出たら以降どの依頼も受け付けない（強制アップデートなど）
  blocking,
}

/// ダイアログの表示依頼。
///
/// 表示そのものは DialogPresenter が行う。呼び出し側は「何を出したいか」と
/// 「押されたら何をするか」だけを渡す。
@immutable
sealed class DialogRequest {
  const DialogRequest({
    required this.key,
    this.priority = DialogPriority.normal,
  });

  /// 同じ原因の依頼を積み増さないためのキー（例: `home.load`）
  final String key;

  final DialogPriority priority;
}

/// ボタンの見た目
enum DialogActionStyle { normal, destructive }

/// [MessageDialogRequest] のボタン。押されたら [onPressed] を呼んでから閉じる。
@immutable
final class DialogAction {
  const DialogAction({
    required this.label,
    this.onPressed,
    this.style = DialogActionStyle.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final DialogActionStyle style;
}

/// 文言とボタンだけのダイアログ。確認・案内に使う。
final class MessageDialogRequest extends DialogRequest {
  const MessageDialogRequest({
    required super.key,
    required this.message,
    required this.actions,
    this.title,
    this.content,
    this.canPop = true,
    super.priority,
  });

  /// 「キャンセル」「OK」の確認
  factory MessageDialogRequest.confirm({
    required String key,
    required String message,
    String? title,
    VoidCallback? onOk,
    VoidCallback? onCancel,
    DialogPriority priority = DialogPriority.normal,
  }) {
    return MessageDialogRequest(
      key: key,
      title: title,
      message: message,
      priority: priority,
      actions: [
        DialogAction(label: 'キャンセル', onPressed: onCancel),
        DialogAction(label: 'OK', onPressed: onOk),
      ],
    );
  }

  /// 「閉じる」だけの案内
  factory MessageDialogRequest.info({
    required String key,
    required String message,
    String? title,
    Widget? content,
    VoidCallback? onClose,
    DialogPriority priority = DialogPriority.normal,
  }) {
    return MessageDialogRequest(
      key: key,
      title: title,
      message: message,
      content: content,
      priority: priority,
      actions: [DialogAction(label: '閉じる', onPressed: onClose)],
    );
  }

  final String? title;
  final String message;

  /// [message] の代わりに出す本文。カウントダウンなど、表示中に変わる本文に使う
  final Widget? content;

  /// 左から順に並べる
  final List<DialogAction> actions;

  /// 端末の戻る操作で閉じさせるか。false ならボタンを選ばせる
  final bool canPop;

  @override
  String toString() => 'MessageDialogRequest($key: $message)';
}

/// エラーダイアログ。リトライと、閉じる側のボタンを持つ。
final class ErrorDialogRequest extends DialogRequest {
  const ErrorDialogRequest({
    required super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.canDismiss = true,
    super.priority,
  }) : assert(onRetry != null || canDismiss, 'リトライも閉じるも無いとダイアログから抜けられない');

  final String title;
  final String message;

  /// null ならリトライできないエラーとして「閉じる」だけを出す
  final Future<void> Function()? onRetry;

  /// 「キャンセル」「閉じる」で呼ばれる
  final VoidCallback? onDismiss;

  /// false にするとリトライしか選べない（閉じても行き先が無い場面用）
  final bool canDismiss;

  @override
  String toString() => 'ErrorDialogRequest($key: $title)';
}

/// 強制アップデート。ボタンを押しても閉じない。
final class ForceUpdateDialogRequest extends DialogRequest {
  const ForceUpdateDialogRequest({
    required super.key,
    required this.message,
    required this.onUpdate,
  }) : super(priority: DialogPriority.blocking);

  final String message;

  /// 「アップデート」で呼ばれる（ストアを開くなど）
  final VoidCallback onUpdate;

  @override
  String toString() => 'ForceUpdateDialogRequest($key)';
}

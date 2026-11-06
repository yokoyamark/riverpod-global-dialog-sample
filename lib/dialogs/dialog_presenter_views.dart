part of 'dialog_presenter.dart';

// ダイアログの見た目。出すのは DialogPresenter だけなので、ここに閉じておく。
// どれも閉じられるまで待てる Future を返し、DialogPresenter が次の依頼を
// 出す判断に使う。

Future<void> _showMessageDialog(
  BuildContext context,
  MessageDialogRequest request,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: request.canPop,
      child: AlertDialog(
        title: request.title == null ? null : Text(request.title!),
        content: Text(request.message),
        actions: [
          for (final action in request.actions)
            TextButton(
              onPressed: () {
                action.onPressed?.call();
                Navigator.pop(dialogContext);
              },
              style: action.style == DialogActionStyle.destructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text(action.label),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showErrorDialog(
  BuildContext context,
  ErrorDialogRequest request,
) {
  final onRetry = request.onRetry;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      // 端末の戻る操作では閉じさせず、ボタンを選ばせる
      canPop: false,
      child: AlertDialog(
        title: Text(request.title),
        content: Text(request.message),
        actions: [
          if (request.canDismiss)
            TextButton(
              onPressed: () {
                request.onDismiss?.call();
                Navigator.pop(dialogContext);
              },
              child: Text(onRetry == null ? '閉じる' : 'キャンセル'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                // 閉じてからリトライする。リトライがまた失敗したら、
                // 新しい依頼として積まれる
                Navigator.pop(dialogContext);
                unawaited(onRetry());
              },
              child: const Text('リトライ'),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showForceUpdateDialog(
  BuildContext context,
  ForceUpdateDialogRequest request,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('アップデートが必要です'),
        content: Text(request.message),
        actions: [
          // 押しても閉じない。ストアから戻ってきても、またここで止まる
          TextButton(onPressed: request.onUpdate, child: const Text('アップデート')),
        ],
      ),
    ),
  );
}

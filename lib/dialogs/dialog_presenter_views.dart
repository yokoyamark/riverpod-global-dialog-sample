part of 'dialog_presenter.dart';

// ダイアログの見た目。出すのは DialogPresenter だけなので、ここに閉じておく。
// どれも閉じられるまで待てる Future を返し、DialogPresenter が次の依頼を
// 出す判断に使う。

Future<void> _showMessageDialog(
  BuildContext context,
  MessageDialogRequest request,
  ValueChanged<Route<dynamic>> onRoute,
) {
  return _showPresentedDialog(
    context: context,
    onRoute: onRoute,
    builder: (dialogContext) => PopScope(
      canPop: request.canPop,
      child: AlertDialog(
        title: request.title == null ? null : Text(request.title!),
        content: request.content ?? Text(request.message),
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
  ValueChanged<Route<dynamic>> onRoute,
) {
  final onRetry = request.onRetry;
  return _showPresentedDialog(
    context: context,
    onRoute: onRoute,
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
  ValueChanged<Route<dynamic>> onRoute,
) {
  return _showPresentedDialog(
    context: context,
    onRoute: onRoute,
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

/// Presenter から出すダイアログの共通部分。
///
/// [onRoute] には表示した route を渡す。blocking の依頼が来たときに
/// DialogPresenter が表示中のダイアログを取り除くために使う。
Future<void> _showPresentedDialog({
  required BuildContext context,
  required ValueChanged<Route<dynamic>> onRoute,
  required WidgetBuilder builder,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _RouteReporter(onRoute: onRoute, child: builder(dialogContext)),
  );
}

/// 自分を表示している route を [onRoute] で知らせる
class _RouteReporter extends StatefulWidget {
  const _RouteReporter({required this.onRoute, required this.child});

  final ValueChanged<Route<dynamic>> onRoute;
  final Widget child;

  @override
  State<_RouteReporter> createState() => _RouteReporterState();
}

class _RouteReporterState extends State<_RouteReporter> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) widget.onRoute(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

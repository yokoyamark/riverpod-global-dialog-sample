# riverpod-global-dialog-sample

Flutter + Riverpod で、アプリ全体のダイアログを1か所から出すためのサンプルです。

- **Producer**: 画面やサービスは `dialogSlotProvider` に「表示の依頼」を積むだけ。`BuildContext` は不要です。
- **Consumer**: `MaterialApp.router` の `builder`（Router の外）に置いた `DialogPresenter` が、依頼を1件ずつ表示します。
- **優先度**: `normal`（先着優先・後着は捨てる）/ `critical`（保留中の依頼を押しのけ、押しのけた依頼はあとで出す）/ `blocking`（以降の依頼をすべて捨てる）。同じ `key` の依頼は積み増しません。

## 構成

```
lib/
├── main.dart                         # DialogPresenter を builder に常設
├── router.dart                       # rootNavigatorKey
├── dialogs/
│   ├── dialog_request.dart           # 依頼の型（sealed class）と優先度
│   ├── dialog_slot_notifier.dart     # 表示枠（キュー）
│   ├── dialog_presenter.dart         # 依頼を順に表示する Consumer
│   └── dialog_presenter_views.dart   # ダイアログの見た目
├── services/fake_services.dart       # UI の外にいる Producer の例
└── pages/                            # デモ画面
```

## 動かす

```sh
flutter pub get
flutter run
flutter test
```

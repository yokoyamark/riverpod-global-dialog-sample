# riverpod-global-dialog-sample

Flutter + Riverpod で、アプリ全体のダイアログを1か所から出すためのサンプルです。

ブラウザで触れるデモ: https://yokoyamark.github.io/riverpod-global-dialog-sample/

- 画面下部のパネルに、表示中・枠・待ち列の中身が出ます（デモ用）。
- 「強制アップデート」を押したあとは、ページを再読み込みするまでほかの依頼を受け付けません。

- **Producer**: 画面やサービスは `dialogSlotProvider` に「表示の依頼」を積むだけ。`BuildContext` は不要です。
- **Consumer**: `MaterialApp.router` の `builder`（Router の外）に置いた `DialogPresenter` が、依頼を1件ずつ表示します。
- **優先度**: 待ち列は優先度の高い順、同じ優先度なら発生した順に並びます。同じ `key` の依頼は枠でも待ち列でも積み増しません。
  - `normal`: 割り込まず、発生した順に待つ
  - `critical`: 保留中の依頼より先に出る。押しのけた依頼はあとで出す。表示中のダイアログは押しのけない
  - `blocking`: 表示中のダイアログを取り除いて出す。以降の依頼はすべて捨てる

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

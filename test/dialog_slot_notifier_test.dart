import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_global_dialog_sample/dialogs/dialog_request.dart';
import 'package:riverpod_global_dialog_sample/dialogs/dialog_slot_notifier.dart';

MessageDialogRequest info(
  String key, {
  DialogPriority priority = DialogPriority.normal,
}) => MessageDialogRequest.info(key: key, message: key, priority: priority);

void main() {
  late ProviderContainer container;
  DialogSlotNotifier slot() => container.read(dialogSlotProvider.notifier);
  DialogRequest? current() => container.read(dialogSlotProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  // 注意のあとに続くエラーのように、別の原因の依頼を取りこぼさない
  test('枠が埋まっているときは待ち列に積み、先着から順に出す', () {
    slot()
      ..request(info('a'))
      ..request(info('b'));

    expect(current()?.key, 'a');
    slot().dismiss('a');
    expect(current()?.key, 'b');
    slot().dismiss('b');
    expect(current(), isNull);
  });

  test('同じ key は積み増さない', () {
    final first = info('a');
    slot()
      ..request(first)
      ..request(info('a'));

    expect(current(), same(first));
    slot().dismiss('a');
    expect(current(), isNull);
  });

  test('critical は待っている normal より先に出す', () {
    slot()
      ..request(info('first'))
      ..request(info('waiting'))
      ..request(info('critical', priority: DialogPriority.critical));

    expect(current()?.key, 'critical');
    slot().dismiss('critical');
    expect(current()?.key, 'first');
    slot().dismiss('first');
    expect(current()?.key, 'waiting');
  });

  // 先に起きた失敗のほうが根本原因であることが多い
  test('critical 同士は発生した順に出す', () {
    slot()
      ..request(info('pending'))
      ..request(info('first', priority: DialogPriority.critical))
      ..request(info('second', priority: DialogPriority.critical));

    expect(current()?.key, 'first');
    slot().dismiss('first');
    expect(current()?.key, 'second');
    slot().dismiss('second');
    expect(current()?.key, 'pending');
  });

  test('待ち列にある依頼と同じキーの依頼は積み増さない', () {
    slot()
      ..request(info('load'))
      ..request(info('unauthorized', priority: DialogPriority.critical))
      // load は待ち列にいるので、critical でも積み増さない
      ..request(info('load', priority: DialogPriority.critical));

    slot().dismiss('unauthorized');
    expect(current()?.key, 'load');
    slot().dismiss('load');
    expect(current(), isNull);
  });

  test('blocking のあとはどの依頼も受け付けず、取り下げもできない', () {
    slot()
      ..request(info('waiting'))
      ..request(
        ForceUpdateDialogRequest(key: 'force', message: '', onUpdate: () {}),
      )
      ..request(info('a', priority: DialogPriority.critical));

    expect(current()?.key, 'force');
    slot().dismiss('force');
    expect(current()?.key, 'force');
  });

  test('取り下げは、いま入っている依頼と key が一致するときだけ', () {
    slot().request(info('a'));
    slot().dismiss('other');
    expect(current()?.key, 'a');
  });
}

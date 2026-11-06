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

  test('normal は先着優先で、後から来たものは捨てる', () {
    expect(slot().request(info('a')), isTrue);
    expect(slot().request(info('b')), isFalse);
    expect(current()?.key, 'a');
  });

  test('同じ key は積み増さないが、表示されるので true', () {
    final first = info('a');
    slot().request(first);
    expect(slot().request(info('a')), isTrue);
    expect(current(), same(first));
  });

  test('critical は保留中の依頼を押しのけ、取り下げ後に押しのけた依頼を出す', () {
    slot().request(info('a'));
    expect(
      slot().request(info('b', priority: DialogPriority.critical)),
      isTrue,
    );
    expect(current()?.key, 'b');

    slot().dismiss('b');
    expect(current()?.key, 'a');
    slot().dismiss('a');
    expect(current(), isNull);
  });

  test('blocking のあとはどの依頼も受け付けず、取り下げもできない', () {
    slot().request(
      ForceUpdateDialogRequest(key: 'force', message: '', onUpdate: () {}),
    );
    expect(
      slot().request(info('a', priority: DialogPriority.critical)),
      isFalse,
    );
    slot().dismiss('force');
    expect(current()?.key, 'force');
  });

  test('取り下げは、いま入っている依頼と key が一致するときだけ', () {
    slot().request(info('a'));
    slot().dismiss('other');
    expect(current()?.key, 'a');
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

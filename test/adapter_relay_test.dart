import 'package:flutter_test/flutter_test.dart';
import '../tool/check_adapter_relay.dart' as relay_checks;

void main() {
  test('authenticated relay preserves adapter bytes and cleans up connections',
      () => relay_checks.runAdapterRelayChecks(requireLoopback: true), timeout: const Timeout(Duration(seconds: 30)));
}

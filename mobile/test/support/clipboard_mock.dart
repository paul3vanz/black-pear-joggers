import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Intercepts the platform clipboard channel and records what was copied
/// (like stubbing `navigator.clipboard.writeText` in Jest).
class ClipboardMock {
  ClipboardMock(TestWidgetsFlutterBinding binding) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  final copied = <String>[];
}

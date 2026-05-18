import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelTapresearchFlutterPlugin platform;
  const MethodChannel channel = MethodChannel('tapresearch_flutter_plugin');
  final calls = <MethodCall>[];

  setUp(() {
    platform = MethodChannelTapresearchFlutterPlugin();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          return switch (methodCall.method) {
            'isReady' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isReady invokes native method and returns result', () async {
    expect(await platform.isReady(), isTrue);
    expect(calls.single.method, 'isReady');
  });
}

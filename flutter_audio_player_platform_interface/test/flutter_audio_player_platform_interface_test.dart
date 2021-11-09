import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_audio_player_platform_interface');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await FlutterAudioPlayerPlatformInterface.platformVersion, '42');
  });
}

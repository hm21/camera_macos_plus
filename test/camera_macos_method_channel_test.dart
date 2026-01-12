import 'package:camera_macos_plus/camera_macos_arguments.dart';
import 'package:camera_macos_plus/camera_macos_file.dart';
import 'package:camera_macos_plus/camera_macos_method_channel.dart';
import 'package:camera_macos_plus/exceptions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MethodChannelCameraMacOS platform = MethodChannelCameraMacOS();
  const MethodChannel channel = MethodChannel('camera_macos');

  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return <String, dynamic>{
            'textureId': 1,
            'size': {'width': 1920.0, 'height': 1080.0},
            'devices': <Map<String, dynamic>>[],
          };
        case 'takePicture':
          return <String, dynamic>{
            'imageData': Uint8List.fromList([0, 1, 2, 3, 4, 5]),
          };
        case 'startRecording':
          return <String, dynamic>{
            'success': true,
          };
        case 'stopRecording':
          return <String, dynamic>{
            'videoData': Uint8List.fromList([0, 1, 2, 3, 4, 5]),
            'url': '/tmp/video.mp4',
          };
        case 'destroy':
          return <String, dynamic>{
            'success': true,
          };
        case 'onVideoRecordingFinished':
          dynamic args = methodCall.arguments;
          expect(args, isNot(null));
          expect(args, isA<Map<String, dynamic>>());
          expect(args['videoData'], isA<Uint8List>());
          break;
        default:
          return null;
      }
      return null;
    });
  });

  test(
    'initialize camera picture',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.photo,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
    },
  );

  test(
    'initialize camera video',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.video,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
    },
  );

  test(
    'take picture',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.photo,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
      CameraMacOSFile? file = await platform.takePicture();
      expect(file, isNot(null));
      expect(file?.bytes, isNot(null));
      expect(file?.bytes, isNotEmpty);
    },
  );

  test(
    'record short video',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.video,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
      bool? started = await platform.startVideoRecording(
          maxVideoDuration: 5,
          onVideoRecordingFinished:
              (CameraMacOSFile? file, CameraMacOSException? exception) {
            expect(file, isNot(null));
            expect(file?.bytes, isNot(null));
            expect(file?.bytes, isNotEmpty);
          });
      expect(started, isNot(null));
      expect(started, true);
    },
  );

  test(
    'record video and stop',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.video,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
      bool? started = await platform.startVideoRecording(
          onVideoRecordingFinished:
              (CameraMacOSFile? file, CameraMacOSException? exception) {
        expect(file, isNot(null));
        expect(file?.bytes, isNot(null));
        expect(file?.bytes, isNotEmpty);
        expect(platform.isRecording, false);
      });
      expect(started, isNot(null));
      expect(platform.isRecording, true);
      expect(started, true);
    },
  );

  test(
    'destroy',
    () async {
      CameraMacOSArguments? macOSArguments = await platform.initialize(
        cameraMacOSMode: CameraMacOSMode.video,
      );
      expect(macOSArguments, isNot(null));
      expect(macOSArguments?.textureId, isNot(null));
      expect(macOSArguments?.size.width, greaterThanOrEqualTo(0));
      expect(macOSArguments?.size.height, greaterThanOrEqualTo(0));
      bool? destroyed = await platform.destroy();
      expect(destroyed, isNot(null));
      expect(destroyed, true);
      expect(platform.isDestroyed, true);
    },
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

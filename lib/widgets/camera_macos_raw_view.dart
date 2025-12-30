import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraMacOSRawView extends StatelessWidget {
  const CameraMacOSRawView({
    super.key,
    this.usePlatformView = false,
    this.cameraSize,
    this.textureId,
    this.filterQuality = FilterQuality.low,
    this.onPlatformViewCreated,
  })  : assert(
          !usePlatformView || cameraSize != null,
          'cameraSize must not be null when usePlatformView is true',
        ),
        assert(
          usePlatformView || textureId != null,
          'textureId must not be null when usePlatformView is false',
        );

  final bool usePlatformView;
  final Size? cameraSize;
  final int? textureId;
  final FilterQuality filterQuality;
  final Function(int id)? onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    return usePlatformView
        ? UiKitView(
            viewType: 'camera_macos_view',
            onPlatformViewCreated: onPlatformViewCreated,
            creationParams: {
              'width': cameraSize!.width,
              'height': cameraSize!.height,
            },
            creationParamsCodec: const StandardMessageCodec(),
          )
        : Texture(textureId: textureId!, filterQuality: filterQuality);
  }
}

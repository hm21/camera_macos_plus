import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../camera_macos_method_channel.dart';
import '../camera_macos_platform_interface.dart';

class CameraMacOSRawView extends StatelessWidget {
  /// Creates a raw camera view widget.
  ///
  /// When [usePlatformView] is false (default), the widget will display the
  /// camera using a [Texture] widget. The [textureId] can be provided
  /// explicitly, or it will be automatically retrieved from the platform
  /// channel if the camera has been initialized.
  ///
  /// When [usePlatformView] is true, [cameraSize] must be provided.
  const CameraMacOSRawView({
    super.key,
    this.usePlatformView = false,
    this.cameraSize,
    this.textureId,
    this.filterQuality = FilterQuality.low,
    this.onPlatformViewCreated,
  }) : assert(
          !usePlatformView || cameraSize != null,
          'cameraSize must not be null when usePlatformView is true',
        );

  final bool usePlatformView;
  final Size? cameraSize;

  /// The texture ID to use for displaying the camera.
  /// If null, it will be automatically retrieved from the platform channel.
  final int? textureId;
  final FilterQuality filterQuality;
  final Function(int id)? onPlatformViewCreated;

  /// Returns the current texture ID from the platform channel, or null if
  /// the camera hasn't been initialized.
  static int? get currentTextureId {
    final instance = CameraMacOSPlatform.instance;
    if (instance is MethodChannelCameraMacOS) {
      return instance.lastTextureId;
    }
    return null;
  }

  /// Returns the current camera size from the platform channel, or null if
  /// the camera hasn't been initialized.
  static Size? get currentCameraSize {
    final instance = CameraMacOSPlatform.instance;
    if (instance is MethodChannelCameraMacOS) {
      return instance.lastCameraSize;
    }
    return null;
  }

  int? get _effectiveTextureId => textureId ?? currentTextureId;

  Size? get _effectiveCameraSize => cameraSize ?? currentCameraSize;

  @override
  Widget build(BuildContext context) {
    if (usePlatformView) {
      final size = _effectiveCameraSize;
      if (size == null) {
        return const SizedBox.shrink();
      }
      return UiKitView(
        viewType: 'camera_macos_view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: {
          'width': size.width,
          'height': size.height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    final id = _effectiveTextureId;
    if (id == null) {
      return const SizedBox.shrink();
    }
    return Texture(textureId: id, filterQuality: filterQuality);
  }
}

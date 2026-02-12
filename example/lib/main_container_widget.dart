import 'dart:io';

import 'package:camera_macos_plus/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme Constants
// ═══════════════════════════════════════════════════════════════════════════

class _AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const surface = Color(0xFF1E1E2E);
  static const surfaceLight = Color(0xFF2D2D3F);
  static const surfaceLighter = Color(0xFF3D3D4F);
  static const text = Color(0xFFF8F8F2);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFF4B5563);
}

class MainContainerWidget extends StatefulWidget {
  const MainContainerWidget({super.key});

  @override
  MainContainerWidgetState createState() => MainContainerWidgetState();
}

class MainContainerWidgetState extends State<MainContainerWidget> {
  // Controller & Key
  CameraMacOSController? macOSController;
  GlobalKey cameraKey = GlobalKey();

  // Devices
  List<CameraMacOSDevice> videoDevices = [];
  List<CameraMacOSDevice> audioDevices = [];
  String? selectedVideoDevice;
  String? selectedAudioDevice;

  // Camera Settings
  CameraMacOSMode cameraMode = CameraMacOSMode.photo;
  PictureResolution selectedResolution = PictureResolution.max;
  AudioQuality selectedAudioQuality = AudioQuality.min;
  PictureFormat selectedPictureFormat = PictureFormat.tiff;
  CameraOrientation selectedOrientation = CameraOrientation.orientation0deg;
  VideoFormat selectedVideoFormat = VideoFormat.mp4;
  AudioFormat selectedAudioFormat = AudioFormat.kAudioFormatAppleLossless;

  // Toggles
  bool enableAudio = true;
  bool enableTorch = false;
  bool usePlatformView = false;
  bool streamImage = false;
  bool isVideoMirrored = true;

  // State
  double zoom = 1.0;
  double videoDuration = 15;
  Uint8List? lastImagePreviewData;
  CameraImageData? streamedImage;
  File? lastPictureTaken;

  late TextEditingController durationController;

  @override
  void initState() {
    super.initState();
    durationController = TextEditingController(text: '$videoDuration');
    durationController.addListener(_onDurationChanged);

    // Auto-detect devices on startup
    _initDevices();
  }

  Future<void> _initDevices() async {
    await _listVideoDevices();
    await _listAudioDevices();
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  void _onDurationChanged() {
    final parsed = double.tryParse(durationController.text);
    if (parsed != null) {
      videoDuration = parsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _AppColors.surface,
        cardColor: _AppColors.surfaceLight,
        dividerColor: _AppColors.border,
        colorScheme: const ColorScheme.dark(
          primary: _AppColors.primary,
          secondary: _AppColors.secondary,
          surface: _AppColors.surfaceLight,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _AppColors.surfaceLight,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.videocam_rounded, color: _AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Camera MacOS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _AppColors.text,
                ),
              ),
            ],
          ),
        ),
        body: Row(
          children: [
            // Left Panel - Camera Preview
            Expanded(
              flex: 3,
              child: _CameraPanel(
                cameraKey: cameraKey,
                selectedVideoDevice: selectedVideoDevice,
                selectedAudioDevice: selectedAudioDevice,
                resolution: selectedResolution,
                audioQuality: selectedAudioQuality,
                pictureFormat: selectedPictureFormat,
                orientation: selectedOrientation,
                videoFormat: selectedVideoFormat,
                audioFormat: selectedAudioFormat,
                isVideoMirrored: isVideoMirrored,
                enableTorch: enableTorch,
                enableAudio: enableAudio,
                usePlatformView: usePlatformView,
                zoom: zoom,
                cameraMode: cameraMode,
                isRecording: macOSController?.isRecording ?? false,
                isDestroyed: macOSController?.isDestroyed ?? true,
                onZoomChanged: (value) {
                  macOSController?.setZoomLevel(value);
                  setState(() => zoom = value);
                },
                onCameraInitialized: (controller) {
                  setState(() => macOSController = controller);
                },
                onFocusPoint: (offset) =>
                    macOSController?.setFocusPoint(offset),
                lastImagePreviewData: lastImagePreviewData,
                onPreviewTap: _openPicture,
                streamedImage: streamedImage,
                onCapture: _onCameraButtonTap,
                onDestroy: _destroyCamera,
              ),
            ),

            // Right Panel - Settings
            Container(
              width: 340,
              decoration: const BoxDecoration(
                color: _AppColors.surfaceLight,
                border: Border(
                  left: BorderSide(color: _AppColors.border, width: 1),
                ),
              ),
              child: _SettingsSidebar(
                videoDevices: videoDevices,
                audioDevices: audioDevices,
                selectedVideoDevice: selectedVideoDevice,
                selectedAudioDevice: selectedAudioDevice,
                onVideoDeviceChanged: (id) =>
                    setState(() => selectedVideoDevice = id),
                onAudioDeviceChanged: (id) =>
                    setState(() => selectedAudioDevice = id),
                onListVideoDevices: _listVideoDevices,
                onListAudioDevices: _listAudioDevices,
                orientation: selectedOrientation,
                onOrientationChanged: (v) =>
                    setState(() => selectedOrientation = v),
                resolution: selectedResolution,
                onResolutionChanged: (v) =>
                    setState(() => selectedResolution = v),
                audioQuality: selectedAudioQuality,
                onAudioQualityChanged: (v) =>
                    setState(() => selectedAudioQuality = v),
                videoFormat: selectedVideoFormat,
                onVideoFormatChanged: (v) =>
                    setState(() => selectedVideoFormat = v),
                audioFormat: selectedAudioFormat,
                onAudioFormatChanged: (v) =>
                    setState(() => selectedAudioFormat = v),
                enableAudio: enableAudio,
                onEnableAudioChanged: (v) => setState(() => enableAudio = v),
                usePlatformView: usePlatformView,
                onUsePlatformViewChanged: (v) =>
                    setState(() => usePlatformView = v),
                enableTorch: enableTorch,
                onEnableTorchChanged: (v) {
                  setState(() => enableTorch = v);
                  macOSController?.toggleTorch(v ? Torch.on : Torch.off);
                },
                isVideoMirrored: isVideoMirrored,
                onIsVideoMirroredChanged: (v) {
                  setState(() => isVideoMirrored = v);
                  macOSController?.setVideoMirrored(v);
                },
                streamImage: streamImage,
                onStreamImageChanged: (v) => _toggleImageStream(v),
                cameraMode: cameraMode,
                onCameraModeChanged: (v) => setState(() => cameraMode = v),
                durationController: durationController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Business Logic
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> get _imageFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    return path.join(
      dir.path,
      'P_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.${selectedPictureFormat.name}',
    );
  }

  Future<String> get _videoFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    return path.join(
      dir.path,
      'V_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.${selectedVideoFormat.name}',
    );
  }

  Future<void> _listVideoDevices() async {
    try {
      final devices = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      setState(() {
        videoDevices = devices;
        if (devices.isNotEmpty) {
          selectedVideoDevice = devices.first.deviceId;
        }
      });
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _listAudioDevices() async {
    try {
      final devices = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.audio,
      );
      setState(() {
        audioDevices = devices;
        if (devices.isNotEmpty) {
          selectedAudioDevice = devices.first.deviceId;
        }
      });
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _destroyCamera() async {
    try {
      if (macOSController != null) {
        if (macOSController!.isDestroyed) {
          setState(() => cameraKey = GlobalKey());
        } else {
          await macOSController?.destroy();
          setState(() {});
        }
      }
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _onCameraButtonTap() async {
    if (macOSController == null) return;

    try {
      switch (cameraMode) {
        case CameraMacOSMode.photo:
          final imageData = await macOSController!.takePicture();
          if (imageData != null) {
            setState(() => lastImagePreviewData = imageData.bytes);
            await _savePicture(lastImagePreviewData!);
            _showAlert(
                title: 'Success', message: 'Image successfully captured!');
          }
          break;

        case CameraMacOSMode.video:
          if (macOSController!.isRecording) {
            final videoData = await macOSController!.stopRecording();
            if (videoData != null) {
              _showAlert(
                  title: 'Success', message: 'Video saved at ${videoData.url}');
            }
          } else {
            await _startRecording();
          }
          break;
      }
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _startRecording() async {
    try {
      final urlPath = await _videoFilePath;
      await macOSController!.recordVideo(
        maxVideoDuration: videoDuration,
        url: urlPath,
        enableAudio: enableAudio,
        onVideoRecordingFinished: (result, exception) {
          setState(() {});
          if (exception != null) {
            _showAlert(message: exception.toString());
          } else if (result != null) {
            _showAlert(
                title: 'Success', message: 'Video saved at ${result.url}');
          }
        },
      );
      setState(() {});
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _savePicture(Uint8List photoBytes) async {
    try {
      final filename = await _imageFilePath;
      final file = File(filename);
      if (file.existsSync()) {
        file.deleteSync(recursive: true);
      }
      file
        ..createSync(recursive: true)
        ..writeAsBytesSync(photoBytes);
      lastPictureTaken = file;
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  Future<void> _openPicture() async {
    try {
      if (lastPictureTaken != null) {
        final uri = Uri.file(lastPictureTaken!.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      _showAlert(message: e.toString());
    }
  }

  void _toggleImageStream(bool enable) {
    if (macOSController == null) return;

    setState(() {
      streamImage = enable;
      if (enable) {
        macOSController!.startImageStream((image) {
          setState(() => streamedImage = image);
        });
      } else {
        macOSController!.stopImageStream();
        streamedImage = null;
      }
    });
  }

  Future<void> _showAlert({String title = 'Error', String message = ''}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: _AppColors.text)),
        content:
            Text(message, style: const TextStyle(color: _AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('OK', style: TextStyle(color: _AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Camera Panel (Left Side)
// ═══════════════════════════════════════════════════════════════════════════

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.cameraKey,
    required this.selectedVideoDevice,
    required this.selectedAudioDevice,
    required this.resolution,
    required this.audioQuality,
    required this.pictureFormat,
    required this.orientation,
    required this.videoFormat,
    required this.audioFormat,
    required this.isVideoMirrored,
    required this.enableTorch,
    required this.enableAudio,
    required this.usePlatformView,
    required this.zoom,
    required this.cameraMode,
    required this.isRecording,
    required this.isDestroyed,
    required this.onZoomChanged,
    required this.onCameraInitialized,
    required this.onFocusPoint,
    required this.lastImagePreviewData,
    required this.onPreviewTap,
    required this.streamedImage,
    required this.onCapture,
    required this.onDestroy,
  });

  final GlobalKey cameraKey;
  final String? selectedVideoDevice;
  final String? selectedAudioDevice;
  final PictureResolution resolution;
  final AudioQuality audioQuality;
  final PictureFormat pictureFormat;
  final CameraOrientation orientation;
  final VideoFormat videoFormat;
  final AudioFormat audioFormat;
  final bool isVideoMirrored;
  final bool enableTorch;
  final bool enableAudio;
  final bool usePlatformView;
  final double zoom;
  final CameraMacOSMode cameraMode;
  final bool isRecording;
  final bool isDestroyed;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<CameraMacOSController> onCameraInitialized;
  final ValueChanged<Offset> onFocusPoint;
  final Uint8List? lastImagePreviewData;
  final VoidCallback onPreviewTap;
  final CameraImageData? streamedImage;
  final VoidCallback onCapture;
  final VoidCallback onDestroy;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _AppColors.surface,
      child: Column(
        children: [
          Expanded(
            child: _buildCameraArea(context),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraArea(BuildContext context) {
    if (selectedVideoDevice == null || selectedVideoDevice!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 80,
              color: _AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No camera selected',
              style: TextStyle(
                color: _AppColors.textMuted,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click "Scan" to detect devices',
              style: TextStyle(
                color: _AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera View
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onTapDown: (details) {
                // Use the local position directly relative to the gesture area
                onFocusPoint(details.localPosition);
              },
              child: CameraMacOSView(
                key: cameraKey,
                deviceId: selectedVideoDevice,
                audioDeviceId: selectedAudioDevice,
                fit: BoxFit.contain,
                cameraMode: CameraMacOSMode.photo,
                resolution: resolution,
                audioQuality: audioQuality,
                pictureFormat: pictureFormat,
                orientation: orientation,
                videoFormat: videoFormat,
                audioFormat: audioFormat,
                isVideoMirrored: isVideoMirrored,
                toggleTorch: enableTorch ? Torch.on : Torch.off,
                enableAudio: enableAudio,
                usePlatformView: usePlatformView,
                onCameraInizialized: onCameraInitialized,
                onCameraDestroyed: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Zoom Slider
        /* Positioned(
          left: 32,
          top: 32,
          bottom: 100,
          child: _ZoomSlider(
            zoom: zoom,
            onChanged: onZoomChanged,
          ),
        ),*/

        // Last Image Thumbnail
        if (lastImagePreviewData != null)
          Positioned(
            right: 32,
            bottom: 32,
            child: GestureDetector(
              onTap: onPreviewTap,
              child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  lastImagePreviewData!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // Recording Indicator
        if (isRecording)
          Positioned(
            top: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _AppColors.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record,
                      color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: _AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Destroy/Reinitialize Button
          _ControlButton(
            icon: isDestroyed ? Icons.refresh_rounded : Icons.stop_rounded,
            label: isDestroyed ? 'Restart' : 'Stop',
            color: _AppColors.warning,
            onPressed: onDestroy,
          ),
          const SizedBox(width: 24),

          // Capture Button
          _CaptureButton(
            isRecording: isRecording,
            isVideo: cameraMode == CameraMacOSMode.video,
            onPressed: onCapture,
          ),
          const SizedBox(width: 24),

          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _AppColors.surfaceLighter,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  cameraMode == CameraMacOSMode.photo
                      ? Icons.photo_camera_rounded
                      : Icons.videocam_rounded,
                  color: _AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  cameraMode == CameraMacOSMode.photo ? 'Photo' : 'Video',
                  style: const TextStyle(
                    color: _AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({
    required this.zoom,
    required this.onChanged,
  });

  final double zoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: _AppColors.surfaceLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.zoom_in, color: _AppColors.textMuted, size: 18),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: _AppColors.primary,
                  inactiveTrackColor: _AppColors.border,
                  thumbColor: _AppColors.primary,
                  overlayColor: _AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: zoom,
                  min: 1.0,
                  max: 8.0,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const Icon(Icons.zoom_out, color: _AppColors.textMuted, size: 18),
          const SizedBox(height: 4),
          Text(
            '${zoom.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: _AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.isRecording,
    required this.isVideo,
    required this.onPressed,
  });

  final bool isRecording;
  final bool isVideo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecording ? _AppColors.danger : _AppColors.text,
            width: 4,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRecording ? BorderRadius.circular(8) : null,
            color: isRecording
                ? _AppColors.danger
                : (isVideo ? _AppColors.danger : _AppColors.text),
          ),
          margin: isRecording ? const EdgeInsets.all(12) : EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          iconSize: 28,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Settings Sidebar (Right Side)
// ═══════════════════════════════════════════════════════════════════════════

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.videoDevices,
    required this.audioDevices,
    required this.selectedVideoDevice,
    required this.selectedAudioDevice,
    required this.onVideoDeviceChanged,
    required this.onAudioDeviceChanged,
    required this.onListVideoDevices,
    required this.onListAudioDevices,
    required this.orientation,
    required this.onOrientationChanged,
    required this.resolution,
    required this.onResolutionChanged,
    required this.audioQuality,
    required this.onAudioQualityChanged,
    required this.videoFormat,
    required this.onVideoFormatChanged,
    required this.audioFormat,
    required this.onAudioFormatChanged,
    required this.enableAudio,
    required this.onEnableAudioChanged,
    required this.usePlatformView,
    required this.onUsePlatformViewChanged,
    required this.enableTorch,
    required this.onEnableTorchChanged,
    required this.isVideoMirrored,
    required this.onIsVideoMirroredChanged,
    required this.streamImage,
    required this.onStreamImageChanged,
    required this.cameraMode,
    required this.onCameraModeChanged,
    required this.durationController,
  });

  final List<CameraMacOSDevice> videoDevices;
  final List<CameraMacOSDevice> audioDevices;
  final String? selectedVideoDevice;
  final String? selectedAudioDevice;
  final ValueChanged<String?> onVideoDeviceChanged;
  final ValueChanged<String?> onAudioDeviceChanged;
  final VoidCallback onListVideoDevices;
  final VoidCallback onListAudioDevices;
  final CameraOrientation orientation;
  final ValueChanged<CameraOrientation> onOrientationChanged;
  final PictureResolution resolution;
  final ValueChanged<PictureResolution> onResolutionChanged;
  final AudioQuality audioQuality;
  final ValueChanged<AudioQuality> onAudioQualityChanged;
  final VideoFormat videoFormat;
  final ValueChanged<VideoFormat> onVideoFormatChanged;
  final AudioFormat audioFormat;
  final ValueChanged<AudioFormat> onAudioFormatChanged;
  final bool enableAudio;
  final ValueChanged<bool> onEnableAudioChanged;
  final bool usePlatformView;
  final ValueChanged<bool> onUsePlatformViewChanged;
  final bool enableTorch;
  final ValueChanged<bool> onEnableTorchChanged;
  final bool isVideoMirrored;
  final ValueChanged<bool> onIsVideoMirroredChanged;
  final bool streamImage;
  final ValueChanged<bool> onStreamImageChanged;
  final CameraMacOSMode cameraMode;
  final ValueChanged<CameraMacOSMode> onCameraModeChanged;
  final TextEditingController durationController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Devices Section
        _SectionHeader(
          title: 'Devices',
          icon: Icons.devices_rounded,
          trailing: IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: _AppColors.primary, size: 20),
            onPressed: () {
              onListVideoDevices();
              onListAudioDevices();
            },
            tooltip: 'Scan devices',
          ),
        ),
        const SizedBox(height: 12),
        _DeviceDropdown(
          label: 'Camera',
          icon: Icons.videocam_rounded,
          devices: videoDevices,
          selectedDevice: selectedVideoDevice,
          onChanged: onVideoDeviceChanged,
        ),
        const SizedBox(height: 8),
        _DeviceDropdown(
          label: 'Microphone',
          icon: Icons.mic_rounded,
          devices: audioDevices,
          selectedDevice: selectedAudioDevice,
          onChanged: onAudioDeviceChanged,
        ),

        const SizedBox(height: 24),

        // Mode Section
        const _SectionHeader(title: 'Mode', icon: Icons.camera_rounded),
        const SizedBox(height: 12),
        _ModeSelector(
          selectedMode: cameraMode,
          onChanged: onCameraModeChanged,
        ),
        if (cameraMode == CameraMacOSMode.video) ...[
          const SizedBox(height: 12),
          _SettingTextField(
            label: 'Duration (seconds)',
            controller: durationController,
          ),
        ],

        const SizedBox(height: 24),

        // Quality Section
        const _SectionHeader(
            title: 'Quality', icon: Icons.high_quality_rounded),
        const SizedBox(height: 12),
        _SettingDropdown<PictureResolution>(
          label: 'Resolution',
          value: resolution,
          items: PictureResolution.values,
          labelBuilder: (v) => v.name.toUpperCase(),
          onChanged: onResolutionChanged,
        ),
        _SettingDropdown<VideoFormat>(
          label: 'Video Format',
          value: videoFormat,
          items: VideoFormat.values,
          labelBuilder: (v) => v.name.toUpperCase(),
          onChanged: onVideoFormatChanged,
        ),
        _SettingDropdown<AudioQuality>(
          label: 'Audio Quality',
          value: audioQuality,
          items: AudioQuality.values,
          labelBuilder: (v) => v.name.toUpperCase(),
          onChanged: onAudioQualityChanged,
        ),

        const SizedBox(height: 24),

        // Options Section
        const _SectionHeader(title: 'Options', icon: Icons.tune_rounded),
        const SizedBox(height: 12),
        _SettingSwitch(
          label: 'Mirror Video',
          icon: Icons.flip_rounded,
          value: isVideoMirrored,
          onChanged: onIsVideoMirroredChanged,
        ),
        _SettingSwitch(
          label: 'Enable Audio',
          icon: Icons.volume_up_rounded,
          value: enableAudio,
          onChanged: onEnableAudioChanged,
        ),
        _SettingSwitch(
          label: 'Torch',
          icon: Icons.flashlight_on_rounded,
          value: enableTorch,
          onChanged: onEnableTorchChanged,
        ),
        _SettingSwitch(
          label: 'Stream Preview',
          icon: Icons.stream_rounded,
          value: streamImage,
          onChanged: onStreamImageChanged,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    required this.label,
    required this.icon,
    required this.devices,
    required this.selectedDevice,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<CameraMacOSDevice> devices;
  final String? selectedDevice;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _AppColors.surfaceLighter,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedDevice,
                hint: Text(label,
                    style: const TextStyle(color: _AppColors.textMuted)),
                dropdownColor: _AppColors.surfaceLighter,
                style: const TextStyle(color: _AppColors.text, fontSize: 13),
                items: devices.map((device) {
                  return DropdownMenuItem(
                    value: device.deviceId,
                    child: Text(
                      device.deviceId,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final CameraMacOSMode selectedMode;
  final ValueChanged<CameraMacOSMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _AppColors.surfaceLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.photo_camera_rounded,
              label: 'Photo',
              isSelected: selectedMode == CameraMacOSMode.photo,
              onTap: () => onChanged(CameraMacOSMode.photo),
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: Icons.videocam_rounded,
              label: 'Video',
              isSelected: selectedMode == CameraMacOSMode.video,
              onTap: () => onChanged(CameraMacOSMode.video),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingDropdown<T extends Enum> extends StatelessWidget {
  const _SettingDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: _AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  isExpanded: true,
                  value: value,
                  dropdownColor: _AppColors.surfaceLighter,
                  style: const TextStyle(color: _AppColors.text, fontSize: 13),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(labelBuilder(item)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: _AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _AppColors.text, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _AppColors.primary,
            activeTrackColor: _AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: _AppColors.textMuted,
            inactiveTrackColor: _AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _SettingTextField extends StatelessWidget {
  const _SettingTextField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _AppColors.text, fontSize: 14),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _AppColors.textMuted),
        filled: true,
        fillColor: _AppColors.surfaceLighter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

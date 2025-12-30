import 'extensions.dart';

class CameraMacOSDevice {
  CameraMacOSDevice({
    required this.deviceId,
    this.manufacturer,
    this.deviceType = CameraMacOSDeviceType.unknown,
    this.localizedName,
  });

  factory CameraMacOSDevice.fromMap(Map<String, dynamic> map) {
    return CameraMacOSDevice(
      deviceId: map['deviceId'] ?? '',
      manufacturer: map['manufacturer'],
      localizedName: map['localizedName'],
      deviceType: CameraMacOSDeviceType.values.safeElementAt(
              map['deviceType'] ?? CameraMacOSDeviceType.unknown.index) ??
          CameraMacOSDeviceType.unknown,
    );
  }
  String deviceId;
  String? manufacturer;
  CameraMacOSDeviceType deviceType;
  String? localizedName;
}

enum CameraMacOSDeviceType {
  video,
  audio,
  unknown,
}

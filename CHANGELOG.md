# Changelog

## 0.0.4
- `CameraMacOSRawView` now automatically reads `textureId` from the platform channel if not provided
- Added static getters `CameraMacOSRawView.currentTextureId` and `CameraMacOSRawView.currentCameraSize` for direct access
- `textureId` parameter is now optional - widget gracefully handles missing texture by showing empty widget

## 0.0.3
- Fixed type mismatch error in `destroy()` method that caused crashes in integration tests
- The method now consistently returns a dictionary format for both success and error cases

## 0.0.2
- Rename `CameraMacosRawView` to `CameraMacOSRawView`

## 0.0.1
- Fixed various issues
- Improved stability and performance

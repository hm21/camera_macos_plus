//
//  AVCaptureDevice+Extension.swift
//  camera_macos
//
//  Created by riccardo on 04/11/22.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    
    @available(macOS 10.15, *)
    public class func captureDevice(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: .unspecified).devices
        return devices.first
    }
    
    @available(macOS 10.15, *)
    public class func captureDevices(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType? = nil) -> [AVCaptureDevice] {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: .unspecified).devices
        return devices
    }
    
    public class func captureDevice(mediaType: AVMediaType) -> AVCaptureDevice? {
        if #available(macOS 10.15, *) {
            let deviceTypes: [AVCaptureDevice.DeviceType]
            if mediaType == .audio {
                if #available(macOS 14.0, *) {
                    deviceTypes = [.microphone, .external]
                } else {
                    deviceTypes = [.builtInMicrophone, .externalUnknown]
                }
            } else {
                if #available(macOS 14.0, *) {
                    deviceTypes = [.builtInWideAngleCamera, .external]
                } else {
                    deviceTypes = [.builtInWideAngleCamera, .externalUnknown]
                }
            }
            return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: .unspecified).devices.first
        } else {
            return AVCaptureDevice.default(for: mediaType)
        }
    }
    
    public class func captureDevices(mediaType: AVMediaType? = nil) -> [AVCaptureDevice] {
        if #available(macOS 10.15, *) {
            let deviceTypes: [AVCaptureDevice.DeviceType]
            if mediaType == .audio {
                if #available(macOS 14.0, *) {
                    deviceTypes = [.microphone, .external]
                } else {
                    deviceTypes = [.builtInMicrophone, .externalUnknown]
                }
            } else {
                if #available(macOS 14.0, *) {
                    deviceTypes = [.builtInWideAngleCamera, .external]
                } else {
                    deviceTypes = [.builtInWideAngleCamera, .externalUnknown]
                }
            }
            return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: .unspecified).devices
        } else {
            if let mediaType = mediaType {
                return AVCaptureDevice.devices(for: mediaType)
            } else {
                return AVCaptureDevice.devices()
            }
        }
    }
    
}

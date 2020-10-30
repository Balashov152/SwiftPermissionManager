//
//  PermissionManager.swift
//  Use and Go
//
//  Created by Sergey on 26.04.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

import AVFoundation
import Contacts
import Foundation
import Photos
import UserNotifications
import UIKit

public extension PermissionManager {
    typealias ResultModel = Result<PermissionType, PermissonError>
    
    enum PermissonError: Error {
        case notSupport, denied, unknownDefault, error(text: String?)
    }
}

public struct PermissionManager {
    public init() {}
    
    // MARK: Location
    /// if we need request localiton permission, that must be use in your localtion manager
    public func checkLocation(result: ((ResultModel) -> Void)) {
        guard CLLocationManager.locationServicesEnabled() else {
            result(ResultModel.failure(.notSupport))
            return
        }

        let status: CLAuthorizationStatus
        
        if #available(iOS 14, *) {
            status = CLLocationManager().authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined, .restricted, .denied:
            result(.failure(.denied))
            
        case .authorizedWhenInUse:
            result(.success(.whenInUseLocation))

        case .authorizedAlways:
            result(.success(.alwaysLocation))
        @unknown default:
            result(.failure(.denied))
        }
    }
    
    // MARK: Notifications
    public func checkNotificationPermission(requestOptions: UNAuthorizationOptions?, result: @escaping ((ResultModel) -> Void)) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined, .denied, .provisional:
                if let requestOptions = requestOptions {
                    self.requestNotificationPermission(options: requestOptions, result: result)
                } else {
                    result(.failure(.denied))
                }
                
            case .authorized:
                result(.success(.notification))
            case .ephemeral:
                result(.failure(.unknownDefault)) // TODO: add to notification type
            @unknown default:
                result(.failure(.unknownDefault))
            }
        }
    }
    
    public func requestNotificationPermission(options: UNAuthorizationOptions, result: @escaping ((ResultModel) -> Void)) {
        guard ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil else {
            result(.failure(.error(text: "Device is simulator. Simulator not supported notifications")))
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            guard granted, error == nil else {
                result(.failure(.error(text: error?.localizedDescription)))
                return
            }
            result(.success(.notification))
        }
    }
    
    
    // MARK: PhotoLibrary
    
    /// for user on iOS 14
    public enum PHPhotoLibraryRequest {
        case addOnly, readWrite
    }
    
    public func checkPhotoLibraryPermission(request options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
        let status: PHAuthorizationStatus
        
        if #available(iOS 14, *) {
            let level: PHAccessLevel
            switch options {
            case .addOnly:
                level = .addOnly
            case .readWrite:
                level = .readWrite
            case .none:
                level = .readWrite
            }
            status = PHPhotoLibrary.authorizationStatus(for: level)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        
        
        switch status {
        case .denied, .notDetermined, .restricted:
            if let options = options {
                requestPhotoLibraryPermission(options: options, result: result)
            } else {
                result(.failure(.denied))
            }
        case .authorized:
            result(.success(.photoLibrary))
        case .limited:
            result(.success(.photoLibraryLimited))
        @unknown default:
            result(.failure(.unknownDefault))
        }
    }
    
    public func requestPhotoLibraryPermission(options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .denied, .notDetermined, .restricted:
                result(.failure(.denied))
            case .authorized:
                result(.success(.photoLibrary))
            case .limited:
                result(.success(.photoLibraryLimited))
            @unknown default:
                result(.failure(.unknownDefault))
            }
        }
    }
    
    // MARK: Mic
    public func checkMicPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            result(.success(.mic))
        case .denied, .undetermined:
            if request {
                requestMicPermission(result: result)
            } else {
                result(.failure(.denied))
            }
        @unknown default:
            result(.failure(.unknownDefault))
        }
    }
    
    public func requestMicPermission(result: @escaping ((ResultModel) -> Void)) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            result(granted ? .success(.mic) : .failure(.denied))
        }
    }
    
    // MARK: Camera
    public func checkCameraPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            result(.success(.camera))
        case .denied, .notDetermined, .restricted:
            if request {
                requestMicPermission(result: result)
            } else {
                result(.failure(.denied))
            }
        @unknown default:
            result(.failure(.unknownDefault))
        }
    }
    
    public func requestCameraPermission(result: @escaping ((ResultModel) -> Void)) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            result(granted ? .success(.mic) : .failure(.denied))
        }
    }
    
    
    // MARK: Contacts
    
    public func checkContactsPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            result(.success(.contacts))
        case .denied, .notDetermined, .restricted:
            if request {
                requestMicPermission(result: result)
            } else {
                result(.failure(.denied))
            }
        @unknown default:
            result(.failure(.unknownDefault))
        }
    }
    
    public func requestContactsPermission(result: @escaping ((ResultModel) -> Void)) {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            guard granted, error == nil else {
                result(.failure(.error(text: error?.localizedDescription)))
                return
            }
            result(.success(.contacts))
        }
    }
    
    public func openSettings(type: PermissionType, localized: LocalizedAlert) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: localized.title,
                                                    message: localized.subtitle, preferredStyle: .alert)
            
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    alertController.addAction(UIAlertAction(title: localized.openSettings, style: .default, handler: { (_) -> Void in
                        UIApplication.shared.open(settingsUrl, completionHandler: { success in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }))
                }
            }
            
            var visibleVc = UIApplication.shared.delegate?.window??.rootViewController
            while let presentedVC = visibleVc?.presentedViewController {
                visibleVc = presentedVC
            }
            
            alertController.addAction(UIAlertAction(title: localized.cancel, style: .cancel, handler: nil))
            visibleVc?.present(alertController, animated: true, completion: nil)
        }
    }
}

public extension PermissionManager {
    struct LocalizedAlert {
        let title, subtitle, openSettings, cancel: String
        
        public init(title: String, subtitle: String,
             openSettings: String, cancel: String) {
            self.title = title
            self.subtitle = subtitle
            self.openSettings = openSettings
            self.cancel = cancel
        }
    }
    
    enum PermissionType {
        case notification, mic, camera, whenInUseLocation
        case alwaysLocation, photoLibrary, photoLibraryLimited, contacts
    }
}

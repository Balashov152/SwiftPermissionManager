//
//  PermissionManager.swift
//  Use and Go
//
//  Created by Sergey on 26.04.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

import Foundation
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
        PermissionManager.Location.check(result: result)
    }
    
    // MARK: Notifications
    public func checkNotificationPermission(requestOptions: UNAuthorizationOptions?, result: @escaping ((ResultModel) -> Void)) {
        PermissionManager.Notifications.checkPermission(requestOptions: requestOptions, result: result)
    }
    
    public func requestNotificationPermission(options: UNAuthorizationOptions, result: @escaping ((ResultModel) -> Void)) {
        PermissionManager.Notifications.requestPermission(options: options, result: result)
    }

    // MARK: PhotoLibrary
    
    /// for user on iOS 14
    public enum PHPhotoLibraryRequest {
        case addOnly, readWrite
    }
    
    public func checkPhotoLibraryPermission(request options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
        PhotoLibrary.checkPermission(request: options, result: result)
    }
    
    public func requestPhotoLibraryPermission(options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
        PhotoLibrary.requestPermission(options: options, result: result)
    }
    
    // MARK: Mic
    
    public func checkMicPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        Mic.checkPermission(request: request, result: result)
    }
    
    public func requestMicPermission(result: @escaping ((ResultModel) -> Void)) {
        Mic.requestPermission(result: result)
    }
    
    // MARK: Camera
    
    public func checkCameraPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        Camera.checkPermission(request: request, result: result)
    }
    
    public func requestCameraPermission(result: @escaping ((ResultModel) -> Void)) {
        Camera.requestPermission(result: result)
    }
    
    // MARK: Contacts
    
    public func checkContactsPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
        PermissionManager.Contacts.checkPermission(request: request, result: result)
    }
    
    public func requestContactsPermission(result: @escaping ((ResultModel) -> Void)) {
        PermissionManager.Contacts.requestPermission(result: result)
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

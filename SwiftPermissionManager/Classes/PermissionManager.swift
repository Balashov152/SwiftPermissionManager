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

public class PermissionManager {
    public init() {}
    
    public func checkPermissions(types: [PermissionType], deniedType: ((PermissionType) -> Void)? = nil, allAccess: (() -> Void)? = nil) {
        var accessTypes: [PermissionType] = []
        
        for type in types {
            checkPermission(type: type, createRequestIfNeed: false, denied: {
                deniedType?(type)
                return
            }) {
                accessTypes.append(type)
            }
        }
        
        if types == accessTypes {
            allAccess?()
        }
    }
    
    /**
     Check permission for define type.
     Parameter needRequest installed to true for TypePermission(.whenInUseLocation, .alwaysLocation) associated with location will not call access and denied closures.
     
     - parameter type: Define type for check permission.
     - parameter needRequest: if set to true, will be send request to dependence type. Default value is false.
     - parameter access: This closure will be called if access is available. If needRequest installed to true and authorization status is denied then will be call after the user responds on request.
     - parameter denied: This closure will be called if denied is available. If needRequest installed to true and authorization status is denied then will be call after the user responds on request.
     */
    public func checkPermission(type: PermissionType, createRequestIfNeed needRequest: Bool = false, denied: (() -> Void)? = nil, access: (() -> Void)? = nil) {
        switch type {
        case .whenInUseLocation, .alwaysLocation:
            if CLLocationManager.locationServicesEnabled() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    assert(!needRequest, "request localiton permission must be use in localtion manager")
                    denied?()
                    
                case .authorizedWhenInUse:
                    if type == .whenInUseLocation {
                        access?()
                    }
                    
                case .authorizedAlways:
                    access?()
                @unknown default:
                    denied?()
                }
                
            } else {
                print("Location services are not enabled")
            }
            
        case .notification:
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    switch settings.authorizationStatus {
                    case .notDetermined, .denied, .provisional:
                        if needRequest {
                            self.requestPermission(type: type, completion: { granted in
                                if granted {
                                    access?()
                                } else {
                                    denied?()
                                }
                            })
                        } else {
                            denied?()
                        }
                        
                    case .authorized:
                        access?()
                    case .ephemeral:
                        denied?()
                    @unknown default:
                        denied?()
                        
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
        case .photoLibrary:
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                access?()
            case .denied, .notDetermined, .restricted:
                if needRequest {
                    requestPermission(type: type, completion: { granted in
                        if granted {
                            access?()
                        } else {
                            denied?()
                        }
                    })
                } else {
                    denied?()
                }
            case .limited:
                denied?()
            @unknown default:
                denied?()
            }
            
        case .mic:
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                access?()
            case .denied, .undetermined:
                if needRequest {
                    requestPermission(type: type, completion: { granted in
                        if granted {
                            access?()
                        } else {
                            denied?()
                        }
                    })
                } else {
                    denied?()
                }
            @unknown default:
                denied?()
            }
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                access?()
            case .denied, .notDetermined, .restricted:
                if needRequest {
                    requestPermission(type: type, completion: { granted in
                        if granted {
                            access?()
                        } else {
                            denied?()
                        }
                    })
                } else {
                    denied?()
                }
            @unknown default:
                denied?()
            }
            
        case .contacts:
            switch CNContactStore.authorizationStatus(for: .contacts) {
            case .authorized:
                access?()
            case .denied, .notDetermined, .restricted:
                if needRequest {
                    requestPermission(type: type, completion: { granted in
                        if granted {
                            access?()
                        } else {
                            denied?()
                        }
                    })
                } else {
                    denied?()
                }
            @unknown default:
                denied?()
            }
        }
    }
    
    public func requestPermission(type: PermissionType, completion: @escaping (Bool) -> Void, error: ((String) -> Void)? = nil) {
        switch type {
        case .photoLibrary:
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    completion(true)
                case .denied, .notDetermined, .restricted:
                    completion(false)
                case .limited:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
            
        case .notification:
            if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
                error?("Device is simulator. Simulator not supported notifications")
                return
            } else {
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, err in
                    guard error == nil else {
                        error?(err!.localizedDescription)
                        return
                    }
                    completion(granted)
                }
            }
        case .mic:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .whenInUseLocation:
        break // LocationManager.shared.requestWhenInUseAuthorization()
        case .alwaysLocation:
            break
        //            LocationManager.shared.requestAlwaysAuthorization()
        case .contacts:
            CNContactStore().requestAccess(for: .contacts) { granted, err in
                guard error == nil else {
                    error?(err!.localizedDescription)
                    return
                }
                completion(granted)
            }
        }
    }
    public typealias LocalizedAlert = (title: String, subtitle: String, openSettings: String, cancel: String)
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

extension PermissionManager {
    public enum PermissionType {
        case notification, mic, camera, whenInUseLocation, alwaysLocation, photoLibrary, contacts
    }
}

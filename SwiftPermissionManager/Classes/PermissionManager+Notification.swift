//
//  PermissionManager+Notification.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import UserNotifications

extension PermissionManager {
    public struct Notifications {
        public static func checkPermission(requestOptions: UNAuthorizationOptions?, result: @escaping ((ResultModel) -> Void)) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .notDetermined, .denied, .provisional:
                    if let requestOptions = requestOptions {
                        requestPermission(options: requestOptions, result: result)
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
        
        public static func requestPermission(options: UNAuthorizationOptions, result: @escaping ((ResultModel) -> Void)) {
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
    }
}

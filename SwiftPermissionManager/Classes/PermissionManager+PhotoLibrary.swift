//
//  PermissionManager+PhotoLibrary.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import Photos

extension PermissionManager {
    public struct PhotoLibrary {
        public static func checkPermission(request options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
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
                    requestPermission(options: options, result: result)
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
        
        public static func requestPermission(options: PHPhotoLibraryRequest?, result: @escaping ((ResultModel) -> Void)) {
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
    }
}

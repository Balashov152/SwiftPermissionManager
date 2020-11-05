//
//  PermissionManager+Camera.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import AVFoundation

extension PermissionManager {
    public struct Camera {
        public static func checkPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                result(.success(.camera))
            case .denied, .notDetermined, .restricted:
                if request {
                    requestPermission(result: result)
                } else {
                    result(.failure(.denied))
                }
            @unknown default:
                result(.failure(.unknownDefault))
            }
        }
        
        public static func requestPermission(result: @escaping ((ResultModel) -> Void)) {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                result(granted ? .success(.camera) : .failure(.denied))
            }
        }
    }
}

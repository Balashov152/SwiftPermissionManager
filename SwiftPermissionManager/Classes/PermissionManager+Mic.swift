//
//  PermissionManager+Mic.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import AVFoundation

extension PermissionManager {
    public struct Mic {
        public static func checkPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                result(.success(.mic))
            case .denied, .undetermined:
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
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                result(granted ? .success(.mic) : .failure(.denied))
            }
        }
    }
}

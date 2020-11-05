//
//  PermissionManager+Location.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import CoreLocation

extension PermissionManager {
    public struct Location {
        public static func check(result: ((ResultModel) -> Void)) {
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
    }
}

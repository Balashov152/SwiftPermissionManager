//
//  PermissionManager+Contacts.swift
//  SwiftPermissionManager
//
//  Created by Sergey Balashov on 05.11.2020.
//

import Foundation
import Contacts

extension PermissionManager {
    public struct Contacts {
        public static func checkPermission(request: Bool, result: @escaping ((ResultModel) -> Void)) {
            switch CNContactStore.authorizationStatus(for: .contacts) {
            case .authorized:
                result(.success(.contacts))
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
            CNContactStore().requestAccess(for: .contacts) { granted, error in
                guard granted, error == nil else {
                    result(.failure(.error(text: error?.localizedDescription)))
                    return
                }
                result(.success(.contacts))
            }
        }
    }
}

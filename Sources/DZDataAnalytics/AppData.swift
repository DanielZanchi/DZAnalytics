//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 20/07/21.
//

import Foundation
import SwiftKeychainWrapper

extension DZDataAnalytics {
    
    class AppData {
        
        enum Keys: String {
            case userDefaultsID, isPremium, appVersion, keychainID, sessionCount, originalTransId
        }
        
        static let shared: AppData = AppData()
        
        var defaults: UserDefaults!
        var keychain: KeychainWrapper!
        
        private init() {
            self.defaults = UserDefaults(suiteName: "\(Bundle.main.bundleIdentifier ?? "").DZAnalytics")
            self.keychain = KeychainWrapper(serviceName: "\(Bundle.main.bundleIdentifier ?? "").DZAnalytics")
        }
        
        func saveData() {
            defaults.set(DZDataAnalytics.AnalyticsVars.userDefaultsID, forKey: Keys.userDefaultsID.rawValue)
            
            keychain.set(DZAnalytics.isPremium, forKey: Keys.isPremium.rawValue)
            keychain.set(DZDataAnalytics.AnalyticsVars.keychainID, forKey: Keys.keychainID.rawValue)
            keychain.set(DZDataAnalytics.AnalyticsVars.sessionCount, forKey: Keys.sessionCount.rawValue)
            keychain.set(DZDataAnalytics.AnalyticsVars.originalTransId, forKey: Keys.originalTransId.rawValue)
        }
        
        func getData() {
            if let sessionCount = keychain.integer(forKey: Keys.sessionCount.rawValue) {
                DZDataAnalytics.AnalyticsVars.sessionCount = sessionCount
            }
            
            if let originalTransId = keychain.string(forKey: Keys.originalTransId.rawValue) {
                DZDataAnalytics.AnalyticsVars.originalTransId = originalTransId
            }
        }
    }
    
}

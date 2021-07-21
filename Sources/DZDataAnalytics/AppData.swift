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
            case userDefaultsID, isPremium, appVersion, keychainID, sessionCount
        }
        
        static let shared: AppData = AppData()
        
        var defaults: UserDefaults!
        var keychain: KeychainWrapper!
        
        private init() {
            self.defaults = UserDefaults(suiteName: "DZAnalytics")
            self.keychain = KeychainWrapper(serviceName: "DZAnalytics")
        }
        
        func saveData() {
            defaults.set(AnalyticsManager.AnalyticsVars.userDefaultsID, forKey: Keys.userDefaultsID.rawValue)
            
            keychain.set(AnalyticsManager.shared.isPremium, forKey: Keys.isPremium.rawValue)
            keychain.set(AnalyticsManager.AnalyticsVars.keychainID, forKey: Keys.keychainID.rawValue)
            keychain.set(AnalyticsManager.AnalyticsVars.sessionCount, forKey: Keys.sessionCount.rawValue)
        }
        
        func getData() {
            if let sessionCount = keychain.integer(forKey: Keys.sessionCount.rawValue) {
                AnalyticsManager.AnalyticsVars.sessionCount = sessionCount
            }
        }
    }
    
}

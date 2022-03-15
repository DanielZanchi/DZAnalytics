//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 11/02/22.
//

import Foundation

extension DZDataAnalytics {
    public class DataProvider {
        
        public static let current = DataProvider()
        
        private var paywallName: String?
        private var isTesting: Bool?
        private var trigger: String?
        
        private init() {
            
        }
        
        public func set(paywallName: String, trigger: String, isTesting: Bool = false) {
            self.paywallName = paywallName
            self.trigger = trigger
            self.isTesting = isTesting
        }
        
        public func get() -> (paywallName: String, trigger: String, isTesting: Bool)? {
            guard let paywallName = paywallName, let trigger = trigger, let isTesting = self.isTesting else {
                return nil
            }
            
            return (paywallName: paywallName, trigger: trigger, isTesting: isTesting)
        }
        
        public func reset() {
            self.trigger = nil
            self.paywallName = nil
            self.isTesting = nil
        }
        
    }
}

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
        private var flowType: String?
        private var limitType: String?
        
        private init() {
            
        }
        
        public func set(paywallName: String, trigger: String, isTesting: Bool? = nil, flowType: String? = nil, limitType: String? = nil) {
            self.paywallName = paywallName
            self.trigger = trigger
            self.isTesting = isTesting
            self.flowType = flowType
        }
        
        public func get() -> (paywallName: String?, trigger: String?, isTesting: Bool?, flowType: String?, limitType: String?) {
            return (paywallName: paywallName, trigger: trigger, isTesting: isTesting, flowType: self.flowType, limitType: self.limitType)
        }
        
        public func reset() {
            self.trigger = nil
            self.paywallName = nil
            self.isTesting = nil
            self.flowType = nil
            self.limitType = nil
        }
        
    }
}

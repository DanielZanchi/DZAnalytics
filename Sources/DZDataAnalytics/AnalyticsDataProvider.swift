//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 11/02/22.
//

import Foundation

public class AnalyticsDataProvider {
    
    public static let current = AnalyticsDataProvider()
    
    private var paywallName: String?
    private var trigger: String?
    
    private init() {
        
    }
    
    public func set(paywallName: String, trigger: String) {
        self.paywallName = paywallName
        self.trigger = trigger
    }
    
    public func get() -> (paywallName: String, trigger: String)? {
        guard let paywallName = paywallName, let trigger = trigger else {
            return nil
        }
        
        return (paywallName: paywallName, trigger: trigger)
    }
    
    public func reset() {
        self.trigger = nil
        self.paywallName = nil
    }
    
}

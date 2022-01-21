//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/01/22.
//

import Foundation

extension DZDataAnalytics {
    
    public func setTestPaywall(withName name: String) {
        sendEvent(withName: "ce_begin_paywall_test", parameters: [
            "cp_paywall_name": name
        ])
    }
    
    public func didSeePaywall(withName name: String, isTesting: Bool) {
        sendEvent(withName: "ce_paywall_view", parameters: [
            "cp_paywall_name": name,
            "cp_is_testing": isTesting
        ])
    }

}

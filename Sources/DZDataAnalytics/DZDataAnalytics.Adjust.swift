//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 28/11/22.
//

import Adjust
import AppTrackingTransparency
import FacebookCore

class AdjustManager: NSObject {
    
    var didSetupAdjust = false
    static let shared = AdjustManager()
    
    public func configureAdjust(appToken: String) {
        var env = ADJEnvironmentProduction
        #if DEBUG
        env = ADJEnvironmentSandbox
        #endif
        let adjConfig = ADJConfig(appToken: appToken, environment: env)
        let keychainID = DZAnalytics.getKeychainID()
        adjConfig?.externalDeviceId = keychainID
        adjConfig?.delegate = self
        adjConfig?.sendInBackground = true
        adjConfig?.needsCost = true
        adjConfig?.externalDeviceId = keychainID
        adjConfig?.logLevel = ADJLogLevelVerbose
        
        Adjust.appDidLaunch(adjConfig)
        Adjust.addSessionCallbackParameter("keychain_id", value: keychainID)
        
        didSetupAdjust = true
    }
    
    func checkForNewAttStatus() {
        if didSetupAdjust {
            Adjust.checkForNewAttStatus()
            if #available(iOS 14, *) {
                Settings.shared.isAdvertiserTrackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
            }
        }
    }
    
}

extension AdjustManager: AdjustDelegate {
    func adjustConversionValueUpdated(_ fineValue: NSNumber?, coarseValue: String?, lockWindow: NSNumber?) {
        DZAnalytics.sendEvent(withName: "ce_cv_updated", parameters: [
            "cp_fine_value": fineValue,
            "cp_coarse_value": coarseValue,
            "cp_lock_window": lockWindow
        ])
    }
}

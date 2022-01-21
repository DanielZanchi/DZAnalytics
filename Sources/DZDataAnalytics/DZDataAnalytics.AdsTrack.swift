//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 28/09/21.
//

import AppTrackingTransparency
import iAd
import Foundation
import FirebaseAnalytics

extension DZDataAnalytics {
    
    /// if calling this you should add this to info.plist: "NSUserTrackingUsageDescription" : "Use you device information for performance statistics to improve product stability"
    public func requestiAdAttribution() {
        
        func getAttribution() {
            ADClient.shared().requestAttributionDetails({ (attributionDetails, error) in
                if let error = error {
                    print("There was an error while requesting attribution details: \(error.localizedDescription)")
                }
                
                if let attributionDetails = attributionDetails {
                    for (_, adDictionary) in attributionDetails {
                        if var adDictionary = adDictionary as? [String: Any] {
                            adDictionary = adDictionary.normalizeKeys()
                            
                            Analytics.setDefaultEventParameters(nil)
                            Analytics.setDefaultEventParameters([
                                parametersKeys.cp_keychainID.rawValue: AnalyticsVars.keychainID,
                            ])
                            
                            
                            self.sendEvent(withName: eventNameKeys.ce_search_event_tracking.rawValue, parameters: adDictionary)
                            self.setDefaultParams()
                        }
                    }
                }
            })
        }
        
        guard didRequestAdAttribution() == false else { return }
        
        AppData.shared.defaults.set(true, forKey: AppData.Keys.didRequestAdAttribution.rawValue)
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    getAttribution()
                    
                    self.sendEvent(withName: eventNameKeys.ce_tracking_change_status.rawValue, parameters: [
                        parametersKeys.cp_tracking_status.rawValue: "authorized"
                    ])
                case .denied:
                    print("Denied")
                    self.sendEvent(withName: eventNameKeys.ce_tracking_change_status.rawValue, parameters: [
                        parametersKeys.cp_tracking_status.rawValue: "denied"
                    ])
                case .notDetermined:
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                    self.sendEvent(withName: eventNameKeys.ce_tracking_change_status.rawValue, parameters: [
                        parametersKeys.cp_tracking_status.rawValue: "restricted"
                    ])
                @unknown default:
                    print("Unknown")
                }
            }
        } else {
            getAttribution()
        }
    }
    
    
    
    private func didRequestAdAttribution() -> Bool {
        return AppData.shared.defaults.bool(forKey: AppData.Keys.didRequestAdAttribution.rawValue)
    }
}

extension Dictionary {
    func normalizeKeys() -> [String: Any] {
        var output = [String: Any]()
        
        for row in self {
            if var newKey = row.key as? String {
                newKey = newKey.replacingOccurrences(of: "-", with: "_")
                output[newKey] = row.value
            }
        }
        
        return output
    }
}

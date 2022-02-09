//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 28/09/21.
//

import AppTrackingTransparency
import iAd
import AdServices
import Foundation
import FirebaseAnalytics

extension DZDataAnalytics {
    
    //This doesn't need the tracking auth from the user. If the user didn't give consent it will send a standard payload.s
    func sendSearchAdsAttribution(afterTrackingAuthorization: Bool = false) {
        if #available(iOS 14.3, *) {
            do {
                let attributionToken = try AAAttribution.attributionToken()
                var request = URLRequest(url: URL(string: "https://api-adservices.apple.com/api/v1/")!)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = Data(attributionToken.utf8)
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DZAnalytics.sendEvent(withName: "ce_seatch_ad_error", parameters: ["error": error.localizedDescription])
                        print("there was an error with AAAttribution - \(error.localizedDescription)")
                        return
                    }
                    if let data = data,
                       let attribution = try? JSONDecoder().decode(AAAttributionModel.self, from: data) {
                        DZAnalytics.sendEvent(withName: afterTrackingAuthorization ? "ce_search_ad_attr_ap" : "ce_search_ad_attr_bp", parameters: [
                            "cp_a_attribution": attribution.attribution ?? false,
                            "cp_a_campaign_id": attribution.campaignID ?? 0,
                            "cp_a_click_date": attribution.clickDate ?? "",
                            "cp_a_ad_group_id": attribution.adGroupID ?? 0,
                            "cp_a_country_region": attribution.countryOrRegion ?? "",
                            "cp_a_keyword_id": attribution.keywordID ?? -1,
                            "cp_a_ad_id": attribution.adID ?? 0
                        ])
                    }
                }.resume()
                
            } catch {
                DZAnalytics.sendEvent(withName: "ce_seatch_ad_error", parameters: ["error": error.localizedDescription])
                print("There was an errore getting the attribution token: \(error.localizedDescription)")
            }
        }
    }
    
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
                    self.sendSearchAdsAttribution(afterTrackingAuthorization: true)
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

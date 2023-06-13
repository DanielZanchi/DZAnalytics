//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 28/09/21.
//

import UIKit
import AppTrackingTransparency
import iAd
import AdServices
import Foundation
import FirebaseAnalytics
import Firebase
import Adjust
import FacebookLogin

extension String {
    
    static public func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
}

extension DZDataAnalytics {
    
    //This doesn't need the tracking auth from the user. If the user didn't give consent it will send a standard payload.s
    func sendSearchAdsAttribution(afterTrackingAuthorization: Bool = false) {
		#if DEBUG
		print("Not sending search ads attribution in DEBUG mode")
		return;
		#endif
		
        DZAnalytics.sendEvent(withName: "ce_will_ask_ad_attribution", parameters: [
            "cp_ios_version": UIDevice.current.systemVersion
        ], removingDefault: false)
        
        if #available(iOS 14.3, *) {
            do {
                let attributionToken = try AAAttribution.attributionToken()
                var request = URLRequest(url: URL(string: "https://api-adservices.apple.com/api/v1/")!)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = Data(attributionToken.utf8)
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DZAnalytics.sendEvent(withName: "ce_search_ad_error", parameters: ["cp_error": error.localizedDescription])
                        print("there was an error with AAAttribution - \(error.localizedDescription)")
                        return
                    }
                    if let data = data {
                        var code: Int = -1
                        if let httpReponse = response as? HTTPURLResponse {
                            code = httpReponse.statusCode
                            if code != 200 {
                                DZAnalytics.sendEvent(withName: "ce_search_ads_response", parameters: ["cp_code": code])
                            }
                            if code == 404 && self.adsAttrAttempts < 5 {
                                self.adsAttrAttempts += 1
                                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                                    self.sendSearchAdsAttribution()
                                }
                            }
                        }
                        
                        do {
                            let attribution = try JSONDecoder().decode(AAAttributionModel.self, from: data)
                            let parameters: [String: Any] = [
                                "cp_a_attribution": attribution.attribution ?? false,
                                "cp_a_campaign_id": attribution.campaignID ?? -1,
                                "cp_a_click_date": attribution.clickDate ?? "",
                                "cp_a_ad_group_id": attribution.adGroupID ?? -1,
                                "cp_a_country_region": attribution.countryOrRegion ?? "UNDEFINED",
                                "cp_a_keyword_id": attribution.keywordID ?? -1,
                                "cp_a_ad_id": attribution.adID ?? -1
                            ]
                            DZAnalytics.sendEvent(withName: afterTrackingAuthorization ? "ce_search_ad_attr_ap" : "ce_search_ad_attr_bp", parameters: parameters)
                        } catch {
                            print("error: \(error.localizedDescription)")
                            DZAnalytics.sendEvent(withName: "ce_search_ad_error", parameters: [
                                "cp_error": "data not decodable",
                                "cp_decode_error": true,
                                "cp_decode_catch_error": error.localizedDescription
                            ], removingDefault: false)
                        }
                    } else {
                        DZAnalytics.sendEvent(withName: "ce_search_ad_error", parameters: [
                            "cp_error": "no data downloaded",
                            "cp_decode_error": false
                        ], removingDefault: false)
                    }
                }.resume()
                
            } catch {
                DZAnalytics.sendEvent(withName: "ce_search_ad_error", parameters: ["cp_error": error.localizedDescription])
                print("There was an errore getting the attribution token: \(error.localizedDescription)")
            }
        } else {
            DZAnalytics.sendEvent(withName: "ce_search_ad_error", parameters: ["cp_error": "old ios version: \(UIDevice.current.systemVersion)"])
        }
    }
    
    private func sendToServer(parameters: [String: Any], afterTracking: Bool) {
        var parameters = parameters
        parameters["cp_keychainID"] = getKeychainID()
        parameters["cp_after_tracking_popup"] = afterTracking
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        guard let baseURL = serverURL, let url = URL(string: "\(baseURL)/receiveSearchAdsAttr") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DZAnalytics.sendEvent(withName: "ce_search_ad_error_to_server", parameters: [
                    "cp_error": error.localizedDescription,
                ], removingDefault: false)
                print("There was an error sending ads attr to own server: ", error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print ("httpResponse.statusCode: \(httpResponse.statusCode)")
                DZAnalytics.sendEvent(withName: "ce_search_ad_to_server", parameters: [
                    "cp_status": httpResponse.statusCode,
                ], removingDefault: false)
            }
        }

        task.resume()
    }
    
	@available(iOS 13.0.0, *)
	public func requestiAdAttribution() async {
		return await withCheckedContinuation({ continuation in
			requestiAdAttribution {
				continuation.resume(returning: ())
			}
		})
	}
	
    /// if calling this you should add this to info.plist: "NSUserTrackingUsageDescription" : "Use you device information for performance statistics to improve product stability"
    public func requestiAdAttribution(completion: (() -> Void)? = nil) {
        func getAttribution() {
            ADClient.shared().requestAttributionDetails({ (attributionDetails, error) in
                if let error = error {
                    DZAnalytics.sendEvent(withName: "ce_search_ad_attr_error", parameters: ["cp_error": error.localizedDescription])
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
                } else {
                    DZAnalytics.sendEvent(withName: "ce_search_ad_attr_error", parameters: ["cp_error": "attribution details not valid"])
                }
            })
        }
        
        
        if #available(iOS 14, *) {
            guard didRequestAdAttribution() == false else { completion?(); return }
            ATTrackingManager.requestTrackingAuthorization { status in
                AdjustManager.shared.checkForNewAttStatus()
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
                completion?()
            }
        } else {
            DZAnalytics.sendEvent(withName: "ce_search_ad_attr_error", parameters: ["cp_error": "old ios version: \(UIDevice.current.systemVersion)"])
            getAttribution()
            completion?()
        }
    }
    
    
    
    @available(iOS 14, *)
    private func didRequestAdAttribution() -> Bool {
        return !(ATTrackingManager.trackingAuthorizationStatus == .notDetermined)
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

//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/01/22.
//

import Foundation
import SwiftyStoreKit
import FirebaseAnalytics

extension DZDataAnalytics {
    
    public func sendEvent(withName name: String, parameters: [String: Any]? = nil, removingDefault: Bool = false) {
        DispatchQueue(label: "DZAnalytics.eventLogger").async {
            self.eventSemaphore.wait()
            print("******** event logged")
            if removingDefault {
                Analytics.setDefaultEventParameters(nil)
                Analytics.setDefaultEventParameters([
                    parametersKeys.cp_keychainID.rawValue: AnalyticsVars.keychainID,
                ])
            }
            
            Analytics.logEvent(name, parameters: parameters)
            
            if removingDefault {
                self.setDefaultParams()
            }
            
            DispatchQueue(label: "DZAnalytics.eventLogger").asyncAfter(deadline: .now() + 2) {
                self.eventSemaphore.signal()
            }
            
        }
    }
    
    @available(*, deprecated, message: "Use setTestSegmentation instead")
    public func setTestPaywall(withName name: String) {
        sendEvent(withName: "ce_begin_paywall_test", parameters: [
            "cp_paywall_name": name
        ])
    }
    
    public func setTestSegmnentation(paywallName: String?, surveyEnabled: Bool?) {
        var parameters: [String: Any] = [:]
        if let paywallName = paywallName {
            parameters["cp_experiment_paywall_name"] = paywallName
        }
        if let surveyEnabled = surveyEnabled {
            parameters["cp_experiment_onboarding_survey"] = surveyEnabled
            
        }
        
        sendEvent(withName: "ce_experiment_segmentation", parameters: parameters)
    }
    
    
    public func purchaseInitialized(productId: String) {
        DZAnalytics.sendEvent(withName: "ce_purchase_initialized", parameters: [
            "cp_paywall_name": AnalyticsDataProvider.current.get()?.paywallName ?? "",
            "cp_trigger": AnalyticsDataProvider.current.get()?.trigger ?? "",
            "cp_product_id": productId
        ])
    }
    
    public func didSeePaywall(withName name: String, isTesting: Bool, trigger: String) {
        sendEvent(withName: "ce_paywall_appear", parameters: [
            "cp_paywall_name": name,
            "cp_is_testing": isTesting,
            "cp_trigger": trigger
        ])
    }
    
    public func sendReceiptInfos(_ receipt: [String: AnyObject], localReceipt: Bool = false) {
        guard AnalyticsVars.didSendReceipt == false else { return }
        if let receiptInfo = receipt["receipt"] {
            if let originalPurchaseDate = receiptInfo["original_purchase_date"] as? String,
               let downloadId = receiptInfo["download_id"] as? Int,
               let originalAppVersion = receiptInfo["original_application_version"] as? String {
                sendEvent(withName: "ce_app_store_receipt", parameters: [
                    "cp_r_original_purchase_date": originalPurchaseDate,
                    "cp_r_download_id": downloadId,
                    "cp_r_original_application_version": originalAppVersion,
                    "cp_r_local_receipt": localReceipt
                ])
                
                AnalyticsVars.didSendReceipt = true
                DZDataAnalytics.AppData.shared.saveData()
            }
        }
    }
    
    public func getAndSendReceipt(withSharedKey sharedKey: String, env: AppleReceiptValidator.VerifyReceiptURLType = .production, forceRefresh: Bool = false) {
        guard AnalyticsVars.didSendReceipt == false else { return }
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { result in
            switch result {
            case .success(let receiptData):
                let validator = AppleReceiptValidator(service: env, sharedSecret: sharedKey)
                validator.validate(receiptData: receiptData) { result in
                    switch result {
                    case .success(let receipt):
                        self.sendReceiptInfos(receipt, localReceipt: !forceRefresh)
                    case .error(let error):
                        print("There was an error fetching the receipt: \(error.localizedDescription)")
                    }
                }
            case .error(let error):
                print("There was an error fetching the receipt: \(error.localizedDescription)")
            }
        }
    }
    
}

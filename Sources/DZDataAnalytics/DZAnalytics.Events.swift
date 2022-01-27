//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/01/22.
//

import Foundation
import SwiftyStoreKit

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
    
    public func sendReceiptInfos(_ receipt: [String: AnyObject]) {
        guard AnalyticsVars.didSendReceipt == false else { return }
        if let receiptInfo = receipt["receipt"] {
            if let originalPurchaseDate = receiptInfo["original_purchase_date"] as? String,
               let downloadId = receiptInfo["download_id"] as? Int,
               let originalAppVersion = receiptInfo["original_application_version"] as? String {
                sendEvent(withName: "ce_app_store_receipt", parameters: [
                    "cp_r_original_purchase_date": originalPurchaseDate,
                    "cp_r_download_id": downloadId,
                    "cp_r_original_application_version": originalAppVersion
                ])
                
                AnalyticsVars.didSendReceipt = true
                DZDataAnalytics.AppData.shared.saveData()
            }
        }
    }
    
    public func fetchAndSendReceipt(withSharedKey sharedKey: String, env: AppleReceiptValidator.VerifyReceiptURLType = .production) {
        guard AnalyticsVars.didSendReceipt == false else { return }
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let receiptData):
                let validator = AppleReceiptValidator(service: env, sharedSecret: sharedKey)
                validator.validate(receiptData: receiptData) { result in
                    switch result {
                    case .success(let receipt):
                        self.sendReceiptInfos(receipt)
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

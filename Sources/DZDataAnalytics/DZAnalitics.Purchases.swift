//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/01/22.
//

import Foundation
import StoreKit.SKProduct

extension DZDataAnalytics {
    
    public enum FlowType: String {
        case ce_purchase_initialized, ce_paywall_appear, ce_paywall_dismissed, ce_did_purchase
    }
    
    public func setPremium(_ value: Bool) {
        self.isPremium = value
        AppData.shared.saveData()
        setDefaultParams()
    }
    
    public func setOriginalTransId(_ id: String?) {
        guard let id = id else { return }
        AnalyticsVars.originalTransId = id
        AppData.shared.saveData()
        setDefaultParams()
    }
    
    public func didPurchase(product: SKProduct, addParameters: [String: Any]? = nil) {
        let currencyCode = product.priceLocale.currencyCode ?? ""
        let currencySymbol = product.priceLocale.currencySymbol ?? ""
        let localPrice = product.price.stringValue
        let price = product.localizedPrice ?? ""
        
        var parameters: [String: Any] =             [
            "cp_product_id": product.productIdentifier,
            "cp_currency_code": currencyCode,
            "cp_currency_symbol": currencySymbol,
            "cp_local_price": localPrice,
            "cp_price": price
        ]
        
        if let addParameters = addParameters {
            addParameters.forEach({parameters[$0.key] = $0.value})
        }
        
        purchaseFlowEvent(.ce_did_purchase, addedParameters: parameters)
    }
    
    public func didExpire(productId: String, expireDate: Date) {
        sendEvent(withName: eventNameKeys.ce_subscription_expired.rawValue, parameters:
                    [
                        parametersKeys.cp_product_id.rawValue: productId,
                        parametersKeys.cp_subscription_expire_date.rawValue: expireDate.getStringDate()
                    ])
    }
    
    public func purchaseFlowEvent(_ eventName: FlowType, addedParameters: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            "cp_paywall_name": DataProvider.current.get()?.paywallName ?? "",
            "cp_trigger": DataProvider.current.get()?.trigger ?? "",
            "cp_is_testing": DataProvider.current.get()?.isTesting ?? false,
        ]
        
        if let addedParameters = addedParameters {
            addedParameters.forEach({parameters[$0.key] = $0.value})
        }
        
        sendEvent(withName: eventName.rawValue, parameters: parameters)
    }
    
}

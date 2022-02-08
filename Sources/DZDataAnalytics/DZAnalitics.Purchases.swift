//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 21/01/22.
//

import Foundation
import StoreKit.SKProduct

extension DZDataAnalytics {
    
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
            addParameters.forEach({parameters[$0] = $1})
        }
        
        sendEvent(withName: "ce_did_purchase", parameters: parameters)
    }
    
    public func didExpire(productId: String, expireDate: Date) {
        sendEvent(withName: eventNameKeys.ce_subscription_expired.rawValue, parameters:
                    [
                        parametersKeys.cp_product_id.rawValue: productId,
                        parametersKeys.cp_subscription_expire_date.rawValue: expireDate.getStringDate()
                    ])
    }
    
}

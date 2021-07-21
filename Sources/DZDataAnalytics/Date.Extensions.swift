//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 20/07/21.
//

import Foundation

extension Date {
    /**
     Returns a string with the format "dd/MM/yyyy", or edit the format
     */
    func getStringDate(format: String = "yyyy-MM-dd HH:mm:ss Z", localeId: String = "it_IT") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: localeId)
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: self)
    }
}


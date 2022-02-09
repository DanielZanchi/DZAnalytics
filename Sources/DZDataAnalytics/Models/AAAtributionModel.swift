//
//  AAAtributionModel.swift
//  AnimatedSticker
//
//  Created by Daniel Zanchi on 09/02/22.
//  Copyright © 2022 Daniel Zanchi. All rights reserved.
//

import Foundation

// MARK: - AAAttributionModel
struct AAAttributionModel: Codable {
    let attribution: Bool?
    let orgID, campaignID: Int?
    let conversionType, clickDate: String?
    let adGroupID: Int?
    let countryOrRegion: String?
    let keywordID, adID: Int?

    enum CodingKeys: String, CodingKey {
        case attribution
        case orgID = "orgId"
        case campaignID = "campaignId"
        case conversionType, clickDate
        case adGroupID = "adGroupId"
        case countryOrRegion
        case keywordID = "keywordId"
        case adID = "adId"
    }
}


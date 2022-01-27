import FirebaseAnalytics
import SwiftKeychainWrapper
import Foundation
import StoreKit

public let DZAnalytics = DZDataAnalytics.shared

public class DZDataAnalytics {
    
    enum AnalyticsVars {
        static var sessionCount: Int = 0
        static var sessionId = UUID().uuidString
        static var keychainID: String = ""
        static var userDefaultsID: String = ""
        static var originalTransId: String = ""
        static var didSendReceipt = false
    }
    
    enum parametersKeys: String {
        case cp_session_id, cp_session_count, cp_preferred_language, cp_user_region, cp_isPremium, cp_countryId, cp_keychainID, cp_originalTransId, cp_app_version, cp_is_fresh_install, cp_old_app_version, cp_first_install_date, cp_subscription_expire_date, cp_installed_before_gca, cp_product_id, cp_tracking_status
    }
    
    enum eventNameKeys: String {
        case ce_first_open, ce_session_start, ce_app_update, ce_subscription_expired, ce_search_event_tracking, ce_tracking_change_status
    }
    
    public static let shared = DZDataAnalytics()
    var isPremium = false
    
    private init() {
        AppData.shared.getData()
    }
    
    public func sendEvent(withName name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    @discardableResult
    public func logFirstOpen() -> InstallState {
        AnalyticsVars.sessionCount += 1
        
        let installState = installState()
        
        switch installState {
        case .firstInstall:
            //I don't have a keychainID (so neither a userDefaultsID). I will create them
            AnalyticsVars.keychainID = UUID().uuidString
            AnalyticsVars.userDefaultsID = AnalyticsVars.keychainID
            AppData.shared.saveData()
            setDefaultParams()
            
            Analytics.logEvent(eventNameKeys.ce_first_open.rawValue, parameters: [
                parametersKeys.cp_is_fresh_install.rawValue: true,
                parametersKeys.cp_installed_before_gca.rawValue: false,
                parametersKeys.cp_first_install_date.rawValue: Date().getStringDate(format: "yyyy-MM-dd HH:mm:ss Z")
            ])
            
            Analytics.logEvent(eventNameKeys.ce_session_start.rawValue, parameters: nil)
        case .reinstall:
            //I am missing a userDefaultsID. I will sync it with the keychainID
            AnalyticsVars.userDefaultsID = AnalyticsVars.keychainID
            AppData.shared.saveData()
            setDefaultParams()
            
            Analytics.logEvent(eventNameKeys.ce_first_open.rawValue, parameters: [
                parametersKeys.cp_is_fresh_install.rawValue: false,
                parametersKeys.cp_installed_before_gca.rawValue: false
            ])
            Analytics.logEvent(eventNameKeys.ce_session_start.rawValue, parameters: nil)
            
        case .installed:
            AppData.shared.saveData()
            setDefaultParams()
            
            Analytics.logEvent(eventNameKeys.ce_session_start.rawValue, parameters: nil)
            
            if didUpdate() {
                let oldVersion = AppData.shared.keychain.string(forKey: AppData.Keys.appVersion.rawValue) ?? ""
                Analytics.logEvent(eventNameKeys.ce_app_update.rawValue, parameters: [
                    parametersKeys.cp_old_app_version.rawValue: oldVersion
                ])
            }
        }
        
        let currentAppVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        AppData.shared.keychain.set(currentAppVersion, forKey: AppData.Keys.appVersion.rawValue)
        
        return installState
    }
    
    func setDefaultParams() {
        Analytics.setUserID(AnalyticsVars.keychainID)
        Analytics.setDefaultEventParameters([
            parametersKeys.cp_session_id.rawValue: AnalyticsVars.sessionId,
            parametersKeys.cp_session_count.rawValue: AnalyticsVars.sessionCount,
            parametersKeys.cp_preferred_language.rawValue: Locale.preferredLanguages.first ?? "",
            parametersKeys.cp_user_region.rawValue: Locale.current.regionCode ?? "",
            parametersKeys.cp_isPremium.rawValue: isPremium,
            parametersKeys.cp_countryId.rawValue: Locale.current.regionCode ?? "",
            parametersKeys.cp_keychainID.rawValue: AnalyticsVars.keychainID,
            parametersKeys.cp_originalTransId.rawValue: AnalyticsVars.originalTransId,
            parametersKeys.cp_app_version.rawValue: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        ])
    }
    
    public func getKeychainID() -> String {
        return AnalyticsVars.keychainID
    }
}

extension DZDataAnalytics {
    
    public enum InstallState: String {
        case firstInstall, reinstall, installed
    }
    
    private func installState() -> InstallState {
        if isFirstInstall() {
            return .firstInstall
        }
        
        if isReinstall() {
            return .reinstall
        }
        
        return .installed
    }
    
    private func isFirstInstall() -> Bool {
        if let _ = DZDataAnalytics.AppData.shared.keychain.string(forKey: DZDataAnalytics.AppData.Keys.keychainID.rawValue) {
            return false
        }
        return true
    }
    
    private func isReinstall() -> Bool {
        if var keychainID = DZDataAnalytics.AppData.shared.keychain.string(forKey: DZDataAnalytics.AppData.Keys.keychainID.rawValue) {
            if keychainID == "" {
                keychainID = UUID().uuidString
            }
            if let _ = DZDataAnalytics.AppData.shared.defaults.string(forKey: DZDataAnalytics.AppData.Keys.userDefaultsID.rawValue) {
                AnalyticsVars.keychainID = keychainID
                return false
            }
            AnalyticsVars.keychainID = keychainID
            return true
        }
        return false
    }
    
    private func didUpdate() -> Bool {
        let currentAppVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        if let oldAppVersion = DZDataAnalytics.AppData.shared.keychain.string(forKey: DZDataAnalytics.AppData.Keys.appVersion.rawValue) {
            if oldAppVersion == currentAppVersion {
                return false
            } else {
                return true
            }
        } else {
            //The user didn't have the oldAppVersion in the keychain OR the app was updated
            return false
        }
    }
}

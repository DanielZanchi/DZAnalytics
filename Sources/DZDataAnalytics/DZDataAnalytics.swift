import FirebaseAnalytics
import SwiftKeychainWrapper
import Foundation

protocol AnalyticsManagerDelegate: NSObject {
    func setIsPremium(_ value: Bool)
}

struct DZDataAnalytics {
    
    struct AnalyticsManager {
        
        enum AnalyticsVars {
            static var sessionCount: Int = 0
            static var sessionId = UUID().uuidString
            static var keychainID: String = ""
            static var userDefaultsID: String = ""
            static var originalTransId: String = ""
        }
        
        enum parametersKeys: String {
            case cp_session_id, cp_session_count, cp_preferred_language, cp_user_region, cp_isPremium, cp_countryId, cp_keychainID, cp_originalTransId, cp_app_version, cp_is_fresh_install, cp_old_app_version, cp_first_install_date, cp_subscription_expire_date
        }
        
        enum eventNameKeys: String {
            case ce_first_open, ce_session_start, ce_app_update, ce_subscription_expired
        }

        static let shared = AnalyticsManager()
        weak var delegate: AnalyticsManagerDelegate?
        private(set) var isPremium = false
        
        private init() {
            AppData.shared.getData()
        }
        
        func sendEvent(withName name: String, parameters: [String: Any]? = nil) {
            Analytics.logEvent(name, parameters: parameters)
        }
        
        func logFirstOpen() {
            AnalyticsVars.sessionCount += 1
            
            switch installState() {
            case .firstInstall:
                //I don't have a keychainID (so neither a userDefaultsID). I will create them
                AnalyticsVars.keychainID = UUID().uuidString
                AnalyticsVars.userDefaultsID = AnalyticsVars.keychainID
                AppData.shared.saveData()
                setDefaultParams()
                
                Analytics.logEvent(eventNameKeys.ce_first_open.rawValue, parameters: [
                    parametersKeys.cp_is_fresh_install.rawValue: true,
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
        }
        
        private func setDefaultParams() {
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
    }
}

extension DZDataAnalytics.AnalyticsManager {
    
    enum InstallState {
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
        if let _ = DZDataAnalytics.AppData.shared.keychain.bool(forKey: DZDataAnalytics.AppData.Keys.keychainID.rawValue) {
            return false
        }
        return true
    }
    
    private func isReinstall() -> Bool {
        if let keychainID = DZDataAnalytics.AppData.shared.keychain.string(forKey: DZDataAnalytics.AppData.Keys.keychainID.rawValue) {
            if let _ = DZDataAnalytics.AppData.shared.defaults.string(forKey: DZDataAnalytics.AppData.Keys.userDefaultsID.rawValue) {
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

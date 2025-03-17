//
//  Constants.swift
//  WinkApp
//
//  Created by MacBook on 28/11/24.
//

import UIKit

//MARK: - StoryBoards Constants
enum StoryBoards {
    static let main = UIStoryboard(name: "Main", bundle: Bundle.main)
    static let popup = UIStoryboard(name: "PopUp", bundle: Bundle.main)
}

enum ServerType : String {
    case live = "live"
    case development = "dev"
    case testing = "testing"
}

struct FaceRect {
    static let width: CGFloat = 360
    static let height: CGFloat = 500
}

struct FaceDetect {
    static let miniDistance: CGFloat = 50
    static let maxDistance: CGFloat = 150
}

//MARK: - Font
struct AppFont {
    static let openSansBold = "OpenSans-Bold"
    static let openSansLight = "OpenSans-Light"
    static let openSansMedium = "OpenSans-Medium"
    static let openSansRegular = "OpenSans-Regular"
    static let openSansSemiBold = "OpenSans-SemiBold"
}

struct AppColor {
    static let purpleColor = rgbToUIColor(red: 114, green: 112, blue: 197)
    static let popupBGColor = rgbToUIColor(red: 232, green: 231, blue: 247)
}

struct WebURL {
    
    static var baseURL = "https://dev-api.winklogin.com"
    static var getSessionIdURL = "https://dev-api.winklogin.com/api/OpenSession/open-session-id?ClientId=winkwallet"
    static var enrollmentURL = "/api/Login/v1.0/videos"
    static var socketURL = "wss://dev-api.winklogin.com/ws_winkLoginEnrollment/SkLgTtMllh/true/true/winkwallet/?SessionId="
    static var getProfileURL = "/api/Login/v1.0/users"
    static var checkEmailURL = "/api/User/EmailVerification"
    static var checkContactURL = "/api/User/User/ContactNoCheck"
    
}
struct videoProcessingResult{
    
    static var existingAccount = "failure_existing_account"
    static var successLogin = "success_login"
    static var successEnrollment = "success_enrollment"
    static var notEnrolled = "failure_not_enrolled"
    static var poorQuality = "failure_poor_quality"
    static var failureTryAgain = "failure_try_again"
}

struct ClientDetails {
    
    static var clientId = "ces"
    static var devicToken = "99999"
    static var enrollmntDevicToken = "88888"
    static var clientSecret = "KX0rY0t45JsPgTSOkl3o"
}

struct Okta {
    
    static var redirectURL = "com.intelli.Ritesh.com.SwiftUIDemo://callback"
    static var clientId = "L9cmSMt5gmXdq0tjujkz9PI6XbSmidmu"
    static var clientSecret = "XRBKZAjkhHrPdDQBoidP1BMDelCS5S3OAt97V19QfEA4zTpr-eeK5QdMHfVhDBcp"
    static var audience = "https://dev-losjplaebuyov0c7.us.auth0.com/api/v2/"
    static var baseURL = "https://dev-losjplaebuyov0c7.us.auth0.com/"
}

struct IPQualityScore {
    
    static var USER_ID = "1234"
    static var userName = "IPQualityDude"
    static var apiKey = "I8VtDr8daoddxc30KwVewtcCNqvm4bJ3h5YyWAd40jT7t5R7uduO6etwl0muyaDm"
}

struct Azure {
    
    static let storageAccountName = "winkuserimages"
    static let containerName = "devusersimage"
    static let sasToken = "sp=rac&st=2024-04-29T20:12:40Z&se=2025-12-31T04:12:40Z&spr=https&sv=2022-11-02&sr=c&sig=2zJQG7Ki8GT1PGfFNaPHPsPi4PbP6XR8HfILDe6WJoI%3D"
}

struct VideoTypeFlag {
    
    static var login = "recognition"
    static var enrollment  = "enrollment"
}

// MARK: - RGB to UIColor
func rgbToUIColor(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(
        red: CGFloat(red) / 255.0,
        green: CGFloat(green) / 255.0,
        blue: CGFloat(blue) / 255.0,
        alpha: alpha
    )
}

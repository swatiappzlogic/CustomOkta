//
//  AppState.swift
//  WinkApp
//
//  Created by MacBook on 07/01/25.
//

import UIKit

class AppState {
    static let shared = AppState()
    
    var oktaOidc: OktaOidc? // This will hold the OktaOidc instance globally
    var authStateManager: OktaOidcStateManager?
    var userDetails:UserInfoResponse?

    private init() {} // Private initializer to ensure a singleton
    
    // Initialize OktaOidc with configuration
    func initializeOkta() {
        guard let config = try? OktaOidcConfig(fromPlist: "Okta") else {
            print("Failed to load Okta configuration from plist.")
            return
        }
        
        // Initialize OktaOidc with the configuration
        self.oktaOidc = try? OktaOidc(configuration: config)
    }
    
}

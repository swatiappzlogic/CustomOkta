//
//  LoginVM.swift
//  WinkApp
//
//  Created by MacBook on 31/12/24.
//

import UIKit
import Alamofire

class LoginVM: NSObject {
    
    // Function to authenticate the user
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let url = Okta.baseURL + "oauth/token"
        
        // Prepare the request body
        let body: [String: Any] = [
            "client_id": Okta.clientId,
            "client_secret": Okta.clientSecret,
            "audience": Okta.audience,
            "grant_type": "client_credentials",
            "scope": "create:users"
        ]
        // Headers if needed
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        NetworkManager.shared.post(url: url, parameters: body, headers: headers) { (result: Result<LoginResponse, NetworkError>) in
            switch result {
            case .success(let response):
                // Access token from the nested 'data' object
                let accessToken = response.data?.access_token
                
                UserDefaults.standard.set(accessToken ?? "", forKey: "access_token")
                
                completion(true)
                
            case .failure(let error):
                print("Authentication failed: \(error.localizedDescription)")
                completion(false)
            }
        }
        
    }
    
    private func handleUnauthorizedError() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
                window.rootViewController = storyboard?.instantiateInitialViewController()
                window.makeKeyAndVisible()
            }
        }
    }
    
}

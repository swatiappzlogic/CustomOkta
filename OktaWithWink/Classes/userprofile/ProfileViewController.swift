//
//  ProfileViewController.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import UIKit
import SwiftUI
import OktaOidc
import WebKit
class ProfileViewController: UIViewController {
    
    var userDetails:UserInfoResponse?
    var oktaOidc: OktaOidc?
    var authStateManager:OktaOidcStateManager? // Adjust this based on your implementation
    var webview:WKWebView?
    @IBOutlet weak var btnLogout: UIButton!
    @IBOutlet weak var btnVerifyToken: UIButton!
    var isFromWink:Bool = false
    @State private var createdTime: String = "N/A"
    @State private var expirationTime: String = "N/A"
    @State private var isEmailVerified: Bool = false
    @State private var accessToken: String?
    @State private var showAlert = false
    @State private var tokenValidMessage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnLogout.addTarget(self, action: #selector(logOutUser), for: .touchUpInside)
        self.btnVerifyToken.addTarget(self, action: #selector(checkIfTokenIsValid), for: .touchUpInside)
        // Initialize the ViewModel
        let viewModel = ProfileViewModel()
        
        // Safely unwrap userDetails and assign to viewModel.userProfile
        if let details = userDetails {
            viewModel.userDetails = details // Assign the entire UserInfoResponse object
        } else {
            print("User details are not available.")
        }
        
        // Create the SwiftUI ProfileView and pass the ViewModel
        let profileView = ProfileView(viewModel: viewModel)
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: profileView)
        
        // Add the hosting controller as a child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Set up constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        // Set constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150), // Corrected line
            hostingController.view.heightAnchor.constraint(equalToConstant: 300) // Example height constraint
        ])
        
        // Notify hostingController that it has moved to the parent view controller
        hostingController.didMove(toParent: self)
        self.navigationController?.navigationBar.isHidden = true
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func clearAllUserDefaults() {
        // Get all keys from UserDefaults
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        // Remove all keys except "deke"
        for key in dictionary.keys {
            if key != "user_details" && key != "WinkTag"{
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    @objc func logOutUser(){
        if(KeychainManager.shared.retrieve(key: "WinkTag")) != nil {

            self.navigationController?.popToRootViewController(animated: true)
        }
        else{
            oktaOidc!.signOutOfOkta(authStateManager!, from: self) { error in
                if let error = error {
                    // Error
                    
                    return
                }
                else{
                    DispatchQueue.main.async {
                        if let window = UIApplication.shared.windows.first {
                            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
                            window.rootViewController = storyboard?.instantiateInitialViewController()
                            window.makeKeyAndVisible()
                        }
                    }
                }
            }
        }
        
        self.clearAllUserDefaults()
        let result = KeychainManager.shared.clearAllKeychainData()
        if result {
            print("Keychain data cleared successfully.")
        } else {
            print("Failed to clear keychain data.")
            
        }
        
        let result1 = KeychainManager.shared.clearToken(forKey: "access_token")
        if result1 {
            print("Keychain access_token cleared successfully.")
        } else {
            print("Failed to clear keychain access_token.")
            
        }
    }
    
    @objc func checkIfTokenIsValid(){
        
        if let token = KeychainManager.shared.getToken(forKey: "access_token") {
            checkTokenValidity(token)
        }
    }
    
    private func navigateToLogin() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    func clearCookies() {
        self.webview?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                self.webview?.configuration.websiteDataStore.httpCookieStore.delete(cookie) {
                    print("Deleted cookie: \(cookie.name)")
                }
            }
        }
    }
    
    private func checkTokenValidity(_ jwt: String) {
        let segments = jwt.split(separator: ".")
        guard segments.count > 1 else { return }
        
        let payloadSegment = segments[1]
        let payloadData = base64UrlDecode(String(payloadSegment))
        
        if let payloadData = payloadData,
           let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            
            if let iat = payload["iat"] as? Double {
                let createdDate = Date(timeIntervalSince1970: iat)
                createdTime = formatDate(createdDate)
            }
            
            if let exp = payload["exp"] as? Double {
                let expirationDate = Date(timeIntervalSince1970: exp)
                expirationTime = formatDate(expirationDate)
                
                if expirationDate < Date() {
                    //tokenValidMessage = "Token is expired"
                    print("Token expired")
                    showAlert(message: "Token is expired", shouldNavigate: true)
                    self.navigationController?.popToRootViewController(animated: true)
                    
                    
                } else {
                    showAlert(message: "Token is valid", shouldNavigate: false)
                    print("Token is valid")
                }
                showAlert = true
            }
        }
    }
    
    private func showAlert(message: String, shouldNavigate: Bool) {
        let alert = UIAlertController(title: "Token Status", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if shouldNavigate {
                self.clearAllUserDefaults()
                self.navigateToLogin()
            }
        }))
        present(alert, animated: true)
    }
    
    private func base64UrlDecode(_ base64Url: String) -> Data? {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        return Data(base64Encoded: base64)
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

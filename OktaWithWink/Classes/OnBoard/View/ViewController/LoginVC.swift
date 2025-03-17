//
//  HomeVCViewController.swift
//  WinkApp
//
//  Created by MacBook on 31/12/24.
//

import UIKit
import OktaOidc
import Alamofire

protocol FaceVCDelegate: AnyObject {
    func didReceiveWinkTag(_ winkTag: String)
}

class LoginVC: UIViewController {
    
    var authStateManager:OktaOidcStateManager? = nil
    var user_response_from_wink:UserInfoResponse?
    
    var oktaOidc: OktaOidc?
    
    var isFromWink = false
    var aut0id = ""
    var querry_email = ""
    var id_token = ""
    let loginModel = LoginVM()
    var userDetails:UserInfoResponse?
    var winkSeed: String = ""

    var winkDataReceived: ((String) -> Void)?
    
    @IBOutlet weak var lblTagLabel:UILabel!
    @IBOutlet var btnLogOut:UIButton!
    
    var loginButton: UIButton!
    
    // MARK: - View LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppState.shared.initializeOkta()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
//        loginButton.isHidden = false
//        winkDataReceived = { [weak self] data in
//            // Handle the data received from C
//            //self?.fetchUser(winkTagStr: data)
//            self?.winkSeed = data
//            self?.loginButton.isHidden =  true
//            // You can update UI or perform other actions with the data
//            self?.getUser()
//        }
    }
    // MARK: - Custom Functions
    
    func setupUI(){
        view.backgroundColor = .white
        
        // Create and configure the login button
        loginButton = UIButton(type: .system)
        
        // Set the title for the button
        loginButton.setTitle("Login", for: .normal)
        
        // Customize the button appearance
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18) // Set font and size
        loginButton.backgroundColor = UIColor.blue // Set background color
        loginButton.setTitleColor(UIColor.white, for: .normal) // Set text color
        
        // Add borders
        loginButton.layer.borderWidth = 2.0 // Set border width
        loginButton.layer.borderColor = UIColor.white.cgColor // Set border color
        loginButton.layer.cornerRadius = 5.0 // Set corner radius for rounded edges
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // Add button to the view
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)
        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            loginButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 250), // Increased width to 250
            loginButton.heightAnchor.constraint(equalToConstant: 50)   // Height set to 50
        ])
    }
    
    func goToWinkLogin(){
        let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
        let faceDetectionVC = storyboard?.instantiateViewController(withIdentifier: "FaceDetectionVC") as! FaceDetectionVC
        //faceDetectionVC.delegate = self
        self.navigationController?.pushViewController(faceDetectionVC, animated: true)
    }
    
    func getUser(){
        
        LoaderManager.shared.showLoader(in: view)
        // API Endpoint
        let url = WebURL.baseURL + WebURL.getProfileURL
        
        winkSeed = winkSeed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if winkSeed.hasSuffix("\\") {
            winkSeed = String(winkSeed.dropLast()
            )
        }
        
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
            "Authorization": "Bearer \(winkSeed)",
        ]
        print("Request URL: \(url)")
        
        NetworkManager.shared.get(url: url, parameters: nil, headers: headers) { (result: Result<UserModel, NetworkError>) in
            
            LoaderManager.shared.hideLoader()
            
            switch result {
                
            case .success(let userResponse):
                DispatchQueue.main.async { [self] in
                    let isSuccess = KeychainManager.shared.save(key: "WinkTag", value: userDetails?.winkTag ?? "")
                    if isSuccess{
                        self.fetchUser(winkTagStr: userResponse.winkTag ?? "")
                    }
                    //self.setUser(userData: userResponse)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let networkError = error as? NetworkError {
                        print("Error Code: \(networkError)")
                    }
                    print("Error Details: \(error.localizedDescription)")
                    print("Full Error: \(error)")
                }
            }
        }
    }
    
    func goToProfile(){
        let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
        let profileVC = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        profileVC.oktaOidc = self.oktaOidc
        profileVC.authStateManager = self.authStateManager
        profileVC.userDetails = self.userDetails
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @objc func loginTapped() {
        
        let redirectUri = "com.intelli.Ritesh.com.SwiftUIDemo://callback"

        let oktaOidc = try? OktaOidc()

        // Use configuration from another resource
        let config = try? OktaOidcConfig(fromPlist: "Okta")

        // Instantiate OktaOidc with custom configuration object
        self.oktaOidc = try? OktaOidc(configuration: config)
        
        // Initialize OktaOidcConfig using the dictionary
        do {
            
            // Initiate sign-in with browser
            oktaOidc?.signInWithBrowser(from: self, callback: { stateManager, error in
                if let error = error {
                    let error_discription = error.localizedDescription.description
                    let error_onLoginWithWinkClick =  self.handleAuthorizationError(error: error)
                    if((error_discription != "User cancelled current session") && error_onLoginWithWinkClick)
                    {
                        self.isFromWink = true
//                        AppState.shared.authStateManager = stateManager
//                        let isSaveSuccessful =  KeychainManager.shared.save(key: "access_token", value: stateManager?.accessToken ?? "")
//                            print("dd")
//        

                        self.goToWinkLogin()
                    } else
                    {
                        self.isFromWink = false
                    }
                    return
                }
                
                // Successful login, handle the state manager
                if let authStateManager = stateManager {
                    self.authStateManager = stateManager
                    self.isFromWink = false
                    self.id_token = stateManager?.idToken ?? ""
                    AppState.shared.authStateManager = authStateManager
                    let isSaveSuccessful =  KeychainManager.shared.save(key: "access_token", value: stateManager?.accessToken ?? "")
                    
                    if isSaveSuccessful {
                        
                        if let accessToken = KeychainManager.shared.retrieve(key: "access_token") {
                            if let claims =  JWTService.shared.decodeJWT(token: self.id_token) {
                                self.aut0id = claims.sub ?? ""
                                let winkTag = KeychainManager.shared.retrieve(key: "WinkTag")
                                
                                AuthService.shared.authenticateUser(){ success in
                                    if success {
                                        self.userDetails = UserInfoResponse(firstName: "", lastName: "", contactNo: "", email: claims.name , winkTag: winkTag ?? "")
                                        
                                        AppState.shared.userDetails = self.userDetails
                                        DispatchQueue.main.async {
                                            self.goToProfile()
                                        }
                                    }
                                    else{
                                    }
                                }
                            }
                        } else {
                            print("No Access Token Available")
                        }
                    }
                }
            })
            
        } catch {
            print("Error initializing OktaOidcConfig: \(error)")
        }
    }
    
    func handleAuthorizationError(error: Error) -> Bool{
        // Get the full localized description of the error
        let errorDescription = error.localizedDescription
        
        // Check if it contains "State mismatch"
        if errorDescription.contains("State mismatch") {
            print("Authorization Error: State mismatch")
            return true
        } else {
            // Print the entire error description for further debugging
            print("Error: \(errorDescription)")
            return false
        }
        
        return false
    }
    
    func confirmOktaView(){
        let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
        let OktaLoginVC = storyboard?.instantiateViewController(withIdentifier: "OktaConfirmViewController") as! OktaConfirmViewController
        OktaLoginVC.userDetails = self.user_response_from_wink
        self.navigationController?.pushViewController(OktaLoginVC, animated: true)
    }
    
    func fetchUser(winkTagStr:String) {
        let winkTag = winkTagStr // Replace with dynamic value
        AuthService.shared.authenticateUser() { success in
            if success {
                
                AuthService.shared.fetchUserByWinkTag(winkTag: winkTag) { result in
                    switch result {
                    case .success(let users):
                        if users.isEmpty {
                            print("Wink tag is not attached to this ID")
                            DispatchQueue.main.async {
                                self.confirmOktaView()
                            }
                        } else {
                            for user in users {
                                print("Nickname: \(user.nickname), Email: \(user.email), User ID: \(user.userId)")
                                let user_email = user.email
                                self.user_response_from_wink = UserInfoResponse(firstName: "", lastName: "", contactNo: "", email: user_email, winkTag: winkTag)
                                DispatchQueue.main.async {
                                    self.goToProfile()
                                }
                            }
                        }
                    case .failure(let error):
                        print("Error fetching user: \(error.localizedDescription)")
                    }
                }
                
            }else{
                
            }
        }
    }
    
    // MARK: - Button Action
    
    @IBAction func logoutTapped() {
        if(isFromWink){
            oktaOidc!.signOutOfOkta(authStateManager!, from: self) { error in
                if let error = error {
                    // Error
                    return
                }
            }
        }else{
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        }
    }
}


extension LoginVC: FaceVCDelegate{
    func didReceiveWinkTag(_ winkTag: String) {
        self.fetchUser(winkTagStr: winkTag)
    }
}

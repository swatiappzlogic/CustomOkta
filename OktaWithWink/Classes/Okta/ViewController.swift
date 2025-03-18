import UIKit
//import OktaOidc
import WebKit


public class ViewController: UIViewController {
    
    @IBOutlet weak var lblTagLabel:UILabel!
    @IBOutlet weak var lblWelcome:UILabel!
    
    @IBOutlet var btnLogOut:UIButton!
    
    var oktaOidc: OktaOidc?
    var authStateManager:OktaOidcStateManager? = nil // Adjust this based on your implementation
    var querry_email = ""
    var id_token = ""
    var aut0id = ""
    var isFromWink = false
    var userDetails:UserInfoResponse?
    var user_response_from_wink:UserInfoResponse?
    
    let invalidUrlNotification = Notification.Name("Invalid URL")
    let winkTagSavedNotification = Notification.Name("winkTag Saved")
    let confirmOktadNotification = Notification.Name("confirmOkta")
    
    // MARK: - View LifeCycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Create and configure the login button
        let loginButton = UIButton(type: .system)
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInvalidURLNotification), name: self.invalidUrlNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUser), name: self.winkTagSavedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(confirmOktaView), name: self.confirmOktadNotification, object: nil)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @objc func handleInvalidURLNotification() {
        // Ensure that the UI update happens on the main thread
        DispatchQueue.main.async {
            // Pop the view controller from the navigation stack
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    deinit {
        // Remove observer when the view controller is deallocated
        NotificationCenter.default.removeObserver(self, name: self.invalidUrlNotification, object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        
        let userdetails = Helper.loadUserInfo()
        
        lblWelcome.text = "Welcome " + (userdetails?.firstName.capitalized ?? "" + "!")
        
        super.viewWillAppear(animated)
    }
    
    // MARK: - Action Methods
    
    @objc func logoutTapped() {
        if(KeychainManager.shared.retrieve(key: "winkTag")) != nil {
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
    
    func goToWinkLogin(){
        
        let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
        let faceDetectionVC = storyboard?.instantiateViewController(withIdentifier: "FaceDetectionVC") as! FaceDetectionVC
        // faceDetectionVC.winkDataReceived =  winkDataReceived
        faceDetectionVC.delegate = self
        self.navigationController?.pushViewController(faceDetectionVC, animated: true)
        return
    }
    
    func checkForAlreadyLoginUser(){
        
        if let accessToken = KeychainManager.shared.getToken(forKey: "access_token") {
            
            print("Access Token WinkApp  \(accessToken)")
            let frmWink = KeychainManager.shared.retrieveBool(key: "wink_Login") ?? false
            let isTokenValid = checkTokenValidity(accessToken)
            
            if isTokenValid{
                let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
                let profileVC = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                profileVC.isFromWink = frmWink
                profileVC.userDetails = frmWink ? self.user_response_from_wink : self.userDetails
                self.navigationController?.pushViewController(profileVC, animated: true)
                return
            } else{
                
            }
        }
        
        
        if (KeychainManager.shared.retrieve(key: "WinkTag") != nil){
            goToWinkLogin()
        } else{
            authnticateWithOkta()
        }
        
    }
    
    
    @objc func loginTapped() {
        
        checkForAlreadyLoginUser()
    }
    
    func authnticateWithOkta() {
        
        var oktaOidc = try? OktaOidc()
        
        // Use configuration from another resource
        // let config = try? OktaOidcConfig(fromPlist: "Okta")
        
        if let config = WinkSDKBundleManager.loadOktaConfig(fromCustomBundle: "Okta") {
            print("Successfully loaded Okta config: \(config)")
            do {
               // self.oktaOidc = try OktaOidc(configuration: config)
                oktaOidc  = try OktaOidc(configuration: config)
                self.oktaOidc = oktaOidc
                print("Successfully initialized OktaOidc")
            } catch {
                print("Error initializing OktaOidc: \(error)")
            }
            
            
            do {
                
                DispatchQueue.main.async {
                    if let sdkViewController = self.parent?.children.first(where: { $0 is ViewController }) {
                    
                        // Initiate sign-in with browser
                        oktaOidc?.signInWithBrowser(from: self.parent!, callback: { stateManager, error in
                            
                            // Successful login, handle the state manager
                            if let authStateManager = stateManager {
                                // authStateManager.writeToSecureStorage()
                                // try? authStateManager.removeFromSecureStorage()
                                self.authStateManager = stateManager
                                print("Logged in successfully!")
                                self.isFromWink = false
                                
                                do {
                                    try KeychainManager.shared.saveToken(authStateManager.accessToken ?? "", forKey: "access_token")
                                } catch let error {
                                    print("Failed to save token: \(error)")
                                    // Handle the error appropriately (e.g., show an alert or log it)
                                }
                                
                                self.id_token = authStateManager.idToken ?? ""
                                //UserDefaults.standard.set(authStateManager.accessToken, forKey: "access_token")
                                
                                do {
                                    try KeychainManager.shared.saveToken(authStateManager.accessToken ?? "", forKey: "access_token")
                                } catch let error {
                                    print("Failed to save token: \(error)")
                                    // Handle the error appropriately (e.g., show an alert or log it)
                                }
                                
                                if let accessToken = KeychainManager.shared.getToken(forKey: "access_token") {
                                    print("Retrieved Access Token: \(accessToken)") // Debugging line
                                    if let claims =  JWTService.shared.decodeJWT(token: self.id_token as! String) {
                                        self.aut0id = claims.sub ?? ""
                                        // let winkTag = UserDefaults.standard.string(forKey: "WinkTag") ?? ""
                                        let winkTag = KeychainManager.shared.retrieve(key:"WinkTag") ?? ""
                                        
                                        AuthService.shared.authenticateUser() { success in
                                            if success {
                                                
                                                self.userDetails = UserInfoResponse(firstName: "", lastName: "", contactNo: "", email: claims.name as! String, winkTag: winkTag)
                                                
                                                if let details = self.userDetails{
                                                    Helper.saveUserInfo(userDetails: details)
                                                }
                                                //UserDefaults.standard.set(false, forKey: "wink_login")
                                                KeychainManager.shared.saveBool(key: "wink_login", value:false)
                                                
                                                DispatchQueue.main.async {
                                                    // self.performSegue(withIdentifier: "id_profile", sender: nil)
                                                    self.goToProfile(frmWink: false)
                                                }
                                            }else{
                                                
                                            }
                                        }
                                    }
                                    
                                } else {
                                    print("No Access Token Available")
                                }
                            }
                            
                            
                            if let error = error {
                                let error_discription = error.localizedDescription.description
                                let error_onLoginWithWinkClick =  self.handleAuthorizationError(error: error)
                                
                                if((error_discription != "User cancelled current session") && error_onLoginWithWinkClick)
                                {
                                    self.isFromWink = true
                                    self.goToWinkLogin()
                                }
                                else
                                {
                                    self.isFromWink = false
                                }
                                
                                return
                            }
                            
                        }
                        )
                    }
                }
            } catch {
                print("Error initializing OktaOidcConfig: \(error)")
            }
            
        } else {
            print("Failed to load Okta config.")
        }
        // Instantiate OktaOidc with custom configuration object
    }
    
    // MARK: - Helper Methods
    
    private func checkTokenValidity(_ jwt: String) -> Bool {
        let segments = jwt.split(separator: ".")
        guard segments.count > 1 else {
            // If the JWT is not valid (doesn't have the expected segments), return false
            return false
        }
        
        let payloadSegment = segments[1]
        guard let payloadData = Helper.base64UrlDecode(String(payloadSegment)) else {
            // If decoding the payload fails, return false
            return false
        }
        
        // Decode the JWT to get the creation and expiration dates
        let dates = Helper.decodeJWT(jwt)
        
        // Use optional binding to safely extract created and expiration times
        guard let createdTime = dates.createdDate, let expirationTime = dates.expirationDate else {
            // If we cannot extract the dates, return false
            return false
        }
        
        // Convert payload data into dictionary
        if let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            
            // Check if the "exp" field is present and valid
            if let exp = payload["exp"] as? Double {
                let expirationDate = Date(timeIntervalSince1970: exp)
                
                // Check if the token is expired
                if expirationDate < Date() {
                    print("Token expired")
                    return false
                } else {
                    print("Token is valid")
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper function to display alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
    
    // MARK: - Navigation Methods
    
    
    @objc func confirmOktaView(){
        
        if let topViewController = self.navigationController?.topViewController,
           !(topViewController is OktaConfirmViewController) {
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let OktaLoginVC = storyboard?.instantiateViewController(withIdentifier: "OktaConfirmViewController") as! OktaConfirmViewController
            OktaLoginVC.userDetails = self.user_response_from_wink
            UserDefaults.standard.setValue(self.user_response_from_wink?.firstName, forKey: "UserName")
            self.navigationController?.pushViewController(OktaLoginVC, animated: true)
        } else{
            
        }
    }
    
    func goToProfile(frmWink: Bool){
        if let topViewController = self.navigationController?.topViewController,
           !(topViewController is ProfileViewController) {
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let profileVC = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            profileVC.oktaOidc = self.oktaOidc
            profileVC.isFromWink = frmWink
            profileVC.authStateManager = self.authStateManager
            profileVC.userDetails = frmWink ? self.user_response_from_wink : self.userDetails
            
            self.navigationController?.pushViewController(profileVC, animated: true)
        } else{
            
        }
    }
    
    // MARK: - Network Methods
    
    //Get User info from okta email id
    func getUserInfoFromOkta(userDetails:UserInfoResponse)
    {
        let email = userDetails.email
        
        AuthService.shared.fetchUserDetails(query: email) { userResponses, success in
            if success, let users = userResponses {
                if(users.count > 0){
                    for user in users {
                        print("User ID: \(user.user_id), Email: \(user.email), Name: \(user.name)")
                        DispatchQueue.main.async {
                            self.goToProfile(frmWink: false)
                        }
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.confirmOktaView()
                    }
                }
                
            } else {
                print("Failed to fetch user details.")
                DispatchQueue.main.async {
                    self.confirmOktaView()
                }
            }
        }
    }
    
    //Get user details from winkTag and check if winkTag is mapped or not
    @objc func fetchUser() {
        //var winkTag = winkTagStr
        
        //let winkTag = UserDefaults.standard.value(forKey: "WinkTag") as! String
        
        let winkTag = KeychainManager.shared.retrieve(key:"WinkTag") ?? ""
        
        // Replace with dynamic value
        AuthService.shared.authenticateUser() { success in
            if success {
                
                AuthService.shared.fetchUserByWinkTag(winkTag: winkTag) { result in
                    switch result {
                    case .success(let users):
                        if users.isEmpty {
                            print("Wink tag is not attached to this ID")
                            DispatchQueue.main.async {
                                //self.performSegue(withIdentifier: "id_okta_login", sender: nil)
                                self.confirmOktaView()
                                
                            }
                        } else {
                            for user in users {
                                print("Nickname: \(user.nickname), Email: \(user.email), User ID: \(user.userId)")
                                let user_email = user.email
                                self.user_response_from_wink = UserInfoResponse(firstName: UserDefaults.standard.value(forKey: "UserName") as! String, lastName: "", contactNo: "", email: user_email, winkTag: winkTag)
                                if let details = self.user_response_from_wink{
                                    Helper.saveUserInfo(userDetails: details)
                                }
                                
                                //UserDefaults.standard.set(true, forKey: "wink_login")
                                KeychainManager.shared.saveBool(key: "wink_login", value:true)
                                
                                DispatchQueue.main.async {
                                    //self.performSegue(withIdentifier: "id_profile", sender: nil)
                                    self.goToProfile(frmWink: true)
                                }
                            }
                        }
                    case .failure(let error):
                        print("Error fetching user: \(error.localizedDescription)")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: -

extension ViewController: FaceVCDelegate{
    func didReceiveWinkTag(_ winkTag: String) {
        self.fetchUser()
    }
}

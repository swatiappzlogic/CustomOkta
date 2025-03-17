//
//  WelcomeVCViewController.swift
//  WinkApp
//
//  Created by MacBook on 13/12/24.
//

import UIKit
import Alamofire
//import FingerprintJS


protocol WingTag_Delegate: AnyObject {
    func didReceiveWinkTag(winkTag: String)
}

class WelcomeVC: UIViewController {
    
    @IBOutlet weak var txtFieldFirstName: UITextField?
    @IBOutlet weak var txtFieldLasttName: UITextField?
    @IBOutlet weak var txtFieldEmail: UITextField?
    @IBOutlet weak var txtFieldContact: UITextField?
    @IBOutlet weak var txtFieldDateofBirth: UITextField?
    @IBOutlet weak var txtFieldDevcieId: UITextField?
    
    var winkDataReceived: ((String) -> Void)?
    
    var winkSeed: String = ""
    var clientToken: String = ""
    var userDetails : UserModel?
    var user_response_from_wink:UserInfoResponse?
    
    
    // MARK: - View lifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let fingerprinter = FingerprinterFactory.getInstance()
//        
//        fingerprinter.getDeviceId { deviceId in
//            print("Fetched Device ID: \(String(describing: deviceId))") // Debug log
//            
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                if let deviceId = deviceId, !deviceId.isEmpty {
//                    self.txtFieldDevcieId?.text = deviceId
//                    print("Updated UI with Device ID: \(deviceId)")
//                } else {
//                    self.txtFieldDevcieId?.text = "Device ID not available"
//                    print("Error: Device ID is nil or empty")
//                }
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.getUser()
        //popBackToRootAndSendData(winkTag: userDetails?.winkTag ?? "")

    }
    
    // MARK: - Action Methods
    
    @IBAction func scanButtonAction(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func updateButtonAction(){
        let enrollVC = StoryBoards.main.instantiateViewController(withIdentifier: "EnrollmentVC") as! EnrollmentVC
        enrollVC.updateUser =  true
        enrollVC.clientToken = userDetails?.winkToken ?? ""
        enrollVC.userDetails = userDetails
        self.navigationController?.pushViewController(enrollVC, animated: true)
    }
    
    // MARK: - Custom Methods
    
    func setUser(userData: UserModel){
        
        userDetails = userData
//        txtFieldFirstName?.text = userData.firstName
//        txtFieldLasttName?.text = userData.lastName
//        txtFieldEmail?.text = userData.email
//        txtFieldDateofBirth?.text =  Helper.convertToDateFormatWithoutTime(inputDate: userData.dateOfBirth ?? "")
//        txtFieldContact?.text = userData.contactNo
//        clientToken = userData.winkToken ?? ""
        let isSuccess = KeychainManager.shared.save(key: "WinkTag", value: userDetails?.winkTag ?? "")
        
        if(isSuccess){
            print("winkTag Saved")
            self.fetchUser(winkTagStr: userDetails?.winkTag ?? "")
           // popBackToRootAndSendData(winkTag: userDetails?.winkTag ?? "")
        }
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
    
    func confirmOktaView(){
        
        let OktaLoginVC = StoryBoards.main.instantiateViewController(withIdentifier: "OktaConfirmViewController") as! OktaConfirmViewController
        OktaLoginVC.userDetails = self.user_response_from_wink
        self.navigationController?.pushViewController(OktaLoginVC, animated: true)
    }
    
    func goToProfile(){
        let profileVC = StoryBoards.main.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        //profileVC.oktaOidc = self.oktaOidc
        //profileVC.authStateManager = self.authStateManager
        //profileVC.userDetails = self.userDetails
        self.navigationController?.pushViewController(profileVC, animated: true)
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
                    self.setUser(userData: userResponse)
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
    
    // Dismiss the keyboard when tapping outside of the text fields
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func popBackToRootAndSendData(winkTag: String) {
        // Send data to VC A via delegate
        winkDataReceived?(winkTag)
        // Pop back to root view controller (VC A)
        navigationController?.popToRootViewController(animated: true)
    }
}


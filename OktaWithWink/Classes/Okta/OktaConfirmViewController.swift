//
//  OktaConfirmViewController.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import UIKit
import SwiftUI

class OktaConfirmViewController: UIViewController {
    
    var userDetails:UserInfoResponse?
    var isPasswordVisible: Bool = false
    
    
    @IBOutlet weak var txtFieldEmail: UITextField!
    @IBOutlet weak var txtFieldPassword: UITextField!
    @IBOutlet weak var viwContent: UIView!
    @IBOutlet weak var eyeIconButton: UIButton! // This is the button for the eye icon
            
    var originalViewY: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalViewY = viwContent.frame.origin.y
        // Set up the eye icon as a button
                let eyeIcon = UIImage(systemName: "eye.slash.fill")
                eyeIconButton.setImage(eyeIcon, for: .normal)
        
        // Add gesture recognizer to dismiss the keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        txtFieldPassword.isSecureTextEntry = true
        // Register for keyboard notifications
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        // Remove observer when the view controller is deallocated
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard Notifications
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        let textFieldBottomY = txtFieldPassword.frame.origin.y + txtFieldPassword.frame.height

        // Check if the keyboard will cover the text field, if so, adjust the view
        if textFieldBottomY > keyboardFrame.origin.y {
            // If the text field is going to be covered, move the content up
            let offset = textFieldBottomY - keyboardFrame.origin.y
            UIView.animate(withDuration: 0.3) {
                self.viwContent.frame.origin.y = self.originalViewY - offset - 10 // Add a small margin to prevent the view from getting too close to the keyboard
            }
        }
    }

    
    // Action for when the eye icon is tapped
        @IBAction func togglePasswordVisibility(_ sender: UIButton) {
            isPasswordVisible.toggle() // Toggle the password visibility state
            
            // Change the secure text entry property based on the state
            txtFieldPassword.isSecureTextEntry = !isPasswordVisible
            
            // Change the eye icon based on the password visibility state
            let eyeIconName = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
            let eyeIcon = UIImage(systemName: eyeIconName)
            eyeIconButton.setImage(eyeIcon, for: .normal)
        }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // Reset the view content to its original position when the keyboard hides
        UIView.animate(withDuration: 0.3) {
            self.viwContent.frame.origin.y = self.originalViewY
        }
    }
    // MARK: - Custom Methods
    
    func performAPICall() {
        // Simulate a successful API call after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Notify the delegate that login is complete, passing the username and password
            self.didCompleteOktaLogin(success: true, username: self.txtFieldEmail.text ?? "", password: self.txtFieldPassword.text ?? "")
        }
    }
    
    // Dismiss the keyboard when tapping outside of the text fields
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func goToProfile(){
        
        if let topViewController = self.navigationController?.topViewController,
           !(topViewController is ProfileViewController) {
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let profileVC = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            profileVC.isFromWink = true
            // UserDefaults.standard.set(true, forKey: "wink_login")
            KeychainManager.shared.saveBool(key: "wink_login", value:true)
            profileVC.userDetails = self.userDetails
            self.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    // Validate if text fields are not empty and if email format is correct
    func validateInputs() -> Bool {
        guard let email = txtFieldEmail.text, !email.isEmpty else {
            Helper.showAlert(on: self, title: "", message: "Email cannot be empty.")
            return false
        }
        
        guard Helper.isValidEmail(email) else {
            Helper.showAlert(on: self, title: "", message: "Please enter a valid email address.")
            
            return false
        }
        
        guard let password = txtFieldPassword.text, !password.isEmpty else {
            Helper.showAlert(on: self, title: "", message: "Password cannot be empty.")
            
            return false
        }
        
        return true
    }
    
    @IBAction func confirmButtonAction() {
        if validateInputs() {
            performAPICall()
        }
    }
    
    func didCompleteOktaLogin(success: Bool, username: String?, password: String?) {
        
        DispatchQueue.main.async {
            
            LoaderManager.shared.showLoader(in: self.view)
        }

        if success {
            
            AuthService.shared.loginUser(username: username!, password: password!) { result in
                switch result {
                case .success(let response):
                    // Handle successful login and access token
                    print("Login successful! Response: \(response)")
                    
                    if let accessToken = response["access_token"] as? String {
                        // Use the access token as needed
                        print("Access Token Received: \(accessToken)")
                        let id_token = response["id_token"]
                        print("Id Token:\(id_token)")
                        var aut0id = ""
                        if let claims =  JWTService.shared.decodeJWT(token: id_token as! String) {
                            // print("Given Name: \(claims.given_name)")
                            // print("Family Name: \(claims.family_name)")
                            print("Nickname: \(claims.nickname)")
                            print("Email: \(claims.email)")
                            print("Picture URL: \(claims.picture)")
                            aut0id = claims.sub ?? ""
                           // let winkTag = UserDefaults.standard.string(forKey: "WinkTag") ?? ""
                            let winkTag = KeychainManager.shared.retrieve(key:"WinkTag") ?? ""

                            let name = UserDefaults.standard.string(forKey: "UserName")  ?? ""
                            self.userDetails = UserInfoResponse(firstName: name, lastName: "", contactNo: "", email: claims.email ?? "", winkTag: winkTag)
                                                        
                            AuthService.shared.authenticateUser() { success in
                                if success {
                                    //let winkTag = UserDefaults.standard.string(forKey: "WinkTag") ?? ""
                                    let winkTag = KeychainManager.shared.retrieve(key:"WinkTag") ?? ""
                                    
                                    AuthService.shared.addSecondaryAccountIdentity(primaryAccountUserID: aut0id, provider: "wink", userID: winkTag, connectionID: "") { success in
                                        if success {
                                            print("Secondary account identity added successfully.")
                                            // Access other properties as needed
                                            DispatchQueue.main.async {
                                                //self.performSegue(withIdentifier: "id_profile_view", sender: nil)
                                                self.goToProfile()
                                                LoaderManager.shared.hideLoader()

                                            }
                                            
                                        } else {
                                            print("Failed to add secondary account identity.")
                                        }
                                    }
                                }else{
                                    
                                }
                            }
                            
                            
                        } else {
                            print("Failed to decode JWT.")
                        }
                        
                        
                    }
                    
                case .failure(let error):
                    print("Login failed with error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        LoaderManager.shared.hideLoader()

                    }
                }
            }
        }
        
        LoaderManager.shared.hideLoader()

    }
    
    
    // Delegate method to handle the login success
    
    
}

extension OktaConfirmViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

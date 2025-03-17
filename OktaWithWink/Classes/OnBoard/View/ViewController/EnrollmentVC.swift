//
//  RegisterVC.swift
//  WinkApp
//
//  Created by MacBook on 19/12/24.
//

import UIKit
import ADCountryPicker
import DatePicker
import FlagPhoneNumber
import PhoneNumberKit
import Alamofire

class EnrollmentVC: UIViewController {
    
    var user_response_from_wink:UserInfoResponse?
    var winkSeed: String = ""
    
    @IBOutlet weak var imgViewFlag: UIImageView?
    @IBOutlet weak var imgViewCheckmark: UIImageView?
    
    @IBOutlet weak var btnFlag: UIControl?
    
    @IBOutlet weak var txtFieldPhone: FPNTextField?
    @IBOutlet weak var txtFieldDOB: UITextField?
    @IBOutlet weak var txtFieldEmail: UITextField?
    @IBOutlet weak var txtFieldFirstName: UITextField?
    @IBOutlet weak var txtFieldLastName: UITextField?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let enrollmntModel = EnrollmentVM()
    let picker = ADCountryPicker()
    let phoneNumberKit = PhoneNumberKit()
    
    var clientToken: String = ""
    var birthSelectedDate: String = ""
    var userPhoneNo: String = ""
    
    var dialCodeVal: String = ""
    var updateUser = false
    var termsSelected = false
    var userDetails: UserModel?
    weak var delegate: FaceVCDelegate? // Add this line
    
    // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable keyboard for DOB field
        txtFieldDOB?.isUserInteractionEnabled = true
        
        // Set the date picker setup
        txtFieldPhone?.hasPhoneNumberExample = false // true by default
        txtFieldPhone?.placeholder = "Phone number*"
        txtFieldPhone?.flagButtonSize = CGSize(width: 44, height: 44)
        
        enrollmntModel.delegate = self
        
        // Register for keyboard notifications to adjust scroll view
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKb))
        tap.delegate = self  // Set delegate
        view.addGestureRecognizer(tap)
        
        dialCodeVal = "+1" // Default to +1 (US)
        txtFieldPhone?.setFlag(countryCode: .US)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if updateUser {
            setUserDetails()
        }
    }
    
    // MARK: - Custom Methods
    
    @objc func dismissKb() {
        view.endEditing(true)
    }
    
    func setUserDetails() {
        
        if let phoneNumber = userDetails?.contactNo {
            do {
                // Parse the phone number (it needs to be in international format, i.e., with a '+' sign and country code)
                let parsedPhoneNumber = try phoneNumberKit.parse(phoneNumber)
                
                // Get the region code (e.g., "US" for United States, "UZ" for Uzbekistan)
                let countryCode = phoneNumberKit.getRegionCode(of: parsedPhoneNumber)
                
                // Check if the countryCode is valid (non-empty string)
                if let countryCode = countryCode, !countryCode.isEmpty {
                    // Convert country code (String) to FPNCountryCode enum value
                    if let countryCodeEnum = FPNCountryCode(rawValue: countryCode) {
                        // Set the flag using the FPNCountryCode enum
                        txtFieldPhone?.setFlag(countryCode: countryCodeEnum)
                    } else {
                        // If the country code is not recognized, set a fallback (e.g., US)
                        txtFieldPhone?.setFlag(countryCode: .US)  // Default to US if the country code is unrecognized
                    }
                } else {
                    // If no valid country code, fallback to a default (e.g., US)
                    txtFieldPhone?.setFlag(countryCode: .US)  // Default to US if the region code is invalid or missing
                }
                
                userPhoneNo = phoneNumber
                
                // Set the phone number in the text field
                txtFieldPhone?.set(phoneNumber: phoneNumber)
                
            } catch {
                print("Error parsing phone number: \(error)")
                
                // Fallback: If parsing fails, use a default country code (e.g., US)
                txtFieldPhone?.setFlag(countryCode: .US)  // Default to US if parsing fails
                txtFieldPhone?.set(phoneNumber: phoneNumber)
            }
        }
        
        
        // Set other user details
        txtFieldDOB?.text = Helper.convertToDateFormatWithoutTime(inputDate: userDetails?.dateOfBirth ?? "")
        birthSelectedDate = txtFieldDOB?.text ?? ""
        txtFieldEmail?.text = userDetails?.email
        txtFieldFirstName?.text = userDetails?.firstName
        txtFieldLastName?.text = userDetails?.lastName
    }
    
    
    //
    
    func showDatePicker(sender: UITextField) {
        let minDate = DatePickerHelper.shared.dateFrom(day: 01, month: 01, year: 1950)!
        let maxDate = DatePickerHelper.shared.dateFrom(day: 01, month: 12, year: 2050)!
        let today = Date()
        
        let datePicker = DatePicker()
        datePicker.setup(beginWith: today, min: minDate, max: maxDate) { (selected, date) in
            if selected, let selectedDate = date {
                var dateFormatted = ""
                if let formattedDate = Helper.convertToBirthDateFormat(inputDate: selectedDate.string() ) {
                    dateFormatted = (formattedDate)
                }
                self.birthSelectedDate = dateFormatted
                self.txtFieldDOB?.text = dateFormatted
            } else {
                print("Cancelled")
            }
        }
        view.endEditing(true)
        
        datePicker.show(in: self, on: sender)
    }
    
    func createUser(){
        
        LoaderManager.shared.showLoader(in: view)
        let params: [String: String] = [
            "clientToken":  clientToken,
            "qCToken": randomAlphanumericString(9),
            "firstName": txtFieldFirstName?.text ?? "",
            "lastName": txtFieldLastName?.text ?? "",
            "contactNo": dialCodeVal+(txtFieldPhone?.text ?? ""),
            "email": txtFieldEmail?.text ?? "",
            "dateOfBirth": Helper.convertToDateFormatWithTime(inputDate:birthSelectedDate) ?? "",
            "PalmId": randomAlphanumericString(9)
        ]
        
        enrollmntModel.createUserOnServer(dict: params as NSDictionary)
    }
    
    func randomAlphanumericString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.count)
        var random = SystemRandomNumberGenerator()
        var randomString = ""
        for _ in 0..<length {
            let randomIndex = Int(random.next(upperBound: len))
            let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
            randomString.append(randomCharacter)
        }
        return randomString
    }
    
    func checkEmailExistence(){
    }
    
    func checkContactExistence(){
        
    }
    
    // MARK: - Keyboard Notifications
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            var contentInset = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.height
            self.scrollView.contentInset = contentInset
            self.scrollView.scrollIndicatorInsets = contentInset
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = 0
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = contentInset
    }
    
    // MARK: - Validation Method
    
    func validateForm() -> Bool {
        if txtFieldFirstName?.text?.isEmpty == true ||
            txtFieldLastName?.text?.isEmpty == true ||
            txtFieldEmail?.text?.isEmpty == true ||
            txtFieldDOB?.text?.isEmpty == true ||
            txtFieldPhone?.text?.isEmpty == true {
            showAlert(message: "Please fill all fields.")
            return false
        }
        
        if let email = txtFieldEmail?.text, !isValidEmail(email) {
            showAlert(message: "Please enter a valid email address.")
            return false
        }
        
        if let firstName = txtFieldFirstName?.text, containsSpecialCharacters(firstName) {
            showAlert(message: "First name should not contain special characters.")
            return false
        }
        
        if let lastName = txtFieldLastName?.text, containsSpecialCharacters(lastName) {
            showAlert(message: "Last name should not contain special characters.")
            return false
        }
        
        return true
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(message: String, shouldPop: Bool = false) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        // Add the "OK" button with a handler
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            // If shouldPop is true, pop the view controller
            if shouldPop {
                DispatchQueue.main.async {
                    if let viewControllers = self.navigationController?.viewControllers {
                        // Find the view controller you want to pop to
                        if let targetController = viewControllers.first(where: { $0 is FaceDetectionVC }) {
                            self.navigationController?.popToViewController(targetController, animated: true)
                        }
                    }
                }
            }
        }))
        
        // Present the alert
        present(alert, animated: true, completion: nil)
    }
    
    // Helper method to validate email
    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: email)
    }
    
    // Helper method to check for special characters
    func containsSpecialCharacters(_ string: String) -> Bool {
        let regex = "[^a-zA-Z0-9 ]"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: string)
    }
    
    // MARK: - Button Actions
    
    @IBAction func flagButtonAction() {
        // Create the country list view controller
        let listController = FPNCountryListViewController(style: .grouped)
        
        // Set display mode to .list
        txtFieldPhone?.displayMode = .list // .picker by default
        
        // If the country repository is nil, you may handle the situation here or set it properly
        if let countryRepository = txtFieldPhone?.countryRepository {
            listController.setup(repository: countryRepository)
        } else {
            // Optionally handle the case where the country repository is nil
            print("Country repository is not available.")
        }
        
        // Setup the didSelect closure to update flag and phone number
        listController.didSelect = { [weak self] country in
            guard let self = self else { return }
            
            // Update the flag of the phone number text field
            self.txtFieldPhone?.setFlag(countryCode: country.code)
            
            // Optionally, set the country code or any other details if needed
            // self.txtFieldPhone?.setCountryCode(country.dialCode) // Set the dial code
            
            // Dismiss the country picker
            self.dismiss(animated: true, completion: nil)
        }
        
        // Create a navigation controller and present the country list view controller
        let navigationViewController = UINavigationController(rootViewController: listController)
        listController.title = "Countries"  // Set the title
        
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @IBAction func termsAndConditionButtonAction() {
        
        termsSelected = !termsSelected
        
        imgViewCheckmark?.image = termsSelected ? UIImage(named: "checked") : UIImage(named: "unchecked")
    }
    
    @IBAction func submitForm() {
        if validateForm()  && termsSelected{
            // Continue with your user creation or update process
            createUser()
        } else{
            showAlert(message: "You must accept to Terms & conditions to submit.")
        }
    }
    
    @IBAction func scanButtonAction() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func resetFlagAndDialCode() {
        imgViewFlag?.image = UIImage(named: "phonePlaceholder")
        txtFieldPhone?.text = ""  // Optionally clear the phone number text field
    }
}

extension EnrollmentVC : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Dismiss the keyboard if it is visible
        
        // Show date picker if DOB field is selected
        if textField == txtFieldDOB {
            showDatePicker(sender: textField)
            textField.resignFirstResponder()
            view.endEditing(true)
        }
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only apply logic if the phone number field is being modified
        if textField == txtFieldPhone {
            // Get the current phone number input
            guard let currentText = textField.text else { return true }
            
            // The full phone number after the new character is added
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            // Remove non-numeric characters (except for the '+' sign for country code)
            let cleanedText = updatedText.filter { $0.isNumber || $0 == "+" }
            
            // Check if the input starts with a '+' (indicating country code)
            if cleanedText.hasPrefix("+") {
                // Extract the prefix after the '+' sign
                let prefix = cleanedText
                
                // Check for any valid dial code that matches the prefix entered so far
                //updateFlagAndDialCode(for: prefix) // Update the flag and dial code based on the prefix
            } else {
                // If there is no '+' prefix, reset the flag and dial code
                imgViewFlag?.image = picker.getFlag(countryCode: picker.defaultCountryCode)
                // resetFlagAndDialCode()
            }
            
            // Allow the text to be updated
            textField.text = cleanedText
            return false  // We are manually updating the text field, so return false here
        }
        
        return true  // Return true for other text fields, if needed
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        view.endEditing(true)
        
        if (textField == txtFieldEmail){
            checkEmailExistence()
        } else if(textField == txtFieldPhone){
            //checkContactExistence()
            
            if let phoneNumber = textField.text {
                do {
                    // Parse the phone number (it needs to be in international format, i.e., with a '+' sign and country code)
                    let parsedPhoneNumber = try phoneNumberKit.parse(phoneNumber)
                    
                    // Get the region code (e.g., "US" for United States, "UZ" for Uzbekistan)
                    let countryCode = phoneNumberKit.getRegionCode(of: parsedPhoneNumber)
                    
                    // Check if the countryCode is valid (non-empty string)
                    if let countryCode = countryCode, !countryCode.isEmpty {
                        // Convert country code (String) to FPNCountryCode enum value
                        if let countryCodeEnum = FPNCountryCode(rawValue: countryCode) {
                            // Set the flag using the FPNCountryCode enum
                            // txtFieldPhone?.setFlag(countryCode: countryCodeEnum)
                        } else {
                            // If the country code is not recognized, set a fallback (e.g., US)
                            //txtFieldPhone?.setFlag(countryCode: .US)  // Default to US if the country code is unrecognized
                        }
                    } else {
                        // If no valid country code, fallback to a default (e.g., US)
                        // txtFieldPhone?.setFlag(countryCode: .US)  // Default to US if the region code is invalid or missing
                    }
                    
                    // Set the phone number in the text field
                    //txtFieldPhone?.set(phoneNumber: phoneNumber)
                    
                } catch {
                    print("Error parsing phone number: \(error)")
                    
                    showAlert(message: error.localizedDescription)
                }
            }
        }
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
                    let isSuccess = KeychainManager.shared.save(key: "WinkTag", value: userResponse.winkTag ?? "")
                    
                    if(isSuccess){
                        print("winkTag Saved")
                        //UserDefaults.standard.set(userResponse.winkTag ?? "", forKey: "WinkTag")
                       // UserDefaults.standard.set(userResponse.winkTag ?? "", forKey: "WinkTag")
                        UserDefaults.standard.set(userResponse.firstName, forKey: "UserName")
                       // UserDefaults.standard.set(true, forKey: "wink_login")
                        KeychainManager.shared.saveBool(key: "wink_login", value:true)

                        NotificationCenter.default.post(name: Notification.Name("winkTag Saved"), object: nil, userInfo: nil)
//                        let isSuccess = KeychainManager.shared.save(key: "WinkTag", value: userResponse.winkTag ?? "")
//                        if isSuccess{
//
//                            self.delegate?.didReceiveWinkTag(userResponse.winkTag ?? "") // Pass the string to the delegate
//                        }
                        // self.fetchUser(winkTagStr: userResponse.winkTag ?? "")
                        // popBackToRootAndSendData(winkTag: userDetails?.winkTag ?? "")
                    }
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
        //UserDefaults.standard.set(true, forKey: "wink_login")
        KeychainManager.shared.saveBool(key: "wink_login", value:true)

        self.navigationController?.pushViewController(OktaLoginVC, animated: true)
    }
    
    func goToProfile(){
        
        let profileVC = StoryBoards.main.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        // profileVC.oktaOidc = try? OktaOidc(configuration: config)
        //profileVC.userDetails = self.userDetails
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}

extension EnrollmentVC: enrollModelDelegate{
    func didGetEmailCheckResponse(response: ImageDetailResponseModel) {
        
    }
    
    func didGetContactCheckResponse(response: ImageDetailResponseModel) {
        
    }
    
    func didGetCreateUserResponse(response: EnrollmntModel) {
        LoaderManager.shared.hideLoader()
        //self.navigationController?.popViewController(animated: true)
        
        // Show success message
        let message = updateUser ? "User updated successfully" : "User Created successfully"
        showAlert(message: message, shouldPop: true)
        
        // Pop to the specific view controller
        
        //self.getUser()
    }
    
    func showError(error: String) {
        LoaderManager.shared.hideLoader()
    }
}

extension EnrollmentVC : UIGestureRecognizerDelegate{
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Prevent gesture recognizer from being triggered if the touch is on the button
        if touch.view is UIButton {
            return false
        } else if touch.view is UIControl {
            return false
        }
        return true
    }
}

extension EnrollmentVC: FPNTextFieldDelegate {
    
    /// The place to present/push the listController if you choosen displayMode = .list
    func fpnDisplayCountryList() {
        let pickerNavigationController = UINavigationController(rootViewController: picker)
        self.present(pickerNavigationController, animated: true, completion: nil)
    }
    
    /// Lets you know when a country is selected
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
        print(name, dialCode, code)
        dialCodeVal = dialCode
        txtFieldPhone?.text = userPhoneNo
        print("dsds \((txtFieldPhone?.text ?? ""))")
        // txtFieldPhone?.set(phoneNumber:((txtFieldPhone?.text ?? userDetails?.contactNo) ?? ""))
        
        // Output "France", "+33", "FR"
    }
    
    /// Lets you know when the phone number is valid or not. Once a phone number is valid, you can get it in severals formats (E164, International, National, RFC3966)
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if isValid {
            // Do something...
            let formattedE164 = textField.getFormattedPhoneNumber(format: .E164)        // Output: "+33600000001"
            let formattedInternational = textField.getFormattedPhoneNumber(format: .International) // Output: "+33 6 00 00 00 01"
            let formattedNational = textField.getFormattedPhoneNumber(format: .National) // Output: "06 00 00 00 01"
            let formattedRFC3966 = textField.getFormattedPhoneNumber(format: .RFC3966)  // Output: "tel:+33-6-00-00-00-01"
            let rawPhoneNumber = textField.getRawPhoneNumber()                         // Output: "600000001"
            
        } else {
            // Handle invalid phone number
        }
    }
}

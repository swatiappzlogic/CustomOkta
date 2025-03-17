//
//  Helper.swift
//  WinkApp
//
//  Created by MacBook on 20/12/24.
//

import UIKit

class Helper: NSObject {

    static func showAlert(on viewController: UIViewController, title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func convertToDateFormatWithTime(inputDate: String) -> String? {
        // Step 1: Check for empty or nil input
        guard !inputDate.isEmpty else {
            print("Input date is empty.")
            return nil
        }
        
        // Step 2: Create the input date formatter (for "MM/dd/yyyy")
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM/dd/yyyy" // Input format: "12/26/2024"
        
        // Step 3: Parse the input string to Date
        guard let date = inputFormatter.date(from: inputDate) else {
            print("Invalid date format")
            return nil
        }
        
        // Step 4: Create the output date formatter (for "yyyy-MM-dd'T'HH:mm:ss")
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // Output format: "2024-12-26T00:00:00"
        
        // Step 5: Format the Date to the desired output string
        let formattedDate = outputFormatter.string(from: date)
        return formattedDate
    }

    
    static func convertToDateFormatWithoutTime(inputDate: String) -> String? {
        // Step 1: Create the input date formatter (for "yyyy-MM-dd'T'HH:mm:ss")
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // Input format: "2024-12-26T00:00:00"
        
        // Step 2: Parse the input string to Date
        guard let date = inputFormatter.date(from: inputDate) else {
            print("Invalid date format")
            return nil
        }
        
        // Step 3: Create the output date formatter (for "MM/dd/yyyy")
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM/dd/yyyy" // Output format: "12/26/2024"
        
        // Step 4: Format the Date to the desired output string
        let formattedDate = outputFormatter.string(from: date)
        return formattedDate
    }
    
    static func convertToBirthDateFormat(inputDate: String) -> String? {
        // Step 1: Create the input date formatter (for "December 20, 2024")
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MMMM dd, yyyy" // Input format: "December 20, 2024"
        
        // Step 2: Parse the input string to Date
        guard let date = inputFormatter.date(from: inputDate) else {
            print("Invalid date format")
            return nil
        }
        
        // Step 3: Create the output date formatter (for "2009-09-09T00:00:00")
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM/dd/yyyy" // Output format: "2009-09-09T00:00:00"
        
        // Step 4: Format the Date to the desired output string
        let formattedDate = outputFormatter.string(from: date)
        return formattedDate
    }
    
    static func base64UrlDecode(_ base64Url: String) -> Data? {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        return Data(base64Encoded: base64)
    }
    
    static func generateBlobName() -> String {
        // Get the current date
        let currentDate = Date()

        // Create a DateFormatter to format the timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"  // Format: YearMonthDayHourMinuteSecondMillisecond
        
        // Get the timestamp as a string
        let timestamp = formatter.string(from: currentDate)

        // Combine the timestamp with the fixed string "ios"
        let blobName = "\(timestamp)_ios.jpg"  // You can replace `.jpg` with other image extensions if needed
        
        return blobName
    }
    
    static func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    static func getTopViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    static func showAlert(on viewController: UIViewController, title: String, message: String, completion: @escaping (Bool) -> Void) {
          let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
          
          // OK Action
          let okAction = UIAlertAction(title: "OK", style: .default) { _ in
              completion(true)  // User clicked OK
          }
          // Add actions to alert
          alert.addAction(okAction)
          //alert.addAction(cancelAction)
          
          // Present alert
          viewController.present(alert, animated: true, completion: nil)
      }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    static func saveUserInfo(userDetails: UserInfoResponse) {
        do {
            // Encode the object into Data
            let encoder = JSONEncoder()
            let data = try encoder.encode(userDetails)
            
            // Store the data in UserDefaults
            UserDefaults.standard.set(data, forKey: "user_details")
        } catch {
            print("Failed to encode user details: \(error)")
        }
    }
    
    static func loadUserInfo() -> UserInfoResponse? {
        // Retrieve the data from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: "user_details") {
            do {
                // Decode the data back into the UserInfoResponse object
                let decoder = JSONDecoder()
                let decodedUserDetails = try decoder.decode(UserInfoResponse.self, from: savedData)
                return decodedUserDetails
            } catch {
                print("Failed to decode user details: \(error)")
            }
        }
        return nil
    }
    
    static func decodeJWT(_ jwt: String) -> (createdDate: String?, expirationDate: String?) {
        let segments = jwt.split(separator: ".")
        guard segments.count > 1 else { return (nil, nil) }
        
        let payloadSegment = segments[1]
        guard let payloadData = base64UrlDecode(String(payloadSegment)) else {
            return (nil, nil)
        }
        
        // Decode the payload into a dictionary
        if let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            
            var createdDate: String? = nil
            var expirationDate: String? = nil
            
            // Extract the creation date ("iat") if available
            if let iat = payload["iat"] as? Double {
                let createdDateObj = Date(timeIntervalSince1970: iat)
                createdDate = formatDate(createdDateObj)
            }
            
            // Extract the expiration date ("exp") if available
            if let exp = payload["exp"] as? Double {
                let expirationDateObj = Date(timeIntervalSince1970: exp)
                expirationDate = formatDate(expirationDateObj)
            }
            
            return (createdDate, expirationDate)
        }
        
        return (nil, nil)
    }
    
    static func checkTokenValidity(_ jwt: String) -> Bool {
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

    
    static func logWithTime( message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        
        print("[\(timestamp)] \(message)")
    }
    
    static func encodeQueryValue(_ value: String) -> String {
        // Step 1: Replace any occurrences of "\u002B" with the actual plus sign "+"
        let valueWithPlus = value.replacingOccurrences(of: "\\u002B", with: "+")
        
        // Step 2: URL encode the string using addingPercentEncoding
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        
        // Percent-encode the string, preserving the allowed characters
        if let encodedValue = valueWithPlus.addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
            return encodedValue
        } else {
            return valueWithPlus
        }
    }

   
}

//
//  AuthService.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import Foundation
import UIKit


// Define a struct for the API response
struct APIResponse: Codable {
    let success: Bool
    let message: String?
    // Add any other fields you expect from the response
}

// Define a struct for the user response
// Define the Identity struct
struct Identity: Codable {
    let connection: String
    let user_id: String
    let provider: String
    let isSocial: Bool
}

// Define the AppMetadata struct
struct AppMetadata: Codable {
    let winkTag: String?
}

// Define the UserProfile struct
struct UserResponse: Codable {
    let user_id: String
    let email: String
    let picture: String
    let identities: [Identity]
    let name: String
    let nickname: String
    let updated_at: String
    let email_verified: Bool
    let created_at: String
    let app_metadata: AppMetadata? // Make app_metadata optional
}

// Define a struct for the request body
struct UserInfoRequest: Codable {
    let clientId: String
    let clientSecret: String
    let winkTag: String
}

// Define a struct for the response body
struct UserInfoResponse: Codable {
    var firstName: String
    var lastName: String
    var contactNo: String
    var email: String
    var winkTag: String
}
// Define a User struct to model the response data
struct User: Codable {
    let nickname: String
    let email: String
    let userId: String
    let email_verified:Bool
    let picture:String
    
    enum CodingKeys: String, CodingKey {
        case nickname, email,email_verified,picture
        case userId = "user_id"
    }
}
class AuthService {
    
    // Singleton instance
    static let shared = AuthService()
    
    private init() {}
    // Function to handle unauthorized errors and redirect to root view controller
    private func handleUnauthorizedError() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")

                window.rootViewController = storyboard?.instantiateInitialViewController()
                window.makeKeyAndVisible()
            }
        }
    }
    
    func loginUser(username: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let url = URL(string: Okta.baseURL + "oauth/token")!
        
        // Prepare the request body
        let body: [String: Any] = [
            "client_id": Okta.clientId,
            "client_secret": Okta.clientSecret,
            "audience": Okta.audience,
            "grant_type": "password",
            "username": username,
            "password": password,
            "scope": "openid"
        ]
        
        // Convert the body dictionary to x-www-form-urlencoded format
        var components = URLComponents()
        components.queryItems = body.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        let bodyString = components.percentEncodedQuery ?? ""
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            // Log the response body for debugging
            if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                print("Response Body: \(jsonString)")
            }
            
            // Handle unsuccessful status codes (4xx, 5xx)
            guard (200...299).contains(httpResponse.statusCode) else {
                // Parse the error description from the response
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorDescription = jsonResponse["error_description"] as? String {
                    
                    // Show the specific error message in an alert
                    DispatchQueue.main.async {
                        
                        if let viewController = Helper.getTopViewController(){
                            Helper.showAlert(on: viewController, title: "Login Failed", message: errorDescription)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        
                        if let viewController = Helper.getTopViewController(){
                            Helper.showAlert(on: viewController, title: "Login Failed", message: "An unknown error occurred.")
                        }
                    }
                }
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            // If successful, parse the response to extract access_token and other fields
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            // Parse the response to extract access_token and other fields
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let accessToken = jsonResponse["access_token"] as? String {
                    do {
                        try KeychainManager.shared.saveToken(accessToken, forKey: "access_token")
                    } catch let error {
                        print("Failed to save token: \(error)")
                        // Handle the error appropriately (e.g., show an alert or log it)
                    }
                    
                    //UserDefaults.standard.set(accessToken, forKey: "access_token")
                }
                completion(.success(jsonResponse))
            } else {
                completion(.failure(URLError(.cannotParseResponse)))
            }
        }
        
        task.resume()
    }
    
    func fetchUserByWinkTag(winkTag: String, completion: @escaping (Result<[User], Error>) -> Void) {
        // Construct the URL with the dynamic winkTag
        
        //let winkTagtemp = ";dev-sdpavge\u{002B}-v"

        var encodedWinkTag = winkTag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        //encodedWinkTag = encodedWinkTag
            //.replacingOccurrences(of: "+", with: "%2B")
        
        encodedWinkTag = Helper.encodeQueryValue(encodedWinkTag)
        
        let quotedTag = "\"\(encodedWinkTag)\""
        
        var urlString = "\(Okta.baseURL)api/v2/users?q=user_metadata.winkTag:\(encodedWinkTag)&search_engine=v3"
        
        if UIDevice.current.name != "iPhone"{
            urlString = "\(Okta.baseURL)api/v2/users?q=user_metadata.winkTag:\(encodedWinkTag)&search_engine=v3"
        } else{
            urlString = "\(Okta.baseURL)api/v2/users?q=user_metadata.winkTag:\(quotedTag)&search_engine=v3"
        }
        
        
        print("URL to get user detail from WinkTag:\(urlString)")
        //let accessToken = UserDefaults.standard.string(forKey: "access_token") ?? ""
        
        guard let accessToken = KeychainManager.shared.getToken(forKey: "access_token") else {
            print("No token found for the given key.")
            return // You might want to exit the function if the token is not found
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            NotificationCenter.default.post(name: Notification.Name("Invalid URL"), object: nil, userInfo: nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set the Authorization header with your Auth0 token
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // Replace with your actual access token
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("fetchUserByWinkTag Response: \(jsonString)")
            }
            
            do {
                // Parse the JSON response into User objects
                let users = try JSONDecoder().decode([User].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // First API: Get the access token
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        
        let url = URL(string: "\(Okta.baseURL)oauth/token")!
        
        // Prepare the request body
        let body: [String: Any] = [
            "client_id": Okta.clientId,
            "client_secret": Okta.clientSecret,
            "audience": Okta.audience,
            "grant_type": "client_credentials",
            "scope": "create:users"
        ]
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorizedError()
                }
                completion(false)
                return
            }
            guard let data = data else {
                completion(false)
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Authenticate Response: \(jsonString)")
            }
            
            // Parse the response to extract access_token
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = jsonResponse["access_token"] as? String {
                
                // Store the access token in UserDefaults
                //UserDefaults.standard.set(accessToken, forKey: "access_token")
                
                do {
                    try KeychainManager.shared.saveToken(accessToken, forKey: "access_token")
                } catch let error {
                    print("Failed to save token: \(error)")
                    // Handle the error appropriately (e.g., show an alert or log it)
                }
                
                // Proceed with the next API call
                completion(true)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    
    
    func addSecondaryAccountIdentity(
        primaryAccountUserID: String,
        provider: String,
        userID: String,
        connectionID: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        // Retrieve the access token from UserDefaults
        //let accessToken = UserDefaults.standard.string(forKey: "access_token") ?? ""
        
        guard let accessToken = KeychainManager.shared.getToken(forKey: "access_token") else {
            print("No token found for the given key.")
            return // You might want to exit the function if the token is not found
        }
        
        let array_of_userid = primaryAccountUserID.components(separatedBy: "|")
        // Construct the URL
        guard let url = URL(string: "\(Okta.baseURL)api/v2/users/\(primaryAccountUserID)") else {
            print("Invalid URL.")
            completion(false)
            return
        }
        
        //let winkTagtemp = ";dev-sdpavge\u{002B}-v"

        var encodedUserID = Helper.encodeQueryValue(userID)
        
        // Create the request body
        var requestBody: [String: Any] = [
            "user_metadata": [
                "winkTag": encodedUserID // Store your winkTag here
            ]
        ]
        
        // Prepare the request
        var request = URLRequest(url: url)
        print("URL For linking is:\(url)")
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Convert the request body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            // Ensure we received a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorizedError()
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Server error: \(statusCode)")
                completion(false)
                return
            }
            
            // Decode the response data
            if let data = data {
                do {
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("addd account Response: \(jsonString)")
                    }
                    
                    completion(true)
                } catch {
                    print("Error parsing response: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                print("No data received.")
                completion(false)
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    // Function to fetch user details based on a query
    func fetchUserDetails(query: String, completion: @escaping ([UserResponse]?, Bool) -> Void) {
        // Retrieve the access token from UserDefaults
        //let accessToken = UserDefaults.standard.string(forKey: "access_token") ?? ""
        
        guard let accessToken = KeychainManager.shared.getToken(forKey: "access_token") else {
            print("No token found for the given key.")
            return // You might want to exit the function if the token is not found
        }
        
        // Construct the URL
        guard let url = URL(string: "\(Okta.baseURL)/api/v2/users?q=\(query)") else {
            print("Invalid URL.")
            completion(nil, false)
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil, false)
                return
            }
            
            // Ensure we received a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                
                completion(nil, false)
                return
            }
            
            // Decode the response data
            if let data = data {
                do {
                    let userResponses = try JSONDecoder().decode([UserResponse].self, from: data)
                    print("User details retrieved: \(userResponses)")
                    completion(userResponses, true)
                } catch {
                    print("Error parsing response: \(error.localizedDescription)")
                    completion(nil, false)
                }
            } else {
                print("No data received.")
                completion(nil, false)
            }
        }
        
        // Start the network request
        task.resume()
    }
}



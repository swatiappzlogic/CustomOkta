//
//  ProfileViewModel.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var userDetails:UserInfoResponse?
    
    func fetchUserProfile() {
        // let accessToken = UserDefaults.standard.string(forKey: "access_token") ?? ""
        
        guard let accessToken = KeychainManager.shared.getToken(forKey: "access_token") else {
            print("No token found for the given key.")
            return // You might want to exit the function if the token is not found
        }
        
        print("Access_token:\(accessToken)")
        
        AuthService.shared.fetchUserByWinkTag(winkTag: KeychainManager.shared.retrieve(key: "WinkTag") ?? "") { result in
            switch result {
            case .success(let users):
                if users.isEmpty {
                    DispatchQueue.main.async{
                        self.isLoading = false
                    }
                } else {
                    for user in users {
                        print("Nickname: \(user.nickname), Email: \(user.email), User ID: \(user.userId)")
                        self.fetchUserDetails(email: user.email, accessToken:accessToken)
                    }
                }
            case .failure(let error):
                print("Error fetching user: \(error.localizedDescription)")
            }
        }
        
    }
    
    func fetchUserDetails(email:String, accessToken:String){
        let url = URL(string: "\(Okta.baseURL)api/v2/users?q=\(email)")!
        print("profile_URL:\(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Profile Response: \(jsonString)")
                }
                
                do {
                    // Decode as an array of UserProfiles
                    let userProfiles = try JSONDecoder().decode([UserProfile].self, from: data)
                    
                    // Assuming you want the first user profile from the array
                    if let firstProfile = userProfiles.first {
                        self.userProfile = firstProfile
                    } else {
                        self.errorMessage = "No user profile found"
                    }
                } catch {
                    self.errorMessage = "Failed to decode user profile"
                }
            }
        }.resume()
    }
}

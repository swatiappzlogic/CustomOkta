//
//  ProfileView.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var createdTime: String = "N/A"
    @State private var expirationTime: String = "N/A"
    @State private var iPQsId: String = ""
    @State private var fingerPrintId: String = ""
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    .scaleEffect(1.5) // Increase size of the progress indicator
            } else if let profile = viewModel.userProfile {
                VStack {
                    // Profile Picture
                    let url = URL(string: profile.picture)
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 4)) // Border around image
                    } placeholder: {
                        // Placeholder Image
                        Image(systemName: "person.crop.circle") // Make sure this image exists in your assets
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 4)) // Border around placeholder
                    }
                    .frame(width: 120, height: 120) // Increased size for better visibility
                    
                    // User Info Card
                    VStack(alignment: .leading) {
                        Text("ID: \(profile.user_id)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Name: \(profile.name)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Nickname: \(profile.nickname)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Email: \(profile.email)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        
                        if let accessToken = KeychainManager.shared.getToken(forKey: "access_token") {
                            Text("Access Token: \(accessToken)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                        } else {
                            
                        }
                        
                        Text("Email Verified: \(profile.email_verified ? "Yes" : "No")")
                            .font(.subheadline)
                            .foregroundColor(profile.email_verified ? Color.green : Color.red)
                        
                        Text("Token Created Time: \(createdTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Token Exp Time: \(expirationTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("iPQs Id: \(iPQsId)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
//                        Text("Fingerprint Id: \(iPQsId)")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
                        
                    }
                    .padding()
                    .background(Color.white) // Card background color
                    .cornerRadius(12) // Rounded corners
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Shadow effect
                }
                .padding(.top)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        //.padding(5)
        .background(Color(UIColor.systemGroupedBackground)) // Background color
        .navigationTitle("Profile") // Navigation title
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // your code here
                viewModel.fetchUserProfile()
            }
            
            if let savedValue = KeychainManager.shared.retrieve(key: "iPQSId") {
                print("Retrieved iPQsId from Keychain: \(savedValue)") // Debugging print
                self.iPQsId = savedValue // Update the state with the value from Keychain
            } else {
                print("No iPQsId found in Keychain.")
            }
            
            
            if let savedValue = KeychainManager.shared.retrieve(key: "FingerPrintIdId") {
                print("Retrieved FingerPrintId from Keychain: \(savedValue)") // Debugging print
                //self.iPQsId = savedValue // Update the state with the value from Keychain
            } else {
                print("No FingerPrintId found in Keychain.")
            }
            
            //            if let token = UserDefaults.standard.string(forKey: "access_token") {
            //                //  self.accessToken = token
            //                decodeJWT(token)
            //            }
            
            if let token = KeychainManager.shared.getToken(forKey: "access_token") {
                //self.accessToken = token
                decodeJWT(token)
            }
        }
    }
    private func decodeJWT(_ jwt: String) {
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
            }
            
            //            if let emailVerified = payload["email_verified"] as? Bool {
            //                isEmailVerified = emailVerified
            //            }
        }
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProfileViewModel()
        
        // Set some test data for preview, including all required fields
        viewModel.userProfile = UserProfile(
            user_id: "auth0|66ffc27926e97f2955a73bbd",
            name: "test@test.com",
            email_verified: false,
            nickname: "test",
            picture: "https://s.gravatar.com/avatar/b642b4217b34b1e8d3bd915fc65c4452?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fte.png",
            email: "test@test.com",
            created_at: "2024-10-17T08:50:01.401Z", // Provide a sample value for created_at
            identities: [ // Provide a sample value for identities
                UserProfile.Identity(
                    connection: "Username-Password-Authentication",
                    user_id: "66ffc27926e97f2955a73bbd",
                    provider: "auth0",
                    isSocial: false
                )
                        ]
        )
        
        return ProfileView(viewModel: viewModel)
    }
}

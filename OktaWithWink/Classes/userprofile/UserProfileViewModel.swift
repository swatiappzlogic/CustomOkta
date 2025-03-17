//
//  UserProfileViewModel.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import Foundation
import Combine

class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    
    init() {
        // Sample data (you can replace it with API call to fetch real user data)
        self.userProfile = UserProfile(
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
    }
}

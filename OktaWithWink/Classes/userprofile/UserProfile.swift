//
//  UserProfile.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/16/24.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String { user_id }
    let user_id: String
    let name: String
    let email_verified: Bool
    let nickname: String
    let picture: String
    let email: String
    let created_at: String?
    let identities: [Identity] // Add this line to include identities

    // Nested struct for identities
    struct Identity: Codable {
        let connection: String
        let user_id: String
        let provider: String
        let isSocial: Bool
    }
}


//
//  JWTClaims.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/22/24.
//

import Foundation

// Define a struct for JWT claims
struct JWTClaims: Codable {
    let nickname: String?
    let name: String
    let picture: String?
    let updated_at: String?
    let email: String?
    let email_verified: Bool?
    let iss: String?
    let aud: String?
    let iat: TimeInterval?
    let exp: TimeInterval?
    let sub: String?
    let nonce:String?
}

class JWTService {
    
    // Singleton instance
    static let shared = JWTService()
    
    private init() {}
    
    func decodeJWT(token: String) -> JWTClaims? {
        let segments = token.split(separator: ".")
        
        // Ensure there are exactly three segments in the JWT
        guard segments.count == 3 else {
            print("Invalid JWT format. Expected 3 segments.")
            return nil
        }

        // Decode the payload (the second segment)
        var payloadData: Data?
        
        // Replace URL-safe characters for base64 decoding
        let payloadSegment = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        print("Payload segment: \(payloadSegment)")
        
        // Add padding if necessary
        let paddingLength = 4 - (payloadSegment.count % 4)
        let paddedPayloadSegment = paddingLength < 4 ? payloadSegment + String(repeating: "=", count: paddingLength) : payloadSegment
        
        guard let data = Data(base64Encoded: paddedPayloadSegment) else {
            print("Failed to decode base64 or payload is missing.")
            return nil
        }

        print("Decoded data: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")")

        do {
            // Parse JSON into JWTClaims struct
            let claims = try JSONDecoder().decode(JWTClaims.self, from: data)
            return claims
        } catch {
            print("Error decoding JWT: \(error.localizedDescription)")
            return nil
        }
    }

    
    // Function to check if the token is expired
    func isTokenExpired(token: String) -> Bool {
        guard let payload = decodeJWT(token: token),
              let exp = payload.exp as? TimeInterval else {
            return true // Default to expired if decoding fails
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        return expirationDate < Date() // Check if expired
    }
}

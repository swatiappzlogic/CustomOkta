//
//  FaceDetectionModel.swift
//  WinkApp
//
//  Created by MacBook on 06/12/24.
//

import UIKit

struct UserModel: Decodable {
        
        let winkToken: String?
        let qcToken: String?
        let palmId: String?
        let firstName: String?
        let lastName: String?
        let contactNo: String?
        let email: String?
        let dateOfBirth: String?
        let winkTag: String?
        let createdAt: String?
        let updateAt: String?
        let createdBy: String?
}


struct ImageDetailResponseModel: Decodable {
    let videoProcessingResult: String?
    let winkSeed: String?
    let clientToken: String?
    let profileCompletionStatus: Double?
    let livenessPass: Bool?
    let livenessRealScore: Double?
    let createdAt: String?
    let createdBy: String?
    
    enum CodingKeys: String, CodingKey {
            case videoProcessingResult = "videoProcessingResult"
            case winkSeed
            case clientToken
            case profileCompletionStatus
            case livenessPass
            case livenessRealScore
            case createdAt
            case createdBy
        }
}

struct SessionResponse: Decodable {
    let deviceFlag: Bool
    let jwtSessionToken: String
}

struct UploadResponseModel: Decodable {
    let videoId: String?
    let createdAt: String?
    let createdBy: String?
}

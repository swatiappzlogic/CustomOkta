//
//  LoginModel.swift
//  WinkApp
//
//  Created by MacBook on 31/12/24.
//

import UIKit

struct LoginModel: Decodable {
    let access_token: String
    let token_type:String
    let scope:String
    let expires_in: Int
}

// Define the root structure
struct LoginResponse: Decodable {
    let data: LoginModel?
}

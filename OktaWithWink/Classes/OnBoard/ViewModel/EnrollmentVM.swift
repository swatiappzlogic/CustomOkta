//
//  RegisterVM.swift
//  WinkApp
//
//  Created by MacBook on 19/12/24.
//

import UIKit
import Alamofire


protocol enrollModelDelegate: AnyObject {
    func didGetCreateUserResponse(response: EnrollmntModel)
    func didGetEmailCheckResponse(response: ImageDetailResponseModel)
    func didGetContactCheckResponse(response: ImageDetailResponseModel)

    func showError(error: String)
}

class EnrollmentVM: NSObject {

    var errorMessage: String? = nil
    var delegate: enrollModelDelegate?
    
    func createUserOnServer(dict:NSDictionary){
        
        // API Endpoint
        let url = WebURL.baseURL + WebURL.getProfileURL
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
        ]
        
        // Parameters
        let parameters = ["clientToken":dict.value(forKey: "clientToken") ?? "",
                      "qCToken":dict.value(forKey: "qCToken") ?? "",
                      "firstName":dict.value(forKey: "firstName") ?? "",
                      "lastName":dict.value(forKey: "lastName") ?? "",
                      "contactNo":dict.value(forKey: "contactNo") ?? "" ,
                      "email":dict.value(forKey: "email") ?? "",
                      "dateOfBirth":dict.value(forKey: "dateOfBirth") ?? "",
                      "PalmId":dict.value(forKey: "PalmId") ?? "" ] as [String : Any]
        
      
        NetworkManager.shared.post(url: url, parameters: parameters, headers: headers) { (result: Result<EnrollmntModel, NetworkError>) in
            switch result {
            case .success(let userResponse):
                DispatchQueue.main.async {
                    self.delegate?.didGetCreateUserResponse(response: userResponse)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.showError(error: error.localizedDescription)
                }
            }
        }
    }
    
    func checkEmail(email: String, winkTag: String, token : String){
        
        // API Endpoint
        let url = WebURL.baseURL + WebURL.checkEmailURL
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
            "Authorization": "Bearer \(token)",
        ]
        
        // Parameters
        let parameters: [String: Any] = [
            "clientId": ClientDetails.clientId,
            "clientSecret": ClientDetails.clientSecret,
            "WinkTag": winkTag,
            "Email": email,
        ]
        
        NetworkManager.shared.get(url: url, parameters: parameters, headers: headers) { (result: Result<ImageDetailResponseModel, NetworkError>) in
            switch result {
            case .success(let userResponse):
                DispatchQueue.main.async {
                    // Update UI with fetched data
                    self.delegate?.didGetEmailCheckResponse(response : userResponse)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Show error to user
                    self.delegate?.showError(error: error.localizedDescription)
                }
            }
        }
    }
}

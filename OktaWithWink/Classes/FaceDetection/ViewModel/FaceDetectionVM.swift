//
//  FaceDetectionVM.swift
//  WinkApp
//
//  Created by MacBook on 05/12/24.
//

import UIKit
import Alamofire

protocol UploadImageDelegate: AnyObject {
    func didGetImageDetailResponse(response: ImageDetailResponseModel)
    func showError(error: String, pop :Bool)
    func didUploadImageSuccessfully(response: UploadResponseModel)
    func didFailToUploadImage(error: String )
}

// MARK: -

class FaceDetectionVM: NSObject {
    
    var sessionResponse: SessionResponse? = nil
    var errorMessage: String? = nil
    var delegate: UploadImageDelegate?
    
    
    // MARK: -
    
    func uploadImageToServer(image: UIImage, devicToken: String, videoTypeFlag: String, completion: @escaping (Result<UploadResponseModel, NetworkError>) -> Void) {
        
        // API Endpoint
        let url = WebURL.baseURL + WebURL.enrollmentURL
        
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
        ]
        
        // Parameters
        let parameters: [String: String] = [
            "deviceToken": devicToken,
            "videoTypeFlag": videoTypeFlag
        ]
        
        var scaleFactor = 0.9
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scaleFactor = 0.6
        }
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: scaleFactor) else {
            print("Failed to convert UIImage to Data")
            return
        }
        
        NetworkManager.shared.uploadMultipart(
            url: url,
            headers: headers,
            parameters: parameters,
            imageData: imageData,
            imageKey: "video",
            fileName: "image.jpg"
        ) { [weak self] (result: Result<UploadResponseModel, NetworkError>) in
            switch result {
            case .success(let response):
                self?.delegate?.didUploadImageSuccessfully(response: response)
            case .failure(let error):
                self?.delegate?.didFailToUploadImage(error: error.localizedDescription)
            }
        }
    }
    
    func getImageDetailFromServer(videoId:String, livenessActive: String){
        
        // API Endpoint
        let url = WebURL.baseURL + WebURL.enrollmentURL
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
        ]
        
        // Parameters
        let parameters: [String: Any] = [
            "livenessActive": livenessActive,
            "videoId": videoId,
            "deviceId": KeychainManager.shared.retrieve(key: "iPQSId") ?? ""
        ]
        
        NetworkManager.shared.get(url: url, parameters: parameters, headers: headers) { (result: Result<ImageDetailResponseModel, NetworkError>) in
            switch result {
            case .success(let userResponse):
                DispatchQueue.main.async {
                    // Update UI with fetched data
                    self.delegate?.didGetImageDetailResponse(response : userResponse)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Show error to user
                    self.delegate?.showError(error: error.localizedDescription, pop: false)
                }
            }
        }
    }
    
    func uploadImageToAzureBlob(imageData: Data, containerName: String, storageAccountName: String, sasToken: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
           
           // Generate a unique blob name with timestamp + fixed string
        let blobName = Helper.generateBlobName()

           // Build the URL for Azure Blob Storage with the SAS Token
           let urlString = "https://\(storageAccountName).blob.core.windows.net/\(containerName)/\(blobName)?\(sasToken)"
           guard let url = URL(string: urlString) else {
               print("Invalid URL")
               completion(.failure(.unknownError(NSError(domain: "Invalid URL", code: -1, userInfo: nil))))
               return
           }

           // Use the NetworkManager to upload the image
           NetworkManager.shared.uploadImageToAzureBlobRequest(imageData: imageData, url: url) { result in
               switch result {
               case .success:
                   print("Image uploaded successfully to Azure Blob Storage.")
                   completion(.success(true))
               case .failure(let error):
                   completion(.failure(error))
               }
           }
       }
    
    func getUser(winkSeed: String, showOkta :Bool){
        
        let url = WebURL.baseURL + WebURL.getProfileURL
        // Headersx
        let headers: HTTPHeaders = [
            "clientId": ClientDetails.clientId,
            "Authorization": "Bearer \(winkSeed)",
        ]
        print("Request URL for get User : \(url)")
        print("Request Headers : \(headers)")

        NetworkManager.shared.get(url: url, parameters: nil, headers: headers) { (result: Result<UserModel, NetworkError>) in
            LoaderManager.shared.hideLoader()
            switch result {
                
            case .success(let userResponse):
                DispatchQueue.main.async { [self] in
                    let isSuccess = KeychainManager.shared.save(key: "WinkTag", value: userResponse.winkTag ?? "")
                    
                    if(isSuccess){
                        print("winkTag Saved")
                       // UserDefaults.standard.set(userResponse.winkTag ?? "", forKey: "WinkTag")
                        UserDefaults.standard.set(userResponse.firstName, forKey: "UserName")
                        if !showOkta{
                            NotificationCenter.default.post(name: Notification.Name("winkTag Saved"), object: nil, userInfo: nil)
                        } else{
                            NotificationCenter.default.post(name: Notification.Name("confirmOkta"), object: nil, userInfo: nil)

                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let networkError = error as? NetworkError {
                        print("Error Code: \(networkError)")
                    }
                    print("Error Details: \(error.localizedDescription)")
                    print("Full Error: \(error)")
                    self.delegate?.showError(error: error.localizedDescription, pop: true)

                }
            }
        }
    }
       
}


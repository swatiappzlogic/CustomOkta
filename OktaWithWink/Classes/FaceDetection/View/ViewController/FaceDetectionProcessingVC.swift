//
//  FaceDetectionProcessingVC.swift
//  WinkApp
//
//  Created by MacBook on 10/01/25.
//

import UIKit
import Alamofire
import AVFoundation
import Vision

protocol FaceProcessingDelegate: AnyObject {
    func didUpdateEnrollmentStatus(isEnrolled: Bool)
}

class FaceDetectionProcessingVC: UIViewController {
    
    private let faceDetectModel = FaceDetectionVM()
    weak var delegate: FaceVCDelegate?
    var capturedImage: UIImage!
    var isEnrolled = true
    var stopCapturing = false
    var winkSeed: String = ""
    weak var faceDelegate: FaceProcessingDelegate?
    
    @IBOutlet weak var imgViewFace: UIImageView!
    
    // MARK: - ViewLifeCycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceDetectModel.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        faceCenterImage(capturedImage)
        stopCapturing = false
        Helper.logWithTime(message: "Proceesing screen visible")
    }
    
    // MARK: - Helper Method
    
    func uploadCroppedImage(){
        guard let image = imgViewFace.image ?? UIImage(named: "") else {
            // Handle error, e.g. return or show alert
            print("No image available")
            return
        }
        uploadImage(image)
    }
    
    func faceCenterImage(_ image: UIImage) {
        guard let uncroppedCgImage = image.cgImage else {
            imgViewFace.image = image
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            uncroppedCgImage.faceCrop { [weak self] result in
                switch result {
                case .success(let cgImage):
                    DispatchQueue.main.async {
                        let flippedImage = UIImage(cgImage: cgImage, scale: self?.capturedImage.scale ?? 1.0, orientation: .leftMirrored)
                        self?.imgViewFace.image = flippedImage
                        self?.uploadCroppedImage()
                    }
                case .notFound, .failure(_):
                    DispatchQueue.main.async {
                        self?.imgViewFace.image = image
                    }
                }
            }
        }
    }
    
    private func decodeJWT(_ jwt: String) {
        let segments = jwt.split(separator: ".")
        guard segments.count > 1 else { return }
        
        let payloadSegment = segments[1]
        let payloadData = Helper.base64UrlDecode(String(payloadSegment))
        
        if let payloadData = payloadData,
           let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            
        }
    }
    
    // MARK: - Network Method
    func getUser( showOkta: Bool){
        
        LoaderManager.shared.showLoader(in: view)
        
        winkSeed = winkSeed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        decodeJWT(winkSeed)
        
        if winkSeed.hasSuffix("\\") {
            winkSeed = String(winkSeed.dropLast()
            )
        }
        
        faceDetectModel.getUser(winkSeed: winkSeed, showOkta: showOkta)
    }
    
    func uploadImage(_ image: UIImage) {
        
        Helper.logWithTime(message: "Image upload started")
        
        if (!stopCapturing){
            DispatchQueue.main.async {
                LoaderManager.shared.showLoader(in: self.view)
            }
            
            if isEnrolled{
                
                faceDetectModel.uploadImageToServer(
                    image: image,
                    devicToken: ClientDetails.devicToken,
                    videoTypeFlag: VideoTypeFlag.login
                ) { result in
                    switch result {
                    case .success(let response):
                        print("Image uploaded successfully: \(response)")
                        Helper.logWithTime(message: "Image upload successfully")
                        
                    case .failure(let error):
                        print("Image upload failed: \(error)")
                        LoaderManager.shared.hideLoader()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
            } else{
                faceDetectModel.uploadImageToServer(
                    image: image,
                    devicToken: ClientDetails.enrollmntDevicToken,
                    videoTypeFlag: VideoTypeFlag.enrollment
                ) { result in
                    switch result {
                    case .success(let response):
                        print("Image uploaded successfully: \(response)")
                    case .failure(let error):
                        print("Image upload failed: \(error)")
                        LoaderManager.shared.hideLoader()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func uploadImageToAzure() {
        // Check if globalImage exists
        guard let image = imgViewFace.image else {
            print("No image to upload.")
            return
        }
        
        // Convert UIImage to Data (you can use JPEG or PNG format)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data.")
            return
        }
        
        let storageAccountName = Azure.storageAccountName
        let containerName = Azure.containerName
        let sasToken = Azure.sasToken
        
        // Call the upload function with the image data
        faceDetectModel.uploadImageToAzureBlob(imageData: imageData,
                                               containerName: containerName,
                                               storageAccountName: storageAccountName,
                                               sasToken: sasToken) { result in
            switch result {
            case .success(let isUploaded):
                if isUploaded {
                    print("Image successfully uploaded.")
                    self.navigationController?.popViewController(animated: true)
                } else {
                    print("Image upload failed.")
                }
            case .failure(let error):
                print("Failed to upload image: \(error)")
            }
        }
    }
    
}

// MARK: - UploadImageDelegate

extension FaceDetectionProcessingVC: UploadImageDelegate {
    
    func showError(error: String, pop: Bool){
        LoaderManager.shared.hideLoader()
        
        if (pop){
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func didGetImageDetailResponse(response: ImageDetailResponseModel) {
        LoaderManager.shared.hideLoader()
        
        print("Enrollment Response  \(response)")
        Helper.logWithTime(message: "Enrollment Response  received")
        
        if (response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.successLogin  && response.profileCompletionStatus == 1 && response.livenessPass  == true) || (response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.successLogin  && response.profileCompletionStatus == 1 && response.livenessRealScore ?? 0.0 > 50.0)
        {
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let welcomeVC = storyboard?.instantiateViewController(withIdentifier: "WelcomeVC") as! WelcomeVC
            welcomeVC.winkSeed =  response.winkSeed ?? ""
            winkSeed = response.winkSeed ?? ""
            stopCapturing = true
            self.getUser(showOkta: false)
            return
        }
        
        else if response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.successLogin  && response.profileCompletionStatus == 0.6  && response.livenessPass  == true{
            isEnrolled = true
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let enrollVC = storyboard?.instantiateViewController(withIdentifier: "EnrollmentVC") as! EnrollmentVC
            enrollVC.clientToken = response.clientToken ?? ""
            enrollVC.delegate = delegate
            self.navigationController?.pushViewController(enrollVC, animated: true)
            //stopCaptureSession()
            return
        }
        
        else if response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.notEnrolled  {
            
            isEnrolled = false
            if (response.livenessPass == false && response.livenessRealScore == 0.0){
                self.navigationController?.popViewController(animated: true)
            }
            self.uploadImage(capturedImage)
            
        }
        else  if response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.existingAccount  && response.profileCompletionStatus == 0{
            
            isEnrolled = true
            self.uploadImage(capturedImage)
            self.navigationController?.popViewController(animated: true)
            
        }
        else  if response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.successEnrollment  && response.livenessPass  == true{
            
            isEnrolled = true
            faceDelegate?.didUpdateEnrollmentStatus(isEnrolled: isEnrolled)
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")

            let enrollVC = storyboard?.instantiateViewController(withIdentifier: "EnrollmentVC") as! EnrollmentVC
            enrollVC.clientToken = response.clientToken ?? ""
            self.navigationController?.pushViewController(enrollVC, animated: true)
            return
        }
        else  if response.videoProcessingResult?.trimmingCharacters(in: .whitespacesAndNewlines) == videoProcessingResult.failureTryAgain{
            
            winkSeed = response.winkSeed ?? ""
            stopCapturing = true
            self.getUser(showOkta: true)
            return
            
           // NotificationCenter.default.post(name: Notification.Name("winkTag Saved"), object: nil, userInfo: nil)
        }
        else if !(response.livenessPass ?? false && response.livenessRealScore ?? 50 < 50) {
            
            DispatchQueue.main.async {
                Helper.showAlert(on: self, title: "Retry", message: "Try to align the face within the frame, keep the light well lit and donot cover your face.") { userDidConfirm in
                    if userDidConfirm {
                        
                        self.navigationController?.popViewController(animated: true)
                        
                        // User clicked OK, so reset flags and upload the image
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            //self.resetFlags()
                        }
                    } else {
                        // User clicked Cancel, you can handle this case if necessary
                        print("User cancelled the retry.")
                    }
                }
                
                self.uploadImageToAzure()
                return
            }
        }
        else {
            DispatchQueue.main.async {
                Helper.showAlert(on: self, title: "Retry", message: "Please try again.") { userDidConfirm in
                    if userDidConfirm {
                        self.navigationController?.popViewController(animated: true)
                        
                    } else {
                        // User clicked Cancel, you can handle this case if necessary
                        print("User cancelled the retry.")
                    }
                }
            }
        }
    }
    
    func didUploadImageSuccessfully(response: UploadResponseModel) {
        print("Upload image response received")
        Helper.logWithTime(message: "Upload image response received")
        
        faceDetectModel.getImageDetailFromServer(videoId: response.videoId ?? "", livenessActive: "true")
    }
    
    func didFailToUploadImage(error: String) {
        LoaderManager.shared.hideLoader()
        
        DispatchQueue.main.async {
            Helper.showAlert(on: self, title: "Retry", message: "Please try again.") { userDidConfirm in
                if userDidConfirm {
                    self.navigationController?.popViewController(animated: true)
                    
                    // User clicked OK, so reset flags and upload the image
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        //self.resetFlags()
                    }
                } else {
                    // User clicked Cancel, you can handle this case if necessary
                    print("User cancelled the retry.")
                }
            }
        }
    }
}

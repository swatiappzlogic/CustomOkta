//
//  ViewController.swift
//  WinkApp
//
//  Created by MacBook on 28/11/24.
//

import UIKit

class OnboardVC: UIViewController {
    
    // MARK: - View LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        WebSocketManager.shared.delegate = self
//        WebSocketManager.shared.connect(to: "wss://dev-api.winklogin.com/ws_winkLoginEnrollment/SkLgTtMllh/true/true/winkwallet/?SessionId=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJGaXJzdE5hbWUiOiIiLCJMYXN0TmFtZSI6IiIsIldpbmtUYWciOiIiLCJuYmYiOjE3MzI3OTkxMzQsImV4cCI6MTczMjc5OTQzNCwiaWF0IjoxNzMyNzk5MTM0fQ.viX6WrigE4BHRPDKHyvcm-bSz7C4a5LcvHuirfImdY4")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //showSignUpPopup()
    }
    
    // MARK: - Custom Methods

    func openCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.cameraDevice = .front
        vc.delegate = self
        present(vc, animated: true)
    }
    
    
//    func showSignUpPopup() {
//        
//        // Check for iOS 13+ (using connectedScenes for multiple scenes)
//        if #available(iOS 13.0, *) {
//            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                if let window = windowScene.windows.first(where: { $0.isKeyWindow }),
//                   var topController = window.rootViewController {
//                    
//                    // Traverse presented view controllers to find the top-most one
//                    while let presentedViewController = topController.presentedViewController {
//                        topController = presentedViewController
//                    }
//                    
//                    // Instantiate the SignUpPopUpVC from the storyboard
//                    let signupPopupVC = StoryBoards.popup.instantiateViewController(withIdentifier: "SignUpPopUpVC") as! SignUpPopUpVC
//                    
//                    signupPopupVC.completion = { [weak self] resultCode in
//                        guard let self = self else { return }
//                        
//                        if resultCode == 200 {
//                            self.openCamera()
//                        }
//                    }
//                    signupPopupVC.modalPresentationStyle = .overCurrentContext
//                    signupPopupVC.modalTransitionStyle = .crossDissolve
//                    
//                    // Present the SignUpPopUpVC
//                    topController.present(signupPopupVC, animated: true, completion: nil)
//                }
//            }
//        } else {
//            // Fallback for earlier iOS versions (before iOS 13)
//            if var topController = UIApplication.shared.keyWindow?.rootViewController {
//                // Traverse presented view controllers to find the top-most one
//                while let presentedViewController = topController.presentedViewController {
//                    topController = presentedViewController
//                }
//                
//                // Instantiate the SignUpPopUpVC from the storyboard
//                let signupPopupVC = StoryBoards.popup.instantiateViewController(withIdentifier: "SignUpPopUpVC") as! SignUpPopUpVC
//                signupPopupVC.modalPresentationStyle = .overCurrentContext
//                signupPopupVC.modalTransitionStyle = .crossDissolve
//                
//                // Present the SignUpPopUpVC
//                topController.present(signupPopupVC, animated: true, completion: nil)
//            }
//        }
//    }
    
}

extension OnboardVC:  UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        // print out the image size as a test
        print(image.size)
    }
    
}

extension OnboardVC: WebSocketManagerDelegate{
    func webSocket(_ manager: WebSocketManager, didReceiveDebugMessage message: Message) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveSyncMessage message: Message) {
        
       
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveoAuthRequestIdMessage message: Message) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveExistingaccountMessage message: Message) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveTokenMessage message: Message) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveUnknownMessage message: Message) {
        
    }
    
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: String) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        
    }
    
    func webSocket(_ manager: WebSocketManager, didFailToReceiveMessageWithError error: any Error) {
        
    }
    
    func webSocketDidConnect(_ manager: WebSocketManager) {
        
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: (any Error)?) {
        
    }
    
    
}

//
//  PermissionHnadler.swift
//  WinkApp
//
//  Created by MacBook on 28/11/24.
//

import UIKit
import AVFoundation
import AVKit

class PermissionHelper {

    // Function to check and request both Camera and Microphone permissions
    static func requestCameraAndMicrophonePermission(viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // First, check if both permissions are already granted
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        
        // If both permissions are granted, call the completion handler immediately
        if cameraStatus == .authorized && microphoneStatus == .granted {
            completion(true)
            return
        }
        
        // Show a custom alert explaining why permissions are needed
        let alert = UIAlertController(
            title: "Permissions Required",
            message: "This app requires access to your camera and microphone to record video/audio.",
            preferredStyle: .alert
        )
        
        // Add "Grant Permissions" action to request permissions
        alert.addAction(UIAlertAction(title: "Grant Permissions", style: .default, handler: { _ in
            // Request Camera permission
            AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
                // Request Microphone permission
                AVAudioSession.sharedInstance().requestRecordPermission { microphoneGranted in
                    // Check if both permissions were granted
                    if cameraGranted && microphoneGranted {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }))
        
        // Add "Cancel" action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion(false)
        }))
        
        // Present the alert on the provided view controller
        viewController.present(alert, animated: true, completion: nil)
    }
}

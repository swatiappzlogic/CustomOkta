//
//  SDKManager.swift
//  Pods
//
//  Created by MacBook on 03/03/25.
//

import UIKit

public class SDKManager {
    
    private static var sharedInstance: SDKManager?
    
    // The SDK View Controller that will be added to the sample app's view
    private var sdkViewController: ViewController?
    
    private init() {
        // Initialization code (if any)
    }
    
    public static var shared: SDKManager {
        if sharedInstance == nil {
            sharedInstance = SDKManager()
        }
        return sharedInstance!
    }
    
    // Add the SDK view controller to the provided view controller
    public func addSDKViewController(to parentViewController: UIViewController) {
        print("sdk called")
        
        // Loading the image and storyboard (keeping this part as it is)
            //let temp = WinkSDKBundleManager.image(named: "downArrow")
        let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")

        // Instantiate the ViewController from the storyboard
        if let sdkViewController = storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            // Create a UINavigationController with the sdkViewController as the root
            let navigationController = UINavigationController(rootViewController: sdkViewController)
            
            // Add the navigationController as a child view controller
            parentViewController.addChild(navigationController)
            parentViewController.view.addSubview(navigationController.view)
            navigationController.didMove(toParent: parentViewController)
            
            // Set the navigationController's view frame to cover the entire screen of the parent view
            navigationController.view.frame = parentViewController.view.bounds
            navigationController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Handle appearance transitions
            navigationController.beginAppearanceTransition(true, animated: true)
            navigationController.endAppearanceTransition()
            
        } else {
            print("Failed to instantiate ViewController from storyboard")
        }

    }

}

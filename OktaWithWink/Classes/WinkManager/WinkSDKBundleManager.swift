//
//  WinkSDKBundleManager.swift
//  OktaWithWink_Example
//
//  Created by MacBook on 04/03/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
//import OktaOidc

class WinkSDKBundleManager {
    
    /// - Returns: Bundle
    public static func frameworkBundle() -> Bundle {
        let bundle = Bundle(for: SDKManager.self)
        return bundle
    }
    
    /// - Parameters:
    ///   - name: Resource Name
    ///   - ext: Resource Type
    /// - Returns: path
    public static func imageBundlePath(forResource name: String?, ofType ext: String?) -> String? {
        let bundle = frameworkBundle()
        let path = bundle.path(forResource: name, ofType: ext)
        return path
    }
    
    
    /// Resource picture
    ///
    /// - Parameter name: image name
    /// - Returns: image
    public static func image(named name: String) -> UIImage? {
        let mainBundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle")
        let bundleFullPath = mainBundlePath?.appending("/OktaWithWinkResources.bundle")
        
        if let bundlePath = bundleFullPath {
            let bundle = Bundle(path: bundlePath)
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return nil
    }
    
    public static func bundle(named name: String) -> Bundle? {
        let mainBundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle")
        let bundleFullPath = mainBundlePath?.appending("/OktaWithWinkResources.bundle")
        
        if let bundlePath = bundleFullPath {
            let bundle = Bundle(path: bundlePath)
            return bundle
        }
        return nil
    }
    
    public static func loadGif(_ name: String) -> URL? {
        var mainBundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle")
        mainBundlePath = mainBundlePath?.appending("/OktaWithWinkResources.bundle")
        
        if let bundlePath = mainBundlePath {
            let bundle = Bundle(path: bundlePath)
            if let url = bundle?.url(forResource: name,
                                     withExtension: "gif") {
                return url
            }
        }
        return nil
    }
    public static func resourcesBundle() -> Bundle? {
        let bundle = WinkSDKBundleManager.frameworkBundle()
        //print(b)
        let bundleUrl = bundle.url(forResource: "OktaWithWinkResources", withExtension: "bundle")
    
        
        if let bundleUrl = bundleUrl {
            print("Bundle URL found: \(bundleUrl)")
            let resourceBundle = Bundle(url: bundleUrl)
            return resourceBundle
        } else {
            print("Failed to find the bundle URL for OktaWithWinkResources.bundle")
            return nil
        }
    }
    
    public static func storyBorad(name: String) -> UIStoryboard? {
            let mainBundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle")
            if let bundlePath = mainBundlePath {
                let bundle = Bundle(path: bundlePath)
                return UIStoryboard(name: name, bundle: bundle)
            }
            return nil
        }
 
    public static func resourcesBundleJson() -> Bundle? {
        var mainBundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle")
        mainBundlePath = mainBundlePath?.appending("/OktaWithWinkResources.bundle")
        
        if let mainBundlePath = mainBundlePath {
            let bundle = Bundle(path: mainBundlePath)
            return bundle
        }
        return nil
    }
    
    public static func loadOktaConfig(fromCustomBundle plistName: String) -> OktaOidcConfig? {
        // Get the custom SDK bundle path
        guard let bundlePath = WinkSDKBundleManager.imageBundlePath(forResource: "WinkResources", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath) else {
            print("Error: Could not find custom SDK bundle.")
            return nil
        }

        // Locate the Okta plist file in the custom SDK bundle
        guard let plistPath = bundle.url(forResource: plistName, withExtension: "plist") else {
            print("Error: Could not find plist \(plistName) in the custom bundle.")
            return nil
        }

        do {
            // Read the plist data from the custom bundle
            let data = try Data(contentsOf: plistPath)
            
            // Deserialize the plist into a dictionary
            if let plistContent = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
                
                // Initialize the OktaOidcConfig using the dictionary
                return try OktaOidcConfig(with: plistContent)
            } else {
                print("Error: Failed to parse plist content.")
                return nil
            }
        } catch {
            print("Error: Failed to load or parse plist - \(error.localizedDescription).")
            return nil
        }
    }


}

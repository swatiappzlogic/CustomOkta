//
//  WebViewController.swift
//  CustomOktaSDK
//
//  Created by Ritesh Sharma on 10/11/24.
//

import UIKit
import WebKit

protocol WebViewControllerDelegate: AnyObject {
    func didReceiveWinkTag(_ winkTag: String)
}
class WebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    weak var delegate: WebViewControllerDelegate? // Add this line
    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        // configuration.userContentController = contentController
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        self.webView.navigationDelegate = self // Set the navigation delegate
        
        // Load an initial URL
        if let url = URL(string: "https://devlogin.winklogin.com/?bypass_kc=true&redirect_uri=https%3A%2F%2Fdev-eujzhhpntl3v68a8.us.auth0.com%2Flogin%2Fcallback&login_hint=&response_type=code&scope=openid%20profile&state=zCOJIhnn_uwHkrUtaHilCH7cssW-k8eK&client_id=sephora") {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
        self.webView.isHidden = false
        // Present the web view
        self.view.addSubview(self.webView)
    
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url {
            print("Current URL: \(currentURL.absoluteString)")
        }
    }

    
    // This function captures each URL navigation
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print("Navigated to URL: \(url.absoluteString)")
            
            // Check if the URL contains winkTag
            if let winkTagRange = url.absoluteString.range(of: "&winkTag=") {
                self.webView.isHidden = true
                let winkTag = url.absoluteString[winkTagRange.upperBound...].split(separator: "&").first
                print("WinkTag:", winkTag ?? "Not found")
                UserDefaults.standard.set(winkTag, forKey: "WinkTag")
//                self.lblTagLabel.text = "WinkTag:\(winkTag)"
                // Dismiss the webview after extracting winkTag
               
                if let unwrappedWinkTag = winkTag {
                       let winkTagString = String(unwrappedWinkTag) // Convert Substring to String
                    self.dismiss(animated: false) {
                        self.delegate?.didReceiveWinkTag(winkTagString) // Pass the string to the delegate
                    }
                       
                   } else {
                       print("Wink tag is nil.")
                   }
            } else {
                print("WinkTag not found")
            }
        }
        decisionHandler(.allow)
    }

}

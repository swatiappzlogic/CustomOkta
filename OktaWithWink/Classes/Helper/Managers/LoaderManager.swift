//
//  LoaderManager.swift
//  WinkApp
//
//  Created by MacBook on 12/12/24.
//

import UIKit

import NVActivityIndicatorView

class LoaderManager {
    static let shared = LoaderManager()
    
    private var activityIndicator: NVActivityIndicatorView?

    private init() {
        let frame = CGRect(x: 0, y: 0, width: 70, height: 70) // Adjust size as needed
        let type = NVActivityIndicatorType.ballSpinFadeLoader // Choose the desired type
        let color = UIColor.green // Set your desired color
        let padding: CGFloat = 0 // Adjust padding if needed
        
        activityIndicator = NVActivityIndicatorView(frame: frame, type: type, color: color, padding: padding)
    }
    
    func showLoader(in view: UIView) {
        guard let activityIndicator = activityIndicator else { return }
        if !view.subviews.contains(activityIndicator) {
            activityIndicator.center = view.center
            view.addSubview(activityIndicator)
        }
        activityIndicator.startAnimating()
    }
    
    func hideLoader() {
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
    }
}

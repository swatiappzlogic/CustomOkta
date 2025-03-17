//
//  TempViewController.swift
//  WinkApp
//
//  Created by MacBook on 29/11/24.
//

import UIKit
import WebKit
import AVFoundation

class TempViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WKScriptMessageHandler, WKNavigationDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionsCountLabel: UILabel!
    
    var webView: WKWebView!
    var modelReady = false
    var tmpPicturePath: String?
    var pictureSize = CGSize(width: 1280, height: 1919)
    var imgNo: UInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load an image from the bundle
        imageView.image = UIImage(named: "horse.jpg")
        pictureSize = CGSize(width: 1280, height: 1919)
        
        // Setup WebView and JavaScript
        let jsSourcePath = Bundle.main.path(forResource: "bridge", ofType: "js")!
        let userScript = try! String(contentsOfFile: jsSourcePath)
        let wkUserScript = WKUserScript(source: userScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(wkUserScript)
        userContentController.add(self, name: "TFJSBridge")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        
        // Load HTML file into the WebView
        let htmlIndexPath = Bundle.main.path(forResource: "index", ofType: "html")!
        let htmlIndexURL = URL(fileURLWithPath: htmlIndexPath)
        webView.loadFileURL(htmlIndexURL, allowingReadAccessTo: htmlIndexURL)
        
        view.addSubview(webView)
        
        predictionsCountLabel.text = ""
    }

    @IBAction func detect(_ sender: Any) {
        detectRequest()
    }

    func sendTakenPictureToHtml() {
        guard let tmpPicturePath = tmpPicturePath else { return }
        let script = "document.getElementById('img').src = '\(tmpPicturePath)';"
        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func detectRequest() {
        if modelReady {
            let script = "runDetection();"
            webView.evaluateJavaScript(script) { (result, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        } else {
            print("Model is not ready")
        }
    }

    @IBAction func takePhoto(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.sourceType = .camera
        present(pickerController, animated: true, completion: nil)
    }

    func imagePickerController(_ pickerController: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let chosenImage = info[.editedImage] as? UIImage else { return }
        
        imageView.image = chosenImage
        pickerController.dismiss(animated: true, completion: nil)
        
        // Save the picture to file
        if let imgData = chosenImage.jpegData(compressionQuality: 1) {
            imgNo += 1
            tmpPicturePath = "\(NSTemporaryDirectory())photoTaken\(imgNo).jpg"
            pictureSize = chosenImage.size
            let url = URL(fileURLWithPath: tmpPicturePath!)
            do {
                try imgData.write(to: url)
            } catch {
                print("Error saving image: \(error.localizedDescription)")
            }
        }
        
        sendTakenPictureToHtml()
        imageView.layer.sublayers?.removeAll()
    }

    func imagePickerControllerDidCancel(_ pickerController: UIImagePickerController) {
        pickerController.dismiss(animated: true, completion: nil)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let array = message.body as? [Any] else { return }
        guard let postTypeRaw = (array[0] as? NSNumber)?.intValue else { return }
        guard let postType = PostType(rawValue: postTypeRaw) else { return }
        
        switch postType {
        case .prepareModel:
            if let postTypeResult = array[1] as? [String: Any], let actionStatus = postTypeResult["status"] as? String, actionStatus == "ok" {
                modelReady = true
            }
        case .getPredictions:
            if let predictions = array[1] as? [[String: Any]] {
                handlePredictions(predictions)
            }
        }
    }

    func handlePredictions(_ predictions: [[String: Any]]) {
        for element in predictions {
            if let boundingBox = element["bbox"] as? [String],
               let className = element["class"] as? String,
               let score = element["score"] as? Float {
                
                let xmin = CGFloat((boundingBox[0] as NSString).floatValue) / pictureSize.width
                let ymin = CGFloat((boundingBox[1] as NSString).floatValue) / pictureSize.height
                let width = CGFloat((boundingBox[2] as NSString).floatValue) / pictureSize.width
                let height = CGFloat((boundingBox[3] as NSString).floatValue) / pictureSize.height
                let bboxRect = CGRect(x: xmin, y: ymin, width: width, height: height)
                let description = "\(className), \((Int)(score * 100))%"
                
                drawRect(bboxRect, text: description)
            }
        }
        
        predictionsCountLabel.text = "\(predictions.count) objects detected"
    }

    func drawRect(_ boundingBox: CGRect, text description: String) {
        guard let image = imageView.image else { return }
        
        let source = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        let size = CGSize(width: boundingBox.width * source.size.width, height: boundingBox.height * source.size.height)
        let origin = CGPoint(x: boundingBox.origin.x * source.size.width + source.origin.x, y: boundingBox.origin.y * source.size.height + source.origin.y)
        
        let outline = CAShapeLayer()
        outline.frame = CGRect(origin: origin, size: size)
        outline.borderColor = UIColor.yellow.cgColor
        outline.borderWidth = 1
        imageView.layer.addSublayer(outline)
        
        let label = CATextLayer()
        label.fontSize = 12
        label.allowsEdgeAntialiasing = true
        label.alignmentMode = .center
        label.foregroundColor = UIColor.yellow.cgColor
        label.string = description
        label.frame = outline.frame
        imageView.layer.addSublayer(label)
    }
}

// Enum to define the types of messages from JavaScript
enum PostType: Int {
    case prepareModel = 1
    case getPredictions = 2
}

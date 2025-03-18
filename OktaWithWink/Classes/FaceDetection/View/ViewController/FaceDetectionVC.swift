//
//  FaceDetectionVC.swift
//  WinkApp
//
//  Created by MacBook on 05/12/24.
//

import UIKit
import AVKit
import Vision
import ImageIO
import MobileCoreServices
import Alamofire
import CoreMedia
import CoreImage
//import OktaOidc


class FaceDetectionVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var hasUploaded = false
    var isFaceDetected = false
    var isPerfectDistance = false
    var isUploading = false
    var isDetectionStarted = false
    var isEnrolled = true
    var capturedImage: UIImage?
    var detectedFaces: [VNFaceObservation] = []
    var lastSampleBuffer: CMSampleBuffer?
    var winkSeed: String = ""
    var user_response_from_wink:UserInfoResponse?

    // Main view for showing camera content.
    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var positionLabel: UILabel?
    @IBOutlet weak var prepareLabel: UILabel?
    
    private let faceDetectModel = FaceDetectionVM()
    weak var delegate: FaceVCDelegate? // Add this line

    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    var captureDevice: AVCaptureDevice?
    var detectionRequests: [VNRequest]?
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    var winkDataReceived: ((String) -> Void)?
    
    var overlay: UIView?
    var bracketLayer: CAShapeLayer?
    
    let minDistance: CGFloat = 500
    let maxDistance: CGFloat = 700
    
    // MARK: - View LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.session = self.setupAVCaptureSession()
        self.prepareVisionRequest()
        self.addOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Delay start of face detection by 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isDetectionStarted = true
            self.prepareLabel?.text = "Detection Started"
           // self.prepareLabel?.isHidden = true
            Helper.logWithTime(message: "Capturing Starts")

            self.resetFlags()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    // MARK: - Helper Methods
    
    func resetFlags() {
        self.hasUploaded = false
        isPerfectDistance = false
        isUploading = false
    }
    
    func updatePositionLabel() {
        guard let previewLayer = self.previewLayer else { return }
        
        // If no faces detected
        if detectedFaces.isEmpty {
            //self.positionLabel?.text = "No faces detected"
            return
        }
        
        // Create a list of positions for each detected face
        var positionsText = "Detected Faces: \(detectedFaces.count)\n"
        for (index, face) in detectedFaces.enumerated() {
            // Convert face bounding box to layer coordinates
            let faceRect = previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
            let faceCenter = CGPoint(x: faceRect.midX, y: faceRect.midY)
            
            // Determine the position relative to the screen
            let position: String
            if faceCenter.x < previewLayer.bounds.midX && faceCenter.y < previewLayer.bounds.midY {
                position = "Top-Left"
            } else if faceCenter.x >= previewLayer.bounds.midX && faceCenter.y < previewLayer.bounds.midY {
                position = "Top-Right"
            } else if faceCenter.x < previewLayer.bounds.midX && faceCenter.y >= previewLayer.bounds.midY {
                position = "Bottom-Left"
            } else {
                position = "Bottom-Right"
            }
            
            positionsText += "Face \(index + 1): \(position)\n"
        }
        
        // Update the position label
        self.positionLabel?.text = positionsText
        self.prepareLabel?.text = ""
    }
    
    private func prepareVisionRequest() {
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { (request, error) in
            guard let results = request.results as? [VNFaceObservation] else { return }
            self.detectedFaces = results
            
            DispatchQueue.main.async {
                self.updatePositionLabel()
            }
        }
        
        self.detectionRequests = [faceDetectionRequest]
    }
    
    func checkFaceInCenter(faceRect: CGRect) -> Bool {
        guard let previewLayer = self.previewLayer else { return false }
        
        // Define cutout rectangle (center area)
        let cutoutWidth: CGFloat = 360
        let cutoutHeight: CGFloat = 500
        let cutoutRect = CGRect(
            x: (previewLayer.bounds.width - cutoutWidth) / 2,
            y: (previewLayer.bounds.height - cutoutHeight) / 2,
            width: cutoutWidth,
            height: cutoutHeight
        )
        
        // Define margin as a percentage of the cutout size (e.g., 10% margin)
        let margin: CGFloat = 0.2
        
        let centerX = previewLayer.bounds.width / 2
        let centerY = previewLayer.bounds.height / 2
        
        // Allow the face to be within 10% of the center
        let centerToleranceX = cutoutWidth * margin
        let centerToleranceY = cutoutHeight * margin
        
        // Check if the faceRect is within the tolerance range of the center
        let isWithinX = abs(faceRect.origin.x + faceRect.width / 2 - centerX) < centerToleranceX
        let isWithinY = abs(faceRect.origin.y + faceRect.height / 2 - centerY) < centerToleranceY
        
        return isWithinX && isWithinY
    }
    
    
    func isFaceWellLit(sampleBuffer: CMSampleBuffer) -> Bool {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return false
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let context = CIContext(options: nil)
        
        // Calculate average brightness
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: inputExtent])
        guard let outputImage = filter?.outputImage else {
            return false
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        // Safe computation by converting UInt8 to a larger type before performing addition
        let red = CGFloat(bitmap[0])
        let green = CGFloat(bitmap[1])
        let blue = CGFloat(bitmap[2])
        
        // Calculate average brightness using RGB components
        let brightness = (red + green + blue) / (255.0 * 3)
        
        // Adjust the threshold for better accuracy in real-world conditions
        return brightness > 0.23
    }
    
    func estimateDistance(for faceRect: CGRect) -> CGFloat {
        let faceHeight = faceRect.height
        let screenHeight = self.previewLayer?.bounds.height ?? 1
        let relativeFaceHeight = faceHeight / screenHeight
        
        // Adjust scaling factor for more accurate results
        let distance = 200 / relativeFaceHeight  // Increase the scaling factor for more reasonable distances
        return distance
    }
    
    // MARK: - Navigation Method

    func uploadImage(_ image: UIImage) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let storyboard = WinkSDKBundleManager.storyBorad(name: "MainWink")
            let detectVC = storyboard?.instantiateViewController(withIdentifier: "FaceDetectionProcessingVC") as! FaceDetectionProcessingVC
            detectVC.delegate = self.delegate
            detectVC.faceDelegate = self
            detectVC.capturedImage = image
            self.navigationController?.pushViewController(detectVC, animated: true)
        }
    }
    
    // MARK: - Overlay Methods
    
    
    func updateOverlayColor(forDistance distance: CGFloat?) {
        if distance == nil {
            setOverlayColor(UIColor.red)
        } else {
            setOverlayColor(UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0))
        }
    }
    
    func setOverlayColor(_ color: UIColor) {
        self.bracketLayer?.strokeColor = color.cgColor
    }
    
    func addOverlay() {
        // Create overlay
        let overlay = UIView()
        overlay.frame = view.bounds
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Define scaling factor based on screen size (larger on iPad)
        let screenWidth = UIScreen.main.bounds.width
        var cutoutWidth: CGFloat
        var cutoutHeight: CGFloat
        
        // For iPhone, the cutout size is fixed, but for iPad, we scale it up
        if screenWidth <= 375 { // For iPhones (e.g., iPhone 12, 13)
            cutoutWidth = 460
            cutoutHeight = 600
        } else { // For larger devices (e.g., iPad)
            // Scale the cutout size for iPad
            let scaleFactor: CGFloat = screenWidth / 375 // Using 375 as base (iPhone X width)
            cutoutWidth = 360 * scaleFactor - 100
            cutoutHeight = 500 * scaleFactor - 100
        }

        cutoutWidth = view.bounds.width - 80
        cutoutHeight = view.bounds.height - 200
        
        // Define cutout rectangle
        let cutoutRect = CGRect(
            x: (view.bounds.width - cutoutWidth) / 2,
            y: (view.bounds.height - cutoutHeight) / 2,
            width: cutoutWidth,
            height: cutoutHeight
        )

        // Create paths for cutout
        let path = UIBezierPath(rect: view.bounds)
        let cutoutPath = UIBezierPath(rect: cutoutRect)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true

        // Mask to create transparent cutout
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlay.layer.mask = maskLayer
        view.addSubview(overlay)

        // Square brackets (rectangle border)
        let bracketLayer = CAShapeLayer()
        bracketLayer.strokeColor = UIColor.red.cgColor  // Bright green color

        bracketLayer.lineWidth = 10
        bracketLayer.fillColor = UIColor.clear.cgColor

        // Create a rectangle path instead of arcs
        let bracketPath = UIBezierPath(rect: cutoutRect)

        bracketLayer.path = bracketPath.cgPath
        overlay.layer.addSublayer(bracketLayer)

        // Save references for updates
        self.overlay = overlay
        self.bracketLayer = bracketLayer
    }

    
    // MARK: - AVCaptureSession Methods
    
    func setupAVCaptureSession() -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front camera available.")
        }
        
        self.captureDevice = captureDevice
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                fatalError("Could not add video input to session.")
            }
        } catch {
            fatalError("Could not create video input: \(error)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            fatalError("Could not add video output to session.")
        }
        
        self.videoDataOutput = videoOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        
        // Set up preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = self.view.bounds
        self.previewLayer = previewLayer
        self.previewView?.layer.addSublayer(previewLayer)
        
        return session
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetectionStarted else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNSequenceRequestHandler()
        do {
            try requestHandler.perform(self.detectionRequests ?? [], on: pixelBuffer)
        } catch {
            print("Error performing face detection request: \(error)")
        }
        
        DispatchQueue.main.async {
            if self.detectedFaces.isEmpty {
                self.prepareLabel?.text = "No face detected.\n Align your face with the frame."
                self.positionLabel?.text = ""
                self.updateOverlayColor(forDistance: nil)
                return
            }
            
            guard let face = self.detectedFaces.first else { return }
            let faceRect = self.previewLayer?.layerRectConverted(fromMetadataOutputRect: face.boundingBox) ?? CGRect.zero
            
            // Check face position and lighting
            let isCentered = self.checkFaceInCenter(faceRect: faceRect)
            //let isWellLit = self.isFaceWellLit(sampleBuffer: sampleBuffer)
            let faceDistance = self.estimateDistance(for: faceRect)
            
            var errorMessage: String?
            
            if self.isUploading {
                return
            }
            
            if faceDistance < self.minDistance {
                errorMessage = "Move farther from the camera."
                self.setOverlayColor(.orange)
            } else if faceDistance > self.maxDistance {
                errorMessage = "Move closer to the camera."
                self.setOverlayColor(.orange)
            }else if !isCentered {
                errorMessage = "Move your face to the center of the frame."
                self.setOverlayColor(.red)
            } else{
                self.setOverlayColor(UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0))

            }
            //print ("face distanc\(faceDistance) ")
            
            // Display Error or Process
            if let message = errorMessage {
                self.prepareLabel?.text = message
                self.hasUploaded = false
                self.isUploading = false
            } else {
                self.prepareLabel?.text = "Face aligned and well-lit."
                self.setOverlayColor(.green)
                if !self.isUploading && !self.hasUploaded {
                    self.hasUploaded = true
                    self.isUploading = true
                    if let image = self.imageFromSampleBuffer(sampleBuffer, isFrontCamera: true) {
                        self.capturedImage = image
                        self.uploadImage(image)
                    }
                }
            }
        }
    }
    
    // Function to stop the capture session
    private func stopCaptureSession() {
        session?.stopRunning()
        print("Capture session stopped.")
    }
    
    // Fix image orientation by adjusting rotation and mirroring based on EXIF data
    func fixImageOrientation(image: UIImage, isFrontCamera: Bool) -> UIImage {
        // If the image is already upright, no need to fix anything
        if image.imageOrientation == .up { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        
        // If using the front camera, we need to flip the image horizontally
        if isFrontCamera {
            context?.scaleBy(x: -1.0, y: 1.0)  // Flip horizontally
        }
        
        // Apply the rotation based on EXIF metadata
        switch image.imageOrientation {
        case .down:
            context?.translateBy(x: image.size.width, y: image.size.height)
            context?.rotate(by: .pi)
        case .left:
            context?.translateBy(x: image.size.width, y: 0)
            context?.rotate(by: .pi / 2)
        case .right:
            context?.translateBy(x: 0, y: image.size.height)
            context?.rotate(by: -.pi / 2)
        case .upMirrored:
            context?.scaleBy(x: -1.0, y: 1.0)  // Flip horizontally (no rotation)
        case .downMirrored:
            context?.scaleBy(x: -1.0, y: -1.0) // Flip both horizontally and vertically
        case .leftMirrored:
            context?.scaleBy(x: -1.0, y: 1.0)
            context?.rotate(by: .pi / 2)
        case .rightMirrored:
            context?.scaleBy(x: -1.0, y: -1.0)
            context?.rotate(by: -.pi / 2)
        default:
            break
        }
        
        // Draw the image with applied transformations
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        // Retrieve the new image with the correct orientation and transformations
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    // Convert the sample buffer (from AVCaptureSession) to UIImage and fix its orientation
    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer, isFrontCamera: Bool) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        // Create the UIImage from the CGImage assuming it's upright initially
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        
        // Fix the image orientation and handle potential mirroring if using the front camera
        return fixImageOrientation(image: image, isFrontCamera: isFrontCamera)
    }
}

// MARK: -

extension FaceDetectionVC: FaceProcessingDelegate{
    func didUpdateEnrollmentStatus(isEnrolled: Bool) {
        self.isEnrolled = isEnrolled
    }

}

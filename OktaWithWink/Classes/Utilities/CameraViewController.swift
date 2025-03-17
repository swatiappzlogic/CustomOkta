//
//  CameraViewController.swift
//  WinkApp
//
//  Created by MacBook on 29/11/24.
//
import UIKit
import ARKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, ARSCNViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
    private var faceView: ARSCNView!
    private let overlayMask = CAShapeLayer()
    
    private var modelReady = false
    private var tmpPicturePath: String?
    private var pictureSize = CGSize(width: 1280, height: 1919)
    private var imgNo: UInt = 0
    
    // Variable to track if a face is detected
    private var faceDetected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up ARKit for face tracking
        setupARKit()
        
        // Set up the Camera for capturing photos
        setupCamera()
        
        // Set up the circular overlay mask
       setupCircularOverlay()
        
        view.bringSubviewToFront(statusLabel)
    }
    
    // MARK: - ARKit Setup
    
    private func setupARKit() {
        faceView = ARSCNView(frame: view.bounds)
        faceView.delegate = self
        view.addSubview(faceView)
        
        // Ensure the device supports AR Face Tracking
        guard ARFaceTrackingConfiguration.isSupported else {
            statusLabel.text = "AR Face Detection is not supported on this device"
            return
        }
        
        // Run face tracking configuration
        let configuration = ARFaceTrackingConfiguration()
        faceView.session.run(configuration)
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Check camera permissions
        checkCameraPermission()
        
        // Select the rear camera
        guard let rearCamera = getRearCamera() else {
            print("Error: Unable to access the rear camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: rearCamera)
            captureSession.addInput(input)
        } catch {
            print("Error: Unable to configure camera input. \(error.localizedDescription)")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        captureSession.addOutput(photoOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // Add the camera preview layer to the main view
        view.layer.insertSublayer(previewLayer, at: 0)
        
        captureSession.startRunning()
    }
    
    private func getRearCamera() -> AVCaptureDevice? {
        let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                            mediaType: .video,
                                                            position: .back).devices
        return videoDevices.first
    }
    
    private func checkCameraPermission() {
        // Check if the app has permission to access the camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission granted
            break
        case .denied, .restricted:
            print("Camera permission denied or restricted")
            statusLabel.text = "Camera permission denied"
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { response in
                if !response {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Camera permission denied"
                    }
                }
            }
        default:
            print("Unknown camera permission status")
        }
    }
    
    private func setupCircularOverlay() {
        // Create a mask path for the solid background (black)
        let maskPath = UIBezierPath(rect: view.bounds)
        
        // Define the circular cutout area where the camera will be visible
        let circlePath = UIBezierPath(ovalIn: CGRect(
            x: view.bounds.width / 2 - 150,
            y: view.bounds.height / 2 - 150,
            width: 300,
            height: 300
        ))
        
        // Use the even-odd fill rule to "cut out" the circle area from the mask
        maskPath.append(circlePath)
        maskPath.usesEvenOddFillRule = true
        
        // Create a shape layer to act as a mask
        overlayMask.path = maskPath.cgPath
        overlayMask.fillRule = .evenOdd
        overlayMask.fillColor = UIColor.black.cgColor
        overlayMask.opacity = 0.6
        
        // Add the overlayMask to the view's layer
        view.layer.addSublayer(overlayMask)
    }
    
    // MARK: - Photo Capture
    
    @objc private func captureImage() {
        // Capture photo only if a face is detected
        if faceDetected {
            let settings = AVCapturePhotoSettings()
            //settings.isHighResolutionPhotoEnabled = true
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        } else {
            print("No face detected. Cannot capture photo.")
            statusLabel.text = "No face detected. Cannot capture photo."
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            //
            statusLabel.text = "Error capturing photo"
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let capturedImage = UIImage(data: imageData) else {
            print("Error: Unable to capture image.")
            statusLabel.text = "Unable to capture image."
            return
        }
        
        // Crop the captured image to the circular region
        let croppedImage = cropToCircle(image: capturedImage)
        
        // Save the cropped image to a temporary path
        if let imgData = croppedImage?.jpegData(compressionQuality: 1) {
            imgNo += 1
            tmpPicturePath = "\(NSTemporaryDirectory())photoTaken\(imgNo).jpg"
            pictureSize = croppedImage?.size ?? CGSize(width: 1280, height: 1919)
            let url = URL(fileURLWithPath: tmpPicturePath!)
            do {
                try imgData.write(to: url)
                print("Image saved at: \(tmpPicturePath!)")
                statusLabel.text = "Photo captured successfully"
            } catch {
                print("Error saving image: \(error.localizedDescription)")
                statusLabel.text = "Error saving image"
            }
        }
        
        // Display the cropped image on the screen (optional)
        imageView.image = croppedImage
    }
    
    private func cropToCircle(image: UIImage) -> UIImage? {
        let imageSize = image.size
        let circleFrame = CGRect(
            x: imageSize.width / 2 - 150,
            y: imageSize.height / 2 - 150,
            width: 300,
            height: 300
        )
        
        UIGraphicsBeginImageContextWithOptions(circleFrame.size, false, image.scale)
        
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: circleFrame.size))
        path.addClip()
        
        image.draw(at: CGPoint(x: -circleFrame.origin.x, y: -circleFrame.origin.y))
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
    @IBAction func captureImageButtonTapped(_ sender: UIButton) {
        captureImage()
    }
    
    // MARK: - ARSCNViewDelegate Methods
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // No need for face mesh, but we will detect if the face is present
        if let faceAnchor = anchor as? ARFaceAnchor {
            // The face is detected, set the flag to true
            faceDetected = true
        }
        return nil
    }
    
    // This method is called when a face is no longer detected (optional)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.anchors.isEmpty {
            faceDetected = false // No face detected
        }
    }
}

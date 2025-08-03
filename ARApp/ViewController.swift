import UIKit
import ARKit
import RealityKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    // Camera components
    private var captureButton: UIButton?
    private var capturedImage: UIImage?
    private var scanCounter: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAR()
        setupCamera()
        createScanSessionFolder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start AR session when view appears
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause AR session when view disappears
        arView.session.pause()
    }
    
    private func setupAR() {
        // Configure AR view
        arView.automaticallyConfigureSession = false
        
        // Set up AR session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Start the AR session
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Set up AR session delegate
        arView.session.delegate = self
        
        // Add tap gesture recognizer for interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.createCaptureButton()
                } else {
                    self?.showCameraPermissionAlert()
                }
            }
        }
    }
    
    private func createCaptureButton() {
        captureButton = UIButton(type: .custom)
        captureButton?.backgroundColor = .white
        captureButton?.layer.cornerRadius = 40
        captureButton?.layer.borderWidth = 4
        captureButton?.layer.borderColor = UIColor.black.cgColor
        captureButton?.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        if let captureButton = captureButton {
            view.addSubview(captureButton)
            captureButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
                captureButton.widthAnchor.constraint(equalToConstant: 80),
                captureButton.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
    }
    
    @objc private func captureButtonTapped() {
        // Use ARKit's built-in photo capture
        arView.snapshot(saveToHDR: false) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.capturedImage = image
                    
                    // Save to ScanSession folder
                    let savedToScanSession = self?.saveImageToScanSession(image) ?? false
                    
                    // Show success or error alert
                    if savedToScanSession {
                        let alert = UIAlertController(
                            title: "Photo Captured",
                            message: "Photo saved to ScanSession folder as scan_\(String(format: "%02d", self?.scanCounter ?? 0)).jpg",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "View Photo", style: .default) { _ in
                            self?.showCapturedImage(image)
                        })
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self?.present(alert, animated: true)
                    } else {
                        let alert = UIAlertController(
                            title: "Save Failed",
                            message: "Failed to save photo to ScanSession folder.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                } else {
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Photo Capture Failed",
                        message: "Unable to capture photo. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Permission Required",
            message: "This app needs camera access to capture photos. Please enable camera access in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showCapturedImage(_ image: UIImage) {
        let imageViewController = UIViewController()
        imageViewController.view.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageViewController.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageViewController.view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageViewController.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageViewController.view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageViewController.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Add save button
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveImage))
        imageViewController.navigationItem.rightBarButtonItem = saveButton
        
        let navigationController = UINavigationController(rootViewController: imageViewController)
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barStyle = .black
        
        present(navigationController, animated: true)
    }
    
    @objc private func saveImage() {
        // Save the image to photo library
        if let image = capturedImage {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            // Show error alert if no image
            let alert = UIAlertController(
                title: "Save Failed",
                message: "No image to save.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                // Show error alert
                let alert = UIAlertController(
                    title: "Save Failed",
                    message: "Failed to save photo: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                // Show success alert
                let alert = UIAlertController(
                    title: "Photo Saved",
                    message: "Photo has been saved to your camera roll!",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismiss(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        
        // Perform ray casting to detect surfaces
        guard let raycastQuery = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any) else {
            return
        }
        
        let results = arView.session.raycast(raycastQuery)
        guard let result = results.first else {
            return
        }
        
        // Create a simple sphere entity at the tapped location
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
        
        // Create anchor at the hit location
        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.addChild(sphere)
        
        // Add the anchor to the scene
        arView.scene.addAnchor(anchor)
    }
    
    // MARK: - File Management
    private func createScanSessionFolder() {
        // Get the Documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory")
            return
        }
        
        // Create the ScanSession folder path
        let scanSessionPath = documentsPath.appendingPathComponent("ScanSession")
        
        // Check if the folder already exists
        if !FileManager.default.fileExists(atPath: scanSessionPath.path) {
            do {
                // Create the folder
                try FileManager.default.createDirectory(at: scanSessionPath, withIntermediateDirectories: true, attributes: nil)
                print("Successfully created ScanSession folder at: \(scanSessionPath.path)")
            } catch {
                print("Error creating ScanSession folder: \(error.localizedDescription)")
            }
        } else {
            print("ScanSession folder already exists at: \(scanSessionPath.path)")
        }
    }
    
    private func saveImageToScanSession(_ image: UIImage) -> Bool {
        // Get the Documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory")
            return false
        }
        
        // Create the ScanSession folder path
        let scanSessionPath = documentsPath.appendingPathComponent("ScanSession")
        
        // Ensure the folder exists
        if !FileManager.default.fileExists(atPath: scanSessionPath.path) {
            do {
                try FileManager.default.createDirectory(at: scanSessionPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating ScanSession folder: \(error.localizedDescription)")
                return false
            }
        }
        
        // Increment counter and create filename
        scanCounter += 1
        let filename = String(format: "scan_%02d.jpg", scanCounter)
        let fileURL = scanSessionPath.appendingPathComponent(filename)
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG data")
            return false
        }
        
        // Save the file
        do {
            try imageData.write(to: fileURL)
            print("Successfully saved \(filename) to ScanSession folder")
            print("📁 Full file path: \(fileURL.path)")
            return true
        } catch {
            print("Error saving image to ScanSession folder: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Handle AR session failures
        print("AR Session failed: \(error.localizedDescription)")
        
        // Show alert to user
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "AR Session Error", 
                                        message: error.localizedDescription, 
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Handle session interruption (e.g., phone call, app switching)
        print("AR Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Handle session interruption ending
        print("AR Session interruption ended")
        
        // Restart the session
        startARSession()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // Handle camera tracking state changes
        switch camera.trackingState {
        case .normal:
            print("Camera tracking is normal")
        case .notAvailable:
            print("Camera tracking not available")
        case .limited(let reason):
            print("Camera tracking limited: \(reason)")
        @unknown default:
            print("Unknown camera tracking state")
        }
    }
} 

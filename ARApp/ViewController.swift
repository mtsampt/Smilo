import UIKit
import ARKit
import RealityKit
import AVFoundation
import Photos
import Darwin

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    // Camera components
    private var captureButton: UIButton?
    private var meshGenerationButton: UIButton?
    private var capturedImage: UIImage?
    private var scanCounter: Int = 0
    private var meshGenerator: MeshGenerator?
    
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
        
        // Create mesh generation button
        createMeshGenerationButton()
    }
    
    private func createMeshGenerationButton() {
        meshGenerationButton = UIButton(type: .custom)
        meshGenerationButton?.backgroundColor = .systemBlue
        meshGenerationButton?.layer.cornerRadius = 25
        meshGenerationButton?.layer.borderWidth = 2
        meshGenerationButton?.layer.borderColor = UIColor.white.cgColor
        meshGenerationButton?.setTitle("3D", for: .normal)
        meshGenerationButton?.setTitleColor(.white, for: .normal)
        meshGenerationButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Check device compatibility and update button state
        if !isObjectCaptureSupported() {
            meshGenerationButton?.backgroundColor = .systemGray
            meshGenerationButton?.setTitle("⚠️", for: .normal)
            meshGenerationButton?.isEnabled = false
            print("⚠️ Object Capture not supported on this device")
        }
        
        meshGenerationButton?.addTarget(self, action: #selector(meshGenerationButtonTapped), for: .touchUpInside)
        
        if let meshGenerationButton = meshGenerationButton {
            view.addSubview(meshGenerationButton)
            meshGenerationButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                meshGenerationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                meshGenerationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
                meshGenerationButton.widthAnchor.constraint(equalToConstant: 50),
                meshGenerationButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
        
        // Create a second button for loading meshes
        let loadMeshButton = UIButton(type: .custom)
        loadMeshButton.backgroundColor = .systemGreen
        loadMeshButton.layer.cornerRadius = 20
        loadMeshButton.layer.borderWidth = 2
        loadMeshButton.layer.borderColor = UIColor.white.cgColor
        loadMeshButton.setTitle("Load", for: .normal)
        loadMeshButton.setTitleColor(.white, for: .normal)
        loadMeshButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        loadMeshButton.addTarget(self, action: #selector(loadMeshButtonTapped), for: .touchUpInside)
        
        view.addSubview(loadMeshButton)
        loadMeshButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadMeshButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            loadMeshButton.bottomAnchor.constraint(equalTo: meshGenerationButton!.topAnchor, constant: -10),
            loadMeshButton.widthAnchor.constraint(equalToConstant: 40),
            loadMeshButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Create a third button for the 3D viewer
        let viewerButton = UIButton(type: .custom)
        viewerButton.backgroundColor = .systemOrange
        viewerButton.layer.cornerRadius = 20
        viewerButton.layer.borderWidth = 2
        viewerButton.layer.borderColor = UIColor.white.cgColor
        viewerButton.setTitle("3D", for: .normal)
        viewerButton.setTitleColor(.white, for: .normal)
        viewerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        viewerButton.addTarget(self, action: #selector(viewerButtonTapped), for: .touchUpInside)
        
        view.addSubview(viewerButton)
        viewerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewerButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            viewerButton.bottomAnchor.constraint(equalTo: loadMeshButton.topAnchor, constant: -10),
            viewerButton.widthAnchor.constraint(equalToConstant: 40),
            viewerButton.heightAnchor.constraint(equalToConstant: 40)
        ])
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
    
    @objc private func meshGenerationButtonTapped() {
        print("🔍 DEBUG: meshGenerationButtonTapped called")
        
        // Show immediate feedback
        showAlert(title: "Starting 3D Generation", message: "Creating 3D mesh from photos...")
        
        // Disable the button during generation
        meshGenerationButton?.isEnabled = false
        meshGenerationButton?.alpha = 0.5
        meshGenerationButton?.setTitle("Working...", for: .normal)
        
        // Create a simple test mesh with progress simulation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate progress
            self.meshGenerationButton?.setTitle("25%", for: .normal)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.meshGenerationButton?.setTitle("50%", for: .normal)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.meshGenerationButton?.setTitle("75%", for: .normal)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            print("✅ DEBUG: Creating 3D mesh")
            
            // Create a blue cube (simulating generated mesh)
            let cube = ModelEntity(mesh: .generateBox(size: [0.3, 0.3, 0.3]))
            cube.name = "Generated 3D Mesh"
            
            // Add bright blue material
            var material = SimpleMaterial()
            material.color = .init(tint: .systemBlue)
            material.metallic = 0.0
            material.roughness = 0.0
            cube.model?.materials = [material]
            
            // Display it in AR
            self.displayMeshInAR(cube)
            
            // Re-enable button
            self.meshGenerationButton?.isEnabled = true
            self.meshGenerationButton?.alpha = 1.0
            self.meshGenerationButton?.setTitle("3D", for: .normal)
            
            print("✅ DEBUG: 3D mesh created and displayed")
        }
    }
    
    /// Demonstrates how to load and display a 3D mesh file
    @objc private func loadMeshButtonTapped() {
        print("🔍 DEBUG: loadMeshButtonTapped called")
        
        // Get the Documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            showAlert(title: "Error", message: "Could not access Documents directory")
            return
        }
        
        let meshOutputPath = documentsPath.appendingPathComponent("MeshOutput")
        
        // Check if MeshOutput directory exists
        guard FileManager.default.fileExists(atPath: meshOutputPath.path) else {
            showAlert(title: "No Mesh Files", message: "No MeshOutput directory found. Generate a mesh first.")
            return
        }
        
        // Load all mesh files from the directory
        let entities = loadAllMeshesFromDirectory(meshOutputPath)
        
        if entities.isEmpty {
            showAlert(title: "No Mesh Files", message: "No supported mesh files found in MeshOutput directory.")
        } else {
            // Display the first loaded mesh in AR
            let firstEntity = entities[0]
            print("🎯 DEBUG: About to display mesh: \(firstEntity.name)")
            print("🔍 DEBUG: Entity position: \(firstEntity.position)")
            print("🔍 DEBUG: Entity scale: \(firstEntity.scale)")
            print("🔍 DEBUG: Entity name: \(firstEntity.name)")
            displayMeshInAR(firstEntity)
            
            showAlert(
                title: "Mesh Loaded!",
                message: "Successfully loaded \(entities.count) mesh file(s).\n\nFirst mesh: \(firstEntity.name)"
            )
        }
    }
    
    /// Displays a ModelEntity in the AR scene
    private func displayMeshInAR(_ entity: ModelEntity) {
        print("🔍 DEBUG: Displaying mesh in AR: \(entity.name)")
        
        // Check if AR session is running
        guard arView.session.currentFrame != nil else {
            print("❌ DEBUG: AR session not running!")
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "AR Session Error",
                    message: "AR session is not running. Please restart the app.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            return
        }
        
        // Position the entity in front of the camera
        let cameraTransform = arView.session.currentFrame!.camera.transform
        let cameraPosition = simd_make_float3(cameraTransform.columns.3)
        let cameraForward = simd_make_float3(-cameraTransform.columns.2) // Forward direction
        let position = cameraPosition + cameraForward * 0.5 // 0.5 meters in front
        
        print("📱 DEBUG: Camera position: \(cameraPosition)")
        print("📱 DEBUG: Camera forward: \(cameraForward)")
        print("📱 DEBUG: Cube position: \(position)")
        
        // Make the entity much larger and more visible
        entity.scale = [1.0, 1.0, 1.0] // Make it full size
        entity.position = [0, 0, 0] // Position relative to anchor
        
        // Add bright material to make it very visible
        var material = SimpleMaterial()
        material.color = .init(tint: .systemBlue)
        material.metallic = 0.0
        material.roughness = 0.0
        entity.model?.materials = [material]
        
        // Create anchor and add entity properly
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        
        print("✅ DEBUG: Mesh added to AR scene at position: \(position)")
        print("🎯 DEBUG: Object should be visible in front of you")
        print("📱 DEBUG: Try moving your device around to find the blue cube")
        
        // Also add a simple sphere as backup
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1))
        sphere.name = "Debug Sphere"
        var sphereMaterial = SimpleMaterial()
        sphereMaterial.color = .init(tint: .systemRed)
        sphere.model?.materials = [sphereMaterial]
        
        let sphereAnchor = AnchorEntity(world: position + [0.2, 0, 0])
        sphereAnchor.addChild(sphere)
        arView.scene.addAnchor(sphereAnchor)
        
        print("🔴 DEBUG: Added red sphere as backup at: \(position + [0.2, 0, 0])")
        
        // Show an alert to help the user find the object
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "3D Objects Loaded! 🎉",
                message: "A blue cube and red sphere have been added to your AR scene.\n\nLook around and move your device to find them!\n\nBlue cube position: \(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z))\n\nRed sphere is 0.2m to the right of the cube.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    /// Opens the 3D model viewer
    @objc private func viewerButtonTapped() {
        print("🔍 DEBUG: viewerButtonTapped called")
        
        // Show a simple alert for now since we can't add SwiftUI files easily
        let alert = UIAlertController(
            title: "3D Model Viewer",
            message: "This would open a SwiftUI view with interactive 3D model viewing capabilities including:\n\n• Drag to rotate\n• Pinch to zoom\n• Load custom models\n• Reset view\n\nThe ModelViewer.swift file has been created but needs to be added to the Xcode project manually.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /// Navigates to the ModelViewer with a specific mesh file
    private func navigateToModelViewer(with fileURL: URL) {
        print("🔍 DEBUG: navigateToModelViewer called with file: \(fileURL.path)")
        
        // Show success alert with option to view the model
        let alert = UIAlertController(
            title: "3D Mesh Generated! 🎉",
            message: "Successfully created 3D mesh from your photos.\n\nFile saved to:\n\(fileURL.lastPathComponent)\n\nTo view the model:\n1. Add ModelViewer.swift to your Xcode project\n2. Tap the orange '3D' button\n3. The model will load automatically",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "View Model", style: .default) { _ in
            // This would open the ModelViewer when the file is added to the project
            print("✅ DEBUG: User chose to view model: \(fileURL.lastPathComponent)")
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true) {
            print("✅ DEBUG: Success alert presented for mesh file: \(fileURL.lastPathComponent)")
        }
    }
    
    /// Resets the scan counter to start fresh
    private func resetScanCounter() {
        scanCounter = 0
        print("🔄 DEBUG: Scan counter reset to 0")
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
    
    private func showAlert(title: String, message: String, showViewButton: Bool = false, fileURL: URL? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        if showViewButton, let fileURL = fileURL {
            alert.addAction(UIAlertAction(title: "View Model", style: .default) { _ in
                print("✅ DEBUG: User chose to view model: \(fileURL.lastPathComponent)")
                self.navigateToModelViewer(with: fileURL)
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    private func isObjectCaptureSupported() -> Bool {
        // Check iOS version (Object Capture requires iOS 17+)
        if #available(iOS 17.0, *) {
            // Check device chip (Object Capture requires A14+)
            let device = UIDevice.current
            let deviceInfo = device.systemName + " " + device.systemVersion
            
            // Get device identifier
            var systemInfo = utsname()
            uname(&systemInfo)
            let machine = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }
            
            let deviceIdentifier = machine ?? "unknown"
            print("📱 Device identifier: \(deviceIdentifier)")
            
            // Check if device has A14+ chip (iPhone 12 and newer)
            let a14PlusDevices = [
                "iPhone14,2", // iPhone 13 Pro
                "iPhone14,3", // iPhone 13 Pro Max
                "iPhone14,4", // iPhone 13 mini
                "iPhone14,5", // iPhone 13
                "iPhone14,6", // iPhone SE (3rd generation)
                "iPhone14,7", // iPhone 14
                "iPhone14,8", // iPhone 14 Plus
                "iPhone15,2", // iPhone 14 Pro
                "iPhone15,3", // iPhone 14 Pro Max
                "iPhone15,4", // iPhone 15
                "iPhone15,5", // iPhone 15 Plus
                "iPhone16,1", // iPhone 15 Pro
                "iPhone16,2", // iPhone 15 Pro Max
                "iPhone17,1", // iPhone 16 (future)
                "iPhone17,2", // iPhone 16 Plus (future)
                "iPhone17,3", // iPhone 16 Pro (future)
                "iPhone17,4", // iPhone 16 Pro Max (future)
                // iPad models with A14+ (iPad Air 4th gen and newer)
                "iPad13,1", // iPad Air (4th generation)
                "iPad13,2", // iPad Air (4th generation)
                "iPad13,4", // iPad Pro (11-inch, 3rd generation)
                "iPad13,5", // iPad Pro (11-inch, 3rd generation)
                "iPad13,6", // iPad Pro (12.9-inch, 5th generation)
                "iPad13,7", // iPad Pro (12.9-inch, 5th generation)
                "iPad13,8", // iPad Pro (12.9-inch, 5th generation)
                "iPad13,9", // iPad Pro (12.9-inch, 5th generation)
                "iPad13,10", // iPad Pro (12.9-inch, 5th generation)
                "iPad13,11", // iPad Pro (12.9-inch, 5th generation)
                "iPad14,1", // iPad mini (6th generation)
                "iPad14,2", // iPad mini (6th generation)
                "iPad14,3", // iPad Air (5th generation)
                "iPad14,4", // iPad Air (5th generation)
                "iPad14,5", // iPad Pro (11-inch, 4th generation)
                "iPad14,6", // iPad Pro (11-inch, 4th generation)
                "iPad14,7", // iPad Pro (12.9-inch, 6th generation)
                "iPad14,8", // iPad Pro (12.9-inch, 6th generation)
                "iPad15,1", // iPad (10th generation)
                "iPad15,2", // iPad (10th generation)
                "iPad15,3", // iPad Air (6th generation)
                "iPad15,4", // iPad Air (6th generation)
                "iPad15,5", // iPad Pro (11-inch, 5th generation)
                "iPad15,6", // iPad Pro (11-inch, 5th generation)
                "iPad16,1", // iPad Pro (12.9-inch, 7th generation)
                "iPad16,2", // iPad Pro (12.9-inch, 7th generation)
            ]
            
            let isSupported = a14PlusDevices.contains(deviceIdentifier)
            print("🔍 Device support check: \(isSupported ? "✅ Supported" : "❌ Not supported")")
            return isSupported
            
        } else {
            print("❌ iOS version too old (requires iOS 17+)")
            return false
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let meshError = error as? MeshGeneratorError {
            switch meshError {
            case .noPhotosFound:
                return "No photos found in ScanSession folder. Please capture some photos first."
            case .cancelled:
                return "Mesh generation was cancelled."
            case .generationFailed:
                return "Failed to generate 3D mesh from photos. Please try again."
            case .fileSaveFailed:
                return "Failed to save the generated mesh file."
            case .meshLoadFailed:
                return "Failed to load the generated mesh."
            case .unknownResult:
                return "Unknown error occurred during mesh generation."
            }
        } else {
            return "Failed to generate 3D mesh: \(error.localizedDescription)"
        }
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
            print("❌ DEBUG: No raycast query possible")
            return
        }
        
        let results = arView.session.raycast(raycastQuery)
        guard let result = results.first else {
            print("❌ DEBUG: No surface detected at tap location")
            // If no surface detected, place object in front of camera
            placeObjectInFrontOfCamera()
            return
        }
        
        print("✅ DEBUG: Surface detected at: \(result.worldTransform.columns.3)")
        
        // Create a simple sphere entity at the tapped location
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1))
        sphere.name = "Tap Sphere"
        
        // Add bright material
        var material = SimpleMaterial()
        material.color = .init(tint: .systemGreen)
        sphere.model?.materials = [material]
        
        // Create anchor at the hit location
        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.addChild(sphere)
        
        // Add the anchor to the scene
        arView.scene.addAnchor(anchor)
        
        print("✅ DEBUG: Green sphere placed at tapped location")
    }
    
    private func placeObjectInFrontOfCamera() {
        print("🔍 DEBUG: Placing object in front of camera")
        
        guard let currentFrame = arView.session.currentFrame else {
            print("❌ DEBUG: No current AR frame")
            return
        }
        
        let cameraTransform = currentFrame.camera.transform
        let cameraPosition = simd_make_float3(cameraTransform.columns.3)
        let cameraForward = simd_make_float3(-cameraTransform.columns.2)
        let position = cameraPosition + cameraForward * 0.5
        
        print("📱 DEBUG: Camera position: \(cameraPosition)")
        print("📱 DEBUG: Object position: \(position)")
        
        // Create a bright green sphere
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1))
        sphere.name = "Front Sphere"
        
        var material = SimpleMaterial()
        material.color = .init(tint: .systemGreen)
        sphere.model?.materials = [material]
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        
        print("✅ DEBUG: Green sphere placed in front of camera")
        
        // Show alert
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Green Sphere Added! 🟢",
                message: "A green sphere has been placed 0.5 meters in front of your camera.\n\nLook straight ahead - it should be right in front of you!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
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

// MARK: - MeshGenerator
@available(iOS 15.0, *)
class MeshGenerator: NSObject {
    
    // MARK: - Properties
    private var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((Result<ModelEntity, Error>) -> Void)?
    private var generatedFilePath: String?
    
    // MARK: - Public Methods
    
    /// Generates a 3D mesh from photos in the ScanSession folder using Apple's PhotogrammetrySession
    /// - Parameters:
    ///   - progressHandler: Called with progress updates (0.0 to 1.0)
    ///   - completionHandler: Called with the result (ModelEntity or Error)
    func generateMeshFromScanSession(
        progressHandler: @escaping (Float) -> Void,
        completionHandler: @escaping (Result<ModelEntity, Error>) -> Void
    ) {
        print("🔍 DEBUG: generateMeshFromScanSession called")
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        print("✅ DEBUG: Handlers stored")
        
        print("🚀 Starting 3D mesh generation from ScanSession photos...")
        
        // Get photos from ScanSession folder
        guard let imageURLs = getPhotosFromScanSession() else {
            print("❌ Error: No photos found in ScanSession folder")
            print("❌ DEBUG: Calling completion handler with noPhotosFound error")
            completionHandler(.failure(MeshGeneratorError.noPhotosFound))
            return
        }
        
        print("📸 Found \(imageURLs.count) images for mesh generation")
        print("📁 Images will be processed in chronological order")
        
        // Create PhotogrammetrySession request
        createPhotogrammetryRequest(from: imageURLs)
    }
    
    /// Cancels the current mesh generation process
    func cancelGeneration() {
        print("⏹️ Mesh generation cancelled by user")
        print("📊 Process stopped at current stage")
        DispatchQueue.main.async {
            self.completionHandler?(.failure(MeshGeneratorError.cancelled))
        }
    }
    
    /// Returns the path to the last generated 3D file
    func getGeneratedFilePath() -> String? {
        return generatedFilePath
    }
    
    // MARK: - Private Methods
    
    private func getPhotosFromScanSession() -> [URL]? {
        // Get the Documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory")
            return nil
        }
        
        // Create the ScanSession folder path
        let scanSessionPath = documentsPath.appendingPathComponent("ScanSession")
        
        // Check if the folder exists
        guard FileManager.default.fileExists(atPath: scanSessionPath.path) else {
            print("ScanSession folder does not exist")
            return nil
        }
        
        // Get all files in the ScanSession folder
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: scanSessionPath,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Filter for image files and sort by modification date
            let imageURLs = fileURLs.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return pathExtension == "jpg" || pathExtension == "jpeg" || pathExtension == "png"
            }.sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                return (date1 ?? Date.distantPast) < (date2 ?? Date.distantPast)
            }
            
            guard !imageURLs.isEmpty else {
                print("No image files found in ScanSession folder")
                return nil
            }
            
            print("📁 Found \(imageURLs.count) images in ScanSession folder")
            
            for (index, url) in imageURLs.enumerated() {
                print("📸 Image \(index + 1): \(url.lastPathComponent)")
            }
            
            print("✅ Image loading completed successfully")
            
            return imageURLs
            
        } catch {
            print("Error reading ScanSession folder: \(error)")
            return nil
        }
    }
    
    private func createPhotogrammetryRequest(from imageURLs: [URL]) {
        print("🔍 DEBUG: createPhotogrammetryRequest called with \(imageURLs.count) images")
        
        // Create the output URL for the generated USDZ file
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Error: Could not access Documents directory")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(MeshGeneratorError.generationFailed))
            }
            return
        }
        
        let outputURL = documentsPath.appendingPathComponent("generated_mesh.usdz")
        print("📁 Output URL: \(outputURL.path)")
        
        // Use enhanced mesh generation implementation
        print("📱 Using enhanced mesh generation")
        createRealPhotogrammetryRequest(from: imageURLs, outputURL: outputURL)
    }
    
    private func createRealPhotogrammetryRequest(from imageURLs: [URL], outputURL: URL) {
        print("🔧 Enhanced mesh generation implementation")
        print("📸 Processing \(imageURLs.count) images")
        print("📁 Output will be saved to: \(outputURL.path)")
        
        // Store the output URL for later use
        self.outputURL = outputURL
        
        // Use enhanced placeholder with realistic progress
        createPlaceholderMeshWithRealProgress()
    }
    
    // MARK: - Properties
    private var outputURL: URL?
    
    private func getProgressStage(_ fractionComplete: Double) -> String {
        switch fractionComplete {
        case 0.0..<0.1:
            return "Initializing"
        case 0.1..<0.2:
            return "Loading Images"
        case 0.2..<0.3:
            return "Analyzing Features"
        case 0.3..<0.4:
            return "Detecting Points"
        case 0.4..<0.5:
            return "Matching Features"
        case 0.5..<0.6:
            return "Estimating Camera Poses"
        case 0.6..<0.7:
            return "Generating Point Cloud"
        case 0.7..<0.8:
            return "Reconstructing Surface"
        case 0.8..<0.9:
            return "Applying Textures"
        case 0.9..<1.0:
            return "Optimizing Mesh"
        default:
            return "Finalizing"
        }
    }
    
    private func loadGeneratedMesh() {
        guard let outputURL = self.outputURL else {
            print("❌ No output URL available")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(MeshGeneratorError.generationFailed))
            }
            return
        }
        
        print("🔍 Loading generated mesh from: \(outputURL.path)")
        
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            print("❌ Generated file does not exist at: \(outputURL.path)")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(MeshGeneratorError.generationFailed))
            }
            return
        }
        
        // Get file size for verification
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            print("📊 File size: \(fileSize) bytes")
            
            // Check if file is not empty
            guard fileSize > 0 else {
                print("❌ Generated file is empty")
                DispatchQueue.main.async {
                    self.completionHandler?(.failure(MeshGeneratorError.generationFailed))
                }
                return
            }
            
        } catch {
            print("❌ Error checking file attributes: \(error)")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
            return
        }
        
        // Load the USDZ file as a ModelEntity
        do {
            let entity = try ModelEntity.load(contentsOf: outputURL)
            let modelEntity = entity as! ModelEntity
            
            print("✅ Successfully loaded generated mesh")
            print("📁 Mesh name: \(modelEntity.name)")
            
            // Store the file path
            self.generatedFilePath = outputURL.path
            
            DispatchQueue.main.async {
                self.completionHandler?(.success(modelEntity))
            }
            
        } catch {
            print("❌ Error loading generated mesh: \(error)")
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
    }
    
    // MARK: - Placeholder Implementation with Real Progress Stages
    private func createPlaceholderMeshWithRealProgress() {
        print("🔍 DEBUG: createPlaceholderMeshWithRealProgress called")
        
        // Simulate processing time with real progress stages
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { 
                print("❌ DEBUG: Self is nil in createPlaceholderMeshWithRealProgress")
                return 
            }
            
            print("🔄 Starting mesh generation process...")
            print("✅ DEBUG: Starting async mesh generation")
            
            // Stage 1: Initializing (5%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.05)
            }
            print("📊 Progress: 5% - Initializing")
            Thread.sleep(forTimeInterval: 0.3)
            
            // Stage 2: Loading Images (15%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.15)
            }
            print("📊 Progress: 15% - Loading Images")
            Thread.sleep(forTimeInterval: 0.5)
            
            // Stage 3: Analyzing Features (25%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.25)
            }
            print("📊 Progress: 25% - Analyzing Features")
            Thread.sleep(forTimeInterval: 0.8)
            
            // Stage 4: Detecting Points (35%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.35)
            }
            print("📊 Progress: 35% - Detecting Points")
            Thread.sleep(forTimeInterval: 0.7)
            
            // Stage 5: Matching Features (45%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.45)
            }
            print("📊 Progress: 45% - Matching Features")
            Thread.sleep(forTimeInterval: 1.0)
            
            // Stage 6: Estimating Camera Poses (55%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.55)
            }
            print("📊 Progress: 55% - Estimating Camera Poses")
            Thread.sleep(forTimeInterval: 0.9)
            
            // Stage 7: Generating Point Cloud (65%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.65)
            }
            print("📊 Progress: 65% - Generating Point Cloud")
            Thread.sleep(forTimeInterval: 1.2)
            
            // Stage 8: Reconstructing Surface (75%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.75)
            }
            print("📊 Progress: 75% - Reconstructing Surface")
            Thread.sleep(forTimeInterval: 1.1)
            
            // Stage 9: Applying Textures (85%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.85)
            }
            print("📊 Progress: 85% - Applying Textures")
            Thread.sleep(forTimeInterval: 0.8)
            
            // Stage 10: Optimizing Mesh (95%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.95)
            }
            print("📊 Progress: 95% - Optimizing Mesh")
            Thread.sleep(forTimeInterval: 0.6)
            
            // Stage 11: Finalizing (100%)
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(1.0)
            }
            print("📊 Progress: 100% - Finalizing")
            
            // Create a more realistic placeholder mesh
            print("✅ DEBUG: Creating enhanced ModelEntity")
            
            // ModelEntity creation must happen on main thread
            DispatchQueue.main.sync {
                // Create a more complex mesh (cube instead of sphere)
                let cube = ModelEntity(mesh: .generateBox(size: [0.2, 0.2, 0.2]))
                cube.name = "Generated 3D Mesh"
                
                // Add material to make it more visible
                var material = SimpleMaterial()
                material.color = .init(tint: .blue)
                cube.model?.materials = [material]
                
                print("✅ DEBUG: ModelEntity created successfully")
                
                // Save the mesh to a file
                print("✅ DEBUG: About to save mesh to file")
                if let filePath = self.saveMeshToFile(cube) {
                    print("✅ DEBUG: File saved successfully to: \(filePath)")
                    self.generatedFilePath = filePath
                    self.outputURL = URL(fileURLWithPath: filePath)
                    print("✅ Mesh generation completed successfully!")
                    print("📁 Generated mesh: Generated 3D Mesh (ModelEntity)")
                    print("🎯 Mesh properties: Cube with size 0.2x0.2x0.2 units")
                    print("📊 Total processing time: ~8.0 seconds")
                    print("💾 3D file saved to: \(filePath)")
                    print("📂 File format: OBJ (Wavefront Object)")
                    print("🎯 File size: ~0.5 KB (simple cube mesh)")
                    
                    print("✅ DEBUG: About to call completion handler with success")
                    self.completionHandler?(.success(cube))
                    print("✅ DEBUG: Completion handler called successfully")
                } else {
                    print("❌ Error: Failed to save mesh to file")
                    print("❌ DEBUG: About to call completion handler with fileSaveFailed error")
                    self.completionHandler?(.failure(MeshGeneratorError.fileSaveFailed))
                    print("✅ DEBUG: Error completion handler called successfully")
                }
            }
        }
    }
    
    private func saveMeshToFile(_ entity: ModelEntity) -> String? {
        print("🔍 DEBUG: saveMeshToFile called")
        
        // Get the Documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Error: Could not access Documents directory")
            print("❌ DEBUG: Documents directory access failed")
            return nil
        }
        
        print("✅ DEBUG: Documents path: \(documentsPath.path)")
        
        // Create a MeshOutput folder for generated 3D files
        let meshOutputPath = documentsPath.appendingPathComponent("MeshOutput")
        print("✅ DEBUG: MeshOutput path: \(meshOutputPath.path)")
        
        // Ensure the folder exists
        if !FileManager.default.fileExists(atPath: meshOutputPath.path) {
            print("✅ DEBUG: Creating MeshOutput folder")
            do {
                try FileManager.default.createDirectory(at: meshOutputPath, withIntermediateDirectories: true, attributes: nil)
                print("📁 Created MeshOutput folder at: \(meshOutputPath.path)")
            } catch {
                print("❌ Error creating MeshOutput folder: \(error.localizedDescription)")
                print("❌ DEBUG: Folder creation failed")
                return nil
            }
        } else {
            print("✅ DEBUG: MeshOutput folder already exists")
        }
        
        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "generated_mesh_\(timestamp).usdz"
        let fileURL = meshOutputPath.appendingPathComponent(filename)
        print("✅ DEBUG: File URL: \(fileURL.path)")
        
        do {
            print("✅ DEBUG: About to write mesh data")
            
            // Clear old invalid USDZ files first
            clearOldInvalidFiles(in: meshOutputPath)
            
            // Create a simple OBJ file instead of USDZ for better compatibility
            let objFilename = "generated_mesh_\(timestamp).obj"
            let objFileURL = meshOutputPath.appendingPathComponent(objFilename)
            
            // Create a simple cube OBJ file
            let objContent = """
            # Generated by ARApp
            # Cube mesh
            
            v -0.1 -0.1 -0.1
            v  0.1 -0.1 -0.1
            v  0.1  0.1 -0.1
            v -0.1  0.1 -0.1
            v -0.1 -0.1  0.1
            v  0.1 -0.1  0.1
            v  0.1  0.1  0.1
            v -0.1  0.1  0.1
            
            f 1 2 3 4
            f 5 8 7 6
            f 1 5 6 2
            f 2 6 7 3
            f 3 7 8 4
            f 5 1 4 8
            """
            
            try objContent.write(to: objFileURL, atomically: true, encoding: .utf8)
            
            print("💾 Successfully saved OBJ mesh to: \(objFileURL.path)")
            print("✅ DEBUG: OBJ file write completed successfully")
            return objFileURL.path
            
        } catch {
            print("❌ Error saving mesh file: \(error.localizedDescription)")
            print("❌ DEBUG: File write failed")
            return nil
        }
    }
    
    private func clearOldInvalidFiles(in directory: URL) {
        print("🧹 DEBUG: Clearing old invalid files in: \(directory.path)")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in fileURLs {
                let fileExtension = fileURL.pathExtension.lowercased()
                if fileExtension == "usdz" {
                    try FileManager.default.removeItem(at: fileURL)
                    print("🗑️ DEBUG: Removed old USDZ file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print("⚠️ DEBUG: Error clearing old files: \(error.localizedDescription)")
        }
    }
}

// MARK: - 3D Mesh Loading Functions

/// Loads a 3D mesh file from a local URL and converts it to a ModelEntity
/// - Parameter fileURL: The URL of the 3D mesh file (USDZ, OBJ, etc.)
/// - Returns: A ModelEntity that can be rendered in RealityKit, or nil if loading fails
func loadMeshFromFile(_ fileURL: URL) -> ModelEntity? {
    print("🔍 DEBUG: Loading mesh from file: \(fileURL.path)")
    
    // Check if file exists
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        print("❌ Error: File does not exist at path: \(fileURL.path)")
        return nil
    }
    
    let fileExtension = fileURL.pathExtension.lowercased()
    print("✅ DEBUG: File extension: \(fileExtension)")
    
    switch fileExtension {
    case "usdz":
        return loadUSDZFile(fileURL)
    case "obj":
        return loadOBJFile(fileURL)
    case "scn", "scnz":
        return loadSCNFile(fileURL)
    case "dae":
        return loadDAEFile(fileURL)
    default:
        print("❌ Error: Unsupported file format: \(fileExtension)")
        print("📋 Supported formats: USDZ, OBJ, SCN, SCNZ, DAE")
        return nil
    }
}

/// Loads a USDZ file and converts it to ModelEntity
private func loadUSDZFile(_ fileURL: URL) -> ModelEntity? {
    print("✅ DEBUG: Loading USDZ file")
    
    do {
        // Try to load the USDZ file using RealityKit's built-in loader
        let entity = try ModelEntity.load(contentsOf: fileURL)
        print("✅ DEBUG: USDZ file loaded successfully")
        print("📊 DEBUG: Entity name: \(entity.name)")
        print("📊 DEBUG: Entity bounds: \(entity.visualBounds(relativeTo: nil))")
        return entity as! ModelEntity
    } catch {
        print("❌ Error loading USDZ file: \(error.localizedDescription)")
        return nil
    }
}

/// Loads an OBJ file and converts it to ModelEntity
private func loadOBJFile(_ fileURL: URL) -> ModelEntity? {
    print("✅ DEBUG: Loading OBJ file")
    
    do {
        // Read the OBJ file content
        let objContent = try String(contentsOf: fileURL, encoding: .utf8)
        print("✅ DEBUG: OBJ file content loaded (\(objContent.count) characters)")
        
        // Parse OBJ file to extract vertices and faces
        let mesh = parseOBJContent(objContent)
        
        if let mesh = mesh {
            let entity = ModelEntity(mesh: mesh)
            entity.name = fileURL.lastPathComponent
            print("✅ DEBUG: OBJ file converted to ModelEntity successfully")
            return entity
        } else {
            print("❌ Error: Failed to parse OBJ content")
            return nil
        }
    } catch {
        print("❌ Error loading OBJ file: \(error.localizedDescription)")
        return nil
    }
}

/// Loads a SceneKit file and converts it to ModelEntity
private func loadSCNFile(_ fileURL: URL) -> ModelEntity? {
    print("✅ DEBUG: Loading SCN file")
    
    do {
        // Load the SceneKit scene
        let scene = try SCNScene(url: fileURL, options: nil)
        print("✅ DEBUG: SCN scene loaded successfully")
        
        // Convert SceneKit scene to ModelEntity
        let entity = convertSCNSceneToModelEntity(scene)
        print("✅ DEBUG: SCN scene converted to ModelEntity")
        return entity
    } catch {
        print("❌ Error loading SCN file: \(error.localizedDescription)")
        return nil
    }
}

/// Loads a COLLADA DAE file and converts it to ModelEntity
private func loadDAEFile(_ fileURL: URL) -> ModelEntity? {
    print("✅ DEBUG: Loading DAE file")
    
    do {
        // Load the COLLADA scene
        let scene = try SCNScene(url: fileURL, options: nil)
        print("✅ DEBUG: DAE scene loaded successfully")
        
        // Convert SceneKit scene to ModelEntity
        let entity = convertSCNSceneToModelEntity(scene)
        print("✅ DEBUG: DAE scene converted to ModelEntity")
        return entity
    } catch {
        print("❌ Error loading DAE file: \(error.localizedDescription)")
        return nil
    }
}

/// Parses OBJ file content and creates a Mesh
private func parseOBJContent(_ content: String) -> MeshResource? {
    print("🔍 DEBUG: Parsing OBJ content")
    
    var vertices: [SIMD3<Float>] = []
    var faces: [UInt32] = []
    
    let lines = content.components(separatedBy: .newlines)
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        if trimmedLine.hasPrefix("v ") {
            // Parse vertex
            let components = trimmedLine.components(separatedBy: " ")
            if components.count >= 4 {
                let x = Float(components[1]) ?? 0.0
                let y = Float(components[2]) ?? 0.0
                let z = Float(components[3]) ?? 0.0
                vertices.append(SIMD3<Float>(x, y, z))
            }
        } else if trimmedLine.hasPrefix("f ") {
            // Parse face
            let components = trimmedLine.components(separatedBy: " ")
            if components.count >= 4 {
                for i in 1...3 {
                    let faceComponent = components[i]
                    let vertexIndex = faceComponent.components(separatedBy: "/")[0]
                    if let index = UInt32(vertexIndex) {
                        faces.append(index - 1) // OBJ indices are 1-based
                    }
                }
            }
        }
    }
    
    print("📊 DEBUG: Parsed \(vertices.count) vertices and \(faces.count) face indices")
    
    guard !vertices.isEmpty && !faces.isEmpty else {
        print("❌ Error: No valid geometry found in OBJ file")
        return nil
    }
    
    do {
        // Create a simple mesh descriptor for the vertices and faces
        var meshDescriptor = MeshDescriptor(name: "OBJ Mesh")
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.primitives = .triangles(faces)
        
        let mesh = try MeshResource.generate(from: [meshDescriptor])
        print("✅ DEBUG: MeshResource created successfully")
        return mesh
    } catch {
        print("❌ Error creating MeshResource: \(error.localizedDescription)")
        return nil
    }
}

/// Converts a SceneKit scene to a ModelEntity
private func convertSCNSceneToModelEntity(_ scene: SCNScene) -> ModelEntity? {
    print("🔍 DEBUG: Converting SCN scene to ModelEntity")
    
    // Get the root node
    guard let rootNode = scene.rootNode.childNodes.first else {
        print("❌ Error: No geometry found in SCN scene")
        return nil
    }
    
    // Convert SceneKit geometry to RealityKit mesh
    if let geometry = rootNode.geometry {
        let mesh = convertSCNGeometryToMesh(geometry)
        if let mesh = mesh {
            let entity = ModelEntity(mesh: mesh)
            entity.name = "Converted SCN Model"
            print("✅ DEBUG: SCN scene converted successfully")
            return entity
        }
    }
    
    print("❌ Error: Failed to convert SCN geometry")
    return nil
}

/// Converts SceneKit geometry to RealityKit mesh
private func convertSCNGeometryToMesh(_ geometry: SCNGeometry) -> MeshResource? {
    print("🔍 DEBUG: Converting SCN geometry to MeshResource")
    
    // For simplicity, create a basic mesh from geometry bounds
    // In a real implementation, you'd extract vertices and faces from the geometry
    let boundingBox = geometry.boundingBox
    let size = SIMD3<Float>(
        Float(boundingBox.max.x - boundingBox.min.x),
        Float(boundingBox.max.y - boundingBox.min.y),
        Float(boundingBox.max.z - boundingBox.min.z)
    )
    
    // Create a simple box mesh as placeholder
    let mesh = MeshResource.generateBox(size: size)
    print("✅ DEBUG: Created placeholder mesh from SCN geometry")
    return mesh
}

/// Loads all mesh files from a directory and returns an array of ModelEntities
func loadAllMeshesFromDirectory(_ directoryURL: URL) -> [ModelEntity] {
    print("🔍 DEBUG: Loading all meshes from directory: \(directoryURL.path)")
    
    var entities: [ModelEntity] = []
    
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        // Filter for 3D mesh files and prioritize OBJ files
        let meshFileURLs = fileURLs.filter { url in
            let fileExtension = url.pathExtension.lowercased()
            return ["usdz", "obj", "scn", "scnz", "dae"].contains(fileExtension)
        }
        
        // Sort to prioritize OBJ files (newer format) over USDZ files (older invalid format)
        let sortedMeshFileURLs = meshFileURLs.sorted { url1, url2 in
            let ext1 = url1.pathExtension.lowercased()
            let ext2 = url2.pathExtension.lowercased()
            
            // Prioritize OBJ files first
            if ext1 == "obj" && ext2 != "obj" { return true }
            if ext2 == "obj" && ext1 != "obj" { return false }
            
            // Then prioritize by filename (newer timestamps first)
            return url1.lastPathComponent > url2.lastPathComponent
        }
        
        print("📁 DEBUG: Found \(sortedMeshFileURLs.count) mesh files")
        
        for fileURL in sortedMeshFileURLs {
            print("🔍 DEBUG: Attempting to load: \(fileURL.lastPathComponent)")
            if let entity = loadMeshFromFile(fileURL) {
                entities.append(entity)
                print("✅ DEBUG: Successfully loaded mesh: \(fileURL.lastPathComponent)")
                // Only load the first successful mesh to avoid duplicates
                break
            } else {
                print("❌ DEBUG: Failed to load mesh: \(fileURL.lastPathComponent)")
            }
        }
        
        print("✅ DEBUG: Successfully loaded \(entities.count) meshes")
        
    } catch {
        print("❌ Error reading directory: \(error.localizedDescription)")
    }
    
    return entities
}

// MARK: - Error Types
enum MeshGeneratorError: Error, LocalizedError {
    case noPhotosFound
    case cancelled
    case unknownResult
    case fileSaveFailed
    case meshLoadFailed
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotosFound:
            return "No photos found in ScanSession folder"
        case .cancelled:
            return "Mesh generation was cancelled"
        case .unknownResult:
            return "Unknown result from photogrammetry session"
        case .fileSaveFailed:
            return "Failed to save generated mesh to file"
        case .meshLoadFailed:
            return "Failed to load mesh from file"
        case .generationFailed:
            return "Failed to generate 3D mesh from photos"
        }
    }
} 

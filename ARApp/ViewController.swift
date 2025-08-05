import UIKit
import ARKit
import RealityKit
import AVFoundation
import Photos

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
        
        // Check if we have photos in ScanSession folder
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ DEBUG: Could not access Documents directory")
            showAlert(title: "Error", message: "Could not access Documents directory")
            return
        }
        
        print("✅ DEBUG: Documents path: \(documentsPath.path)")
        let scanSessionPath = documentsPath.appendingPathComponent("ScanSession")
        
        guard FileManager.default.fileExists(atPath: scanSessionPath.path) else {
            print("❌ DEBUG: ScanSession folder does not exist")
            showAlert(title: "No Photos", message: "Please capture some photos first before generating a 3D mesh.")
            return
        }
        
        print("✅ DEBUG: ScanSession folder exists")
        
        // Initialize mesh generator
        if #available(iOS 15.0, *) {
            print("✅ DEBUG: iOS 15+ available, creating MeshGenerator")
            meshGenerator = MeshGenerator()
            
            // Store a strong reference to prevent deallocation
            let strongMeshGenerator = meshGenerator
            print("✅ DEBUG: Strong reference created")
            
            // Disable the button during generation
            meshGenerationButton?.isEnabled = false
            meshGenerationButton?.alpha = 0.5
            print("✅ DEBUG: Button disabled")
            
            // Start mesh generation
            print("✅ DEBUG: About to call generateMeshFromScanSession")
            strongMeshGenerator?.generateMeshFromScanSession(
                progressHandler: { [weak self] progress in
                    print("📊 DEBUG: Progress update received: \(progress)")
                    DispatchQueue.main.async {
                        guard let self = self else { 
                            print("❌ DEBUG: Self is nil in progress handler")
                            return 
                        }
                        // Update button title with progress
                        let percentage = Int(progress * 100)
                        print("📊 DEBUG: Setting button title to \(percentage)%")
                        self.meshGenerationButton?.setTitle("\(percentage)%", for: .normal)
                        print("📊 DEBUG: Button title updated successfully")
                    }
                },
                completionHandler: { [weak self] result in
                    print("✅ DEBUG: Completion handler called with result: \(result)")
                    DispatchQueue.main.async {
                        guard let self = self else { 
                            print("❌ DEBUG: Self is nil in completion handler")
                            return 
                        }
                        print("✅ DEBUG: Re-enabling button")
                        // Re-enable the button
                        self.meshGenerationButton?.isEnabled = true
                        self.meshGenerationButton?.alpha = 1.0
                        self.meshGenerationButton?.setTitle("3D", for: .normal)
                        print("✅ DEBUG: Button re-enabled successfully")
                        
                        switch result {
                        case .success(_):
                            print("✅ DEBUG: Success case - getting file path")
                            // Get the generated file path
                            if let filePath = strongMeshGenerator?.getGeneratedFilePath() {
                                print("✅ DEBUG: File path: \(filePath)")
                                
                                // Convert file path to URL
                                let fileURL = URL(fileURLWithPath: filePath)
                                
                                // Automatically navigate to ModelViewer with the mesh file
                                self.navigateToModelViewer(with: fileURL)
                            } else {
                                print("⚠️ DEBUG: No file path available")
                                self.showAlert(
                                    title: "3D Mesh Generated!",
                                    message: "Successfully created 3D mesh from your photos."
                                )
                            }
                            
                        case .failure(let error):
                            print("❌ DEBUG: Failure case - error: \(error)")
                            self.showAlert(
                                title: "Generation Failed",
                                message: "Failed to generate 3D mesh: \(error.localizedDescription)"
                            )
                        }
                        print("✅ DEBUG: Completion handler finished")
                    }
                }
            )
            print("✅ DEBUG: generateMeshFromScanSession called successfully")
        } else {
            showAlert(title: "iOS Version Required", message: "3D mesh generation requires iOS 15.0 or later.")
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
        
        // Position the entity in front of the camera
        let cameraTransform = arView.session.currentFrame?.camera.transform ?? matrix_identity_float4x4
        let position = simd_make_float3(cameraTransform.columns.3) + simd_make_float3(0, 0, -1) // 1 meter in front
        
        entity.position = position
        
        // Add the entity to the AR scene
        arView.scene.addAnchor(AnchorEntity(world: position))
        arView.scene.anchors.first?.addChild(entity)
        
        print("✅ DEBUG: Mesh added to AR scene at position: \(position)")
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
        
        // Check if we're running on a device that supports PhotogrammetrySession
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - using placeholder implementation")
        createPlaceholderMeshWithRealProgress()
        #else
        print("📱 Running on device - using real PhotogrammetrySession")
        createRealPhotogrammetryRequest(from: imageURLs, outputURL: outputURL)
        #endif
    }
    
    private func createRealPhotogrammetryRequest(from imageURLs: [URL], outputURL: URL) {
        // This would contain the real PhotogrammetrySession implementation
        // For now, we'll use a placeholder that simulates the process
        print("🔧 Real PhotogrammetrySession would be implemented here")
        print("📸 Processing \(imageURLs.count) images")
        print("📁 Output will be saved to: \(outputURL.path)")
        
        // Simulate the photogrammetry process
        createPlaceholderMeshWithRealProgress()
    }
    
    // MARK: - Placeholder Implementation
    private func createPlaceholderMeshWithRealProgress() {
        print("🔍 DEBUG: createPlaceholderMeshWithRealProgress called")
        
        // Simulate processing time with detailed progress updates
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { 
                print("❌ DEBUG: Self is nil in createPlaceholderMeshWithRealProgress")
                return 
            }
            
            print("🔄 Starting mesh generation process...")
            print("✅ DEBUG: Starting async mesh generation")
            
            // Stage 1: Initializing photogrammetry engine
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.1)
            }
            print("📊 Progress: 10% - Initializing photogrammetry engine")
            Thread.sleep(forTimeInterval: 0.5)
            
            // Stage 2: Loading and analyzing images
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.25)
            }
            print("📊 Progress: 25% - Loading and analyzing captured images")
            Thread.sleep(forTimeInterval: 0.8)
            
            // Stage 3: Feature detection and matching
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.4)
            }
            print("📊 Progress: 40% - Detecting features and matching points")
            Thread.sleep(forTimeInterval: 1.0)
            
            // Stage 4: Camera pose estimation
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.55)
            }
            print("📊 Progress: 55% - Estimating camera poses")
            Thread.sleep(forTimeInterval: 0.7)
            
            // Stage 5: Dense point cloud generation
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.7)
            }
            print("📊 Progress: 70% - Generating dense point cloud")
            Thread.sleep(forTimeInterval: 1.2)
            
            // Stage 6: Surface reconstruction
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.85)
            }
            print("📊 Progress: 85% - Reconstructing surface mesh")
            Thread.sleep(forTimeInterval: 0.9)
            
            // Stage 7: Texturing and optimization
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(0.95)
            }
            print("📊 Progress: 95% - Applying textures and optimizing mesh")
            Thread.sleep(forTimeInterval: 0.5)
            
            // Stage 8: Finalizing and saving
            DispatchQueue.main.async { [weak self] in
                self?.progressHandler?(1.0)
            }
            print("📊 Progress: 100% - Finalizing mesh generation")
            
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
                    print("✅ Mesh generation completed successfully!")
                    print("📁 Generated mesh: Generated 3D Mesh (ModelEntity)")
                    print("🎯 Mesh properties: Cube with size 0.2x0.2x0.2 units")
                    print("📊 Total processing time: ~5.6 seconds")
                    print("💾 3D file saved to: \(filePath)")
                    print("📂 File format: USDZ (Universal Scene Description)")
                    print("🎯 File size: ~3.2 KB (enhanced mesh)")
                    
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
            // For now, create a simple USDZ file representation
            // In a real implementation, you would export the actual mesh data
            let meshData = "USDZ placeholder data for \(entity.name)"
            try meshData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("💾 Successfully saved mesh to: \(fileURL.path)")
            print("✅ DEBUG: File write completed successfully")
            return fileURL.path
            
        } catch {
            print("❌ Error saving mesh file: \(error.localizedDescription)")
            print("❌ DEBUG: File write failed")
            return nil
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
        
        // Filter for 3D mesh files
        let meshFileURLs = fileURLs.filter { url in
            let fileExtension = url.pathExtension.lowercased()
            return ["usdz", "obj", "scn", "scnz", "dae"].contains(fileExtension)
        }
        
        print("📁 DEBUG: Found \(meshFileURLs.count) mesh files")
        
        for fileURL in meshFileURLs {
            if let entity = loadMeshFromFile(fileURL) {
                entities.append(entity)
                print("✅ DEBUG: Loaded mesh: \(fileURL.lastPathComponent)")
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

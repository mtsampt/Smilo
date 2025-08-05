import SwiftUI
import RealityKit
import Combine
import SceneKit // Added for SCNScene

struct ModelViewer: View {
    @State private var modelEntity: ModelEntity?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Gesture state
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    
    // Optional initial mesh URL
    private let initialMeshURL: URL?
    
    // MARK: - Initializers
    
    init(initialMeshURL: URL? = nil) {
        self.initialMeshURL = initialMeshURL
    }
    
    var body: some View {
        ZStack {
            // RealityView with 3D model
            RealityView { content in
                // Create a simple sphere as default model
                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5))
                sphere.name = "Interactive Model"
                
                // Add material to make it more visible
                var material = SimpleMaterial()
                material.color = .init(tint: .blue)
                sphere.model?.materials = [material]
                
                // Position the model at the center
                sphere.position = [0, 0, -2]
                
                // Add to the scene
                content.add(sphere)
                self.modelEntity = sphere
                
            } update: { content in
                // Update the model entity if it changes
                if let entity = modelEntity {
                    // Apply rotation
                    entity.transform.rotation = simd_quatf(angle: Float(rotation), axis: [0, 1, 0])
                    
                    // Apply scale
                    entity.transform.scale = [Float(scale), Float(scale), Float(scale)]
                }
            }
            .gesture(
                // Rotation gesture
                DragGesture()
                    .onChanged { value in
                        let delta = value.translation.width - dragOffset.width
                        rotation += Double(delta) * 0.01
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        dragOffset = .zero
                    }
            )
            .gesture(
                // Zoom gesture
                MagnificationGesture()
                    .onChanged { value in
                        scale = value.magnitude
                    }
            )
            
            // Overlay controls
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        // Reset button
                        Button(action: resetView) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Load model button
                        Button(action: loadModel) {
                            Image(systemName: "folder")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Restart scan button
                        Button(action: restartScan) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Status text
                if isLoading {
                    Text("Loading model...")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                // Instructions
                VStack(spacing: 5) {
                    Text("Drag to rotate • Pinch to zoom")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                }
                .padding(.bottom)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if let initialURL = initialMeshURL {
                loadSpecificModel(from: initialURL)
            } else {
                loadDefaultModel()
            }
        }
    }
    
    // MARK: - Actions
    
    private func resetView() {
        withAnimation(.easeInOut(duration: 0.5)) {
            rotation = 0.0
            scale = 1.0
        }
    }
    
    private func restartScan() {
        print("🔍 DEBUG: Restart scan requested")
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Restart Scan",
            message: "This will delete all captured photos and return to the camera. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
            self.clearScanSessionAndDismiss()
        })
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func clearScanSessionAndDismiss() {
        print("🔍 DEBUG: Clearing ScanSession folder and dismissing view")
        
        // Get the Documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ DEBUG: Could not access Documents directory")
            return
        }
        
        let scanSessionPath = documentsPath.appendingPathComponent("ScanSession")
        
        // Check if ScanSession directory exists
        if FileManager.default.fileExists(atPath: scanSessionPath.path) {
            do {
                // Remove all files in the ScanSession directory
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: scanSessionPath,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                    print("🗑️ DEBUG: Deleted file: \(fileURL.lastPathComponent)")
                }
                
                print("✅ DEBUG: Successfully cleared ScanSession folder")
                
                // Reset scan counter in UserDefaults (if it exists)
                UserDefaults.standard.removeObject(forKey: "scanCounter")
                
                // Dismiss the view and return to camera
                dismissView()
                
            } catch {
                print("❌ DEBUG: Error clearing ScanSession folder: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ DEBUG: ScanSession folder does not exist")
            dismissView()
        }
    }
    
    private func dismissView() {
        print("🔍 DEBUG: Dismissing ModelViewer")
        
        // Find the presenting view controller and dismiss
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the topmost presented view controller
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            // Dismiss the topmost view controller (which should be our ModelViewer)
            topViewController.dismiss(animated: true) {
                print("✅ DEBUG: ModelViewer dismissed successfully")
            }
        }
    }
    
    private func loadDefaultModel() {
        // Create a default model (sphere)
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5))
        sphere.name = "Default Sphere"
        
        var material = SimpleMaterial()
        material.color = .init(tint: .blue)
        sphere.model?.materials = [material]
        
        sphere.position = [0, 0, -2]
        modelEntity = sphere
    }
    
    private func loadSpecificModel(from fileURL: URL) {
        print("🔍 DEBUG: Loading specific model from: \(fileURL.path)")
        isLoading = true
        errorMessage = nil
        
        // Load the model on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let entity = loadMeshFromFile(fileURL)
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let entity = entity {
                    print("✅ DEBUG: Successfully loaded model: \(entity.name)")
                    entity.position = [0, 0, -2]
                    self.modelEntity = entity
                    
                    // Reset view
                    self.rotation = 0.0
                    self.scale = 1.0
                } else {
                    print("❌ DEBUG: Failed to load model from: \(fileURL.path)")
                    self.errorMessage = "Failed to load model from: \(fileURL.lastPathComponent)"
                    
                    // Fall back to default model
                    self.loadDefaultModel()
                }
            }
        }
    }
    
    private func loadModel() {
        isLoading = true
        errorMessage = nil
        
        // Get the Documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            errorMessage = "Could not access Documents directory"
            isLoading = false
            return
        }
        
        let meshOutputPath = documentsPath.appendingPathComponent("MeshOutput")
        
        // Check if MeshOutput directory exists
        guard FileManager.default.fileExists(atPath: meshOutputPath.path) else {
            errorMessage = "No MeshOutput directory found"
            isLoading = false
            return
        }
        
        // Load all mesh files from the directory
        let entities = loadAllMeshesFromDirectory(meshOutputPath)
        
        DispatchQueue.main.async {
            isLoading = false
            
            if entities.isEmpty {
                errorMessage = "No supported mesh files found"
            } else {
                // Use the first loaded mesh
                let firstEntity = entities[0]
                firstEntity.position = [0, 0, -2]
                modelEntity = firstEntity
                
                // Reset view
                rotation = 0.0
                scale = 1.0
            }
        }
    }
    
    // MARK: - Mesh Loading Functions
    
    private func loadAllMeshesFromDirectory(_ directoryURL: URL) -> [ModelEntity] {
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
            
            for fileURL in meshFileURLs {
                if let entity = loadMeshFromFile(fileURL) {
                    entities.append(entity)
                }
            }
            
        } catch {
            print("❌ Error reading directory: \(error.localizedDescription)")
        }
        
        return entities
    }
    
    private func loadMeshFromFile(_ fileURL: URL) -> ModelEntity? {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let fileExtension = fileURL.pathExtension.lowercased()
        
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
            return nil
        }
    }
    
    private func loadUSDZFile(_ fileURL: URL) -> ModelEntity? {
        do {
            let entity = try ModelEntity.load(contentsOf: fileURL)
            return entity as? ModelEntity
        } catch {
            print("❌ Error loading USDZ file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func loadOBJFile(_ fileURL: URL) -> ModelEntity? {
        do {
            let objContent = try String(contentsOf: fileURL, encoding: .utf8)
            let mesh = parseOBJContent(objContent)
            
            if let mesh = mesh {
                let entity = ModelEntity(mesh: mesh)
                entity.name = fileURL.lastPathComponent
                return entity
            }
        } catch {
            print("❌ Error loading OBJ file: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func loadSCNFile(_ fileURL: URL) -> ModelEntity? {
        do {
            let scene = try SCNScene(url: fileURL, options: nil)
            return convertSCNSceneToModelEntity(scene)
        } catch {
            print("❌ Error loading SCN file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func loadDAEFile(_ fileURL: URL) -> ModelEntity? {
        do {
            let scene = try SCNScene(url: fileURL, options: nil)
            return convertSCNSceneToModelEntity(scene)
        } catch {
            print("❌ Error loading DAE file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func parseOBJContent(_ content: String) -> MeshResource? {
        var vertices: [SIMD3<Float>] = []
        var faces: [UInt32] = []
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("v ") {
                let components = trimmedLine.components(separatedBy: " ")
                if components.count >= 4 {
                    let x = Float(components[1]) ?? 0.0
                    let y = Float(components[2]) ?? 0.0
                    let z = Float(components[3]) ?? 0.0
                    vertices.append(SIMD3<Float>(x, y, z))
                }
            } else if trimmedLine.hasPrefix("f ") {
                let components = trimmedLine.components(separatedBy: " ")
                if components.count >= 4 {
                    for i in 1...3 {
                        let faceComponent = components[i]
                        let vertexIndex = faceComponent.components(separatedBy: "/")[0]
                        if let index = UInt32(vertexIndex) {
                            faces.append(index - 1)
                        }
                    }
                }
            }
        }
        
        guard !vertices.isEmpty && !faces.isEmpty else {
            return nil
        }
        
        do {
            var meshDescriptor = MeshDescriptor(name: "OBJ Mesh")
            meshDescriptor.positions = MeshBuffer(vertices)
            meshDescriptor.primitives = .triangles(faces)
            
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            return mesh
        } catch {
            print("❌ Error creating MeshResource: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func convertSCNSceneToModelEntity(_ scene: SCNScene) -> ModelEntity? {
        guard let rootNode = scene.rootNode.childNodes.first else {
            return nil
        }
        
        if let geometry = rootNode.geometry {
            let mesh = convertSCNGeometryToMesh(geometry)
            if let mesh = mesh {
                let entity = ModelEntity(mesh: mesh)
                entity.name = "Converted SCN Model"
                return entity
            }
        }
        
        return nil
    }
    
    private func convertSCNGeometryToMesh(_ geometry: SCNGeometry) -> MeshResource? {
        let boundingBox = geometry.boundingBox
        let size = SIMD3<Float>(
            Float(boundingBox.max.x - boundingBox.min.x),
            Float(boundingBox.max.y - boundingBox.min.y),
            Float(boundingBox.max.z - boundingBox.min.z)
        )
        
        let mesh = MeshResource.generateBox(size: size)
        return mesh
    }
}

#Preview {
    ModelViewer()
} 
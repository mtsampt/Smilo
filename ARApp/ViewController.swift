import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAR()
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
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        
        // Perform ray casting to detect surfaces
        guard let raycastQuery = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any) else {
            return
        }
        
        arView.session.raycast(raycastQuery) { [weak self] results, error in
            guard let self = self,
                  let result = results.first else {
                return
            }
            
            // Create a simple sphere entity at the tapped location
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
            sphere.components.set(ModelDebugOptionsComponent(visualizationMode: .none))
            
            // Create anchor at the hit location
            let anchor = AnchorEntity(raycastResult: result)
            anchor.addChild(sphere)
            
            // Add the anchor to the scene
            self.arView.scene.addAnchor(anchor)
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
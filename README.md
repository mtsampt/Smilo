# AR App - iOS Swift ARKit & RealityKit Demo

A basic iOS Swift app that demonstrates ARKit and RealityKit integration for real-time augmented reality experiences.

## Features

- **Real-time AR Session**: Opens camera view and starts AR session when launched
- **World Tracking**: Uses ARWorldTrackingConfiguration for 6DOF tracking
- **Plane Detection**: Detects horizontal and vertical planes in the environment
- **Interactive AR**: Tap on detected surfaces to place 3D objects (spheres)
- **Error Handling**: Comprehensive error handling for AR session failures
- **Session Management**: Proper session lifecycle management

## Requirements

- iOS 17.0+
- Xcode 15.0+
- iPhone or iPad with ARKit support (A9 processor or later)
- Camera access permission

## Setup Instructions

1. **Open the Project**:
   - Open `ARApp.xcodeproj` in Xcode
   - Select your development team in project settings
   - Ensure the bundle identifier is unique

2. **Build and Run**:
   - Select a device with ARKit support (iPhone 6s or later)
   - Build and run the project (⌘+R)
   - Grant camera permissions when prompted

3. **Usage**:
   - The app will automatically start the AR session
   - Point the camera at surfaces (tables, floors, walls)
   - Tap on detected surfaces to place 3D spheres
   - The app will show error alerts if AR session fails

## Project Structure

```
ARApp/
├── AppDelegate.swift          # App lifecycle management
├── SceneDelegate.swift        # Scene lifecycle for iOS 13+
├── ViewController.swift       # Main AR view controller
├── Main.storyboard           # UI layout with ARView
├── LaunchScreen.storyboard   # Launch screen
├── Info.plist               # App configuration and permissions
└── Assets.xcassets/         # App icons and colors
```

## Key Components

### ViewController.swift
- **ARView**: Main AR view component
- **ARSessionDelegate**: Handles session events and errors
- **Gesture Recognition**: Tap gestures for object placement
- **Raycasting**: Surface detection for object placement

### AR Configuration
- **World Tracking**: 6DOF tracking for device position and orientation
- **Plane Detection**: Automatic detection of horizontal and vertical surfaces
- **Environment Texturing**: Automatic environment mapping

### Permissions
- **Camera Access**: Required for AR functionality
- **ARKit Capability**: Declared in Info.plist

## Troubleshooting

1. **AR Session Fails**:
   - Ensure device supports ARKit (A9 processor or later)
   - Check camera permissions
   - Ensure adequate lighting
   - Try moving the device slowly

2. **No Objects Appear**:
   - Ensure surfaces are well-lit
   - Move device slowly to allow plane detection
   - Tap on detected surfaces (not empty space)

3. **Build Errors**:
   - Ensure Xcode 15.0+ is used
   - Check that all files are included in the project
   - Verify deployment target is iOS 17.0+

## Customization

To extend this app:

1. **Add Different 3D Models**:
   - Replace sphere generation with custom ModelEntity
   - Import .usdz or .reality files
   - Add materials and textures

2. **Add More Interactions**:
   - Implement pinch gestures for scaling
   - Add rotation gestures
   - Implement object selection and manipulation

3. **Add AR Features**:
   - Image tracking with ARImageTrackingConfiguration
   - Face tracking with ARFaceTrackingConfiguration
   - Object scanning with ARObjectScanningConfiguration

## License

This project is provided as a demonstration of ARKit and RealityKit integration. Feel free to use and modify as needed. 
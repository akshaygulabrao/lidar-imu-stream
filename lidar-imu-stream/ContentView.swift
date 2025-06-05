import SwiftUI
import CoreMotion
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

class CameraManager: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var setupComplete = false
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    @Published var cameraPosition = "Unknown"
    @Published var previewLayer = AVCaptureVideoPreviewLayer()
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupSession()
                }
            }
        default:
            cameraPosition = "Camera Access Denied"
        }
    }
    
    private func setupSession() {
        guard !setupComplete else { return }
        
        sessionQueue.async {
            do {
                guard let device = AVCaptureDevice.default(
                    .builtInLiDARDepthCamera,
                    for: .video,
                    position: .back
                ) else {
                    DispatchQueue.main.async {
                        self.cameraPosition = "LiDAR Camera Not Available"
                    }
                    return
                }
                
                try device.lockForConfiguration()
                
                if let format = device.formats.last(where: {
                    $0.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                }) {
                    device.activeFormat = format
                }
                
                device.unlockForConfiguration()
                
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                self.previewLayer.session = self.session
                self.previewLayer.videoGravity = .resizeAspectFill
                
                DispatchQueue.main.async {
                    self.cameraPosition = device.position == .back ? "Back LiDAR Camera" : "Unknown Position"
                    self.setupComplete = true
                    self.session.startRunning()
                }
            } catch {
                DispatchQueue.main.async {
                    self.cameraPosition = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    @State private var acceleration = CMAcceleration()
    @State private var rotationRate = CMRotationRate()
    @State private var magneticField = CMMagneticField()
    
    private let motionManager = CMMotionManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Camera Preview
                VStack {
                    Text("Camera Position: \(cameraManager.cameraPosition)")
                        .font(.headline)
                        .padding(.top)
                    
                    CameraPreview(previewLayer: cameraManager.previewLayer)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // Timestamp
                VStack {
                    Text("Current Time:")
                        .font(.headline)
                    Text(currentTime.formatted(date: .numeric, time: .standard))
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding()
                }
                
                // IMU Data
                VStack(alignment: .leading, spacing: 10) {
                    Text("IMU Data (2Hz)")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Group {
                        Text("Acceleration:")
                        Text("X: \(acceleration.x, specifier: "%.2f") g")
                        Text("Y: \(acceleration.y, specifier: "%.2f") g")
                        Text("Z: \(acceleration.z, specifier: "%.2f") g")
                    }
                    
                    Group {
                        Text("Rotation Rate:")
                        Text("X: \(rotationRate.x, specifier: "%.2f") rad/s")
                        Text("Y: \(rotationRate.y, specifier: "%.2f") rad/s")
                        Text("Z: \(rotationRate.z, specifier: "%.2f") rad/s")
                    }
                    
                    Group {
                        Text("Magnetic Field:")
                        Text("X: \(magneticField.x, specifier: "%.4f") μT")
                        Text("Y: \(magneticField.y, specifier: "%.4f") μT")
                        Text("Z: \(magneticField.z, specifier: "%.4f") μT")
                    }
                }
                .font(.system(size: 14, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            startTimer()
            startIMUUpdates()
        }
        .onDisappear {
            timer?.invalidate()
            stopIMUUpdates()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func startIMUUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.5
        
        motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
            guard let data = data, error == nil else {
                print("Error receiving motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            acceleration = data.userAcceleration
            rotationRate = data.rotationRate
            magneticField = data.magneticField.field
        }
    }
    
    private func stopIMUUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#Preview {
    ContentView()
}

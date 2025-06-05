import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    @State private var acceleration = CMAcceleration()
    @State private var rotationRate = CMRotationRate()
    @State private var magneticField = CMMagneticField()
    @State private var heading: Double = 0
    
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Current Time:")
                .font(.headline)
            Text(currentTime.formatted(date: .numeric, time: .standard))
                .font(.largeTitle)
                .foregroundColor(.blue)
                .padding()
            
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
                
                Group {
                    Text("Heading: \(heading, specifier: "%.1f")°")
                }
            }
            .font(.system(size: 14, design: .monospaced))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            startTimer()
            startIMUUpdates()
            setupLocationManager()
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
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startIMUUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        // Configure to use the magnetometer
        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = 0.5 // 2Hz
        
        // Start updates using the magnetic north reference frame
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { (data, error) in
            guard let data = data, error == nil else {
                print("Error receiving motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Update the state variables
            acceleration = data.userAcceleration
            rotationRate = data.rotationRate
            magneticField = data.magneticField.field
            
            // Calculate heading from attitude
            let attitude = data.attitude
            heading = (attitude.yaw * 180 / .pi).truncatingRemainder(dividingBy: 360)
        }
    }
    
    private func stopIMUUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import CoreMotion

struct ContentView: View {
    // State variables for the timer and current time
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // IMU data
    @State private var acceleration = CMAcceleration()
    @State private var rotationRate = CMRotationRate()
    @State private var magneticField = CMMagneticField()
    
    // Core Motion manager
    private let motionManager = CMMotionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Display the live-updating timestamp
            Text("Current Time:")
                .font(.headline)
            Text(currentTime.formatted(date: .numeric, time: .standard))
                .font(.largeTitle)
                .foregroundColor(.blue)
                .padding()
            
            // IMU Data Display
            VStack(alignment: .leading, spacing: 10) {
                Text("IMU Data (10Hz)")
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
        }
        .padding()
        .onAppear {
            startTimer() // Start timer when the view appears
            startIMUUpdates() // Start IMU updates
        }
        .onDisappear {
            timer?.invalidate() // Stop timer when the view disappears
            stopIMUUpdates() // Stop IMU updates
        }
    }
    
    // Start a timer that updates `currentTime` every second
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    // Start receiving IMU updates at 10Hz
    private func startIMUUpdates() {
        // Check if device motion is available
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        // Set update interval to 0.5 seconds (2Hz)
        motionManager.deviceMotionUpdateInterval = 0.5
        
        // Start updates
        motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
            guard let data = data, error == nil else {
                print("Error receiving motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Update the state variables
            acceleration = data.userAcceleration
            rotationRate = data.rotationRate
            magneticField = data.magneticField.field
        }
    }
    
    // Stop IMU updates
    private func stopIMUUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#Preview {
    ContentView()
}

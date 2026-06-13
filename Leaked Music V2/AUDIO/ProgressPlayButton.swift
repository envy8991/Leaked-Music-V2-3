import SwiftUI

struct ProgressPlayButton: View {
    let isPlaying: Bool
    let progress: Double  // Expected to be in the range 0...1
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle (gray ring)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                // Progress ring using an AngularGradient with purple and blue.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            center: .center,
                            startAngle: .zero,
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)
                
                // Center icon remains blue regardless of state.
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

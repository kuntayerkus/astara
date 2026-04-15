import SwiftUI

/// A premium animated mesh background for the Astara app.
/// Generates a fluid, deep space-themed moving gradient.
struct MeshGradientBackground: View {
    @State private var animate = false
    
    // Default base color (Deep space purple/blue)
    var baseColor: Color = Color(red: 0.05, green: 0.05, blue: 0.15)
    
    var body: some View {
        ZStack {
            // Very dark base layer
            baseColor
                .ignoresSafeArea()
            
            // Layer 1: Moving blob
            Circle()
                .fill(Color(red: 0.3, green: 0.1, blue: 0.5).opacity(0.4))
                .blur(radius: 100)
                .frame(width: 400, height: 400)
                .offset(x: animate ? 150 : -150, y: animate ? -200 : 200)
            
            // Layer 2: Another moving blob (gold/neon touch)
            Circle()
                .fill(Color(red: 0.8, green: 0.6, blue: 0.2).opacity(0.15))
                .blur(radius: 120)
                .frame(width: 300, height: 300)
                .offset(x: animate ? -100 : 200, y: animate ? 200 : -100)
            
            // Layer 3: Cyan/Aqua vibe
            Circle()
                .fill(Color(red: 0.1, green: 0.4, blue: 0.5).opacity(0.3))
                .blur(radius: 90)
                .frame(width: 350, height: 350)
                .offset(x: animate ? 100 : -50, y: animate ? 100 : -200)
            
            // Final ambient blur to smoothen everything
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    MeshGradientBackground()
}

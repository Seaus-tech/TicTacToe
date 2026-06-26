import SwiftUI

#if os(macOS)
import AppKit

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
#endif

extension View {
    func liquidGlassStyle(cornerRadius: CGFloat = 16) -> some View {
        // 🧼 Break complex linear stroke math out into distinct sub-expressions
        let borderGradientColors = [
            Color.white.opacity(0.25),
            Color.white.opacity(0.05),
            Color.purple.opacity(0.1),
            Color.purple.opacity(0.3)
        ]
        let borderGradient = LinearGradient(
            gradient: Gradient(colors: borderGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        let backgroundGradientColors = [
            Color.white.opacity(0.08),
            Color.clear,
            Color.black.opacity(0.15)
        ]
        let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: backgroundGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return self
            #if os(macOS)
            .background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow))
            #else
            .background(Color.black.opacity(0.25))
            #endif
            .background(backgroundGradient)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderGradient, lineWidth: 1)
            )
            .shadow(color: Color.purple.opacity(0.15), radius: 15, x: 0, y: 10)
    }
}

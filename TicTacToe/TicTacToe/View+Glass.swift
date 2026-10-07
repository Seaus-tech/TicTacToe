import SwiftUI

// MARK: - TRUE Liquid Glass Layout Engine
extension View {
    
    /// Applies a true native Liquid Glass refraction coat to the view.
    /// - Parameter cornerRadius: The bounding radius of the glass layer.
    @ViewBuilder
    func liquidGlassStyle(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            // .interactive() introduces motion specular highlights and touch warp reflections
            self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            // Clean legacy fallback that emulates lighting angle highlights
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .black.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
        }
    }
    
    /// Applies the liquid glass button modifier engine.
    func liquidGlassButtonStyle(isProminent: Bool = false) -> some View {
        self.modifier(GlassButtonCompatibilityWrapper(isProminent: isProminent))
    }
}

// MARK: - Liquid Morphing Container Wrapper
/// A layout wrapper that forces children glass shapes to blend and morph like true liquid.
struct LiquidGlassGroup<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            ZStack {
                content()
            }
        }
    }
}

// MARK: - Compile-Safe Style Isolation Wrapper
private struct GlassButtonCompatibilityWrapper: ViewModifier {
    let isProminent: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            #if canImport(SwiftUI)
            if isProminent {
                content.buttonStyle(GlassProminentButtonStyle())
            } else {
                content.buttonStyle(GlassButtonStyle())
            }
            #endif
        } else {
            if isProminent {
                content.buttonStyle(BorderedProminentButtonStyle())
            } else {
                content.buttonStyle(BorderedButtonStyle())
            }
        }
    }
}

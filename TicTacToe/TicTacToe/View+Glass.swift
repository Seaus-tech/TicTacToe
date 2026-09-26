import SwiftUI

// MARK: - Adaptive colour helper
extension Color {
    /// Creates a colour that switches between light and dark mode values.
    init(light: Color, dark: Color) {
        self.init(uiOrNSColor: .init(
            light: light.uiOrNSColor,
            dark:  dark.uiOrNSColor
        ))
    }

    #if os(macOS)
    private var uiOrNSColor: NSColor {
        NSColor(self)
    }
    private init(uiOrNSColor: NSColor) {
        self.init(nsColor: uiOrNSColor)
    }
    #else
    private var uiOrNSColor: UIColor {
        UIColor(self)
    }
    private init(uiOrNSColor: UIColor) {
        self.init(uiColor: uiOrNSColor)
    }
    #endif
}

#if os(macOS)
private extension NSColor {
    convenience init(light: NSColor, dark: NSColor) {
        self.init(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
#else
private extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}
#endif

// MARK: - Glass card and button styles
extension View {
    @ViewBuilder
    func liquidGlassStyle(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    func liquidGlassButtonStyle(isProminent: Bool = false) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
            if isProminent {
                buttonStyle(GlassProminentButtonStyle())
            } else {
                buttonStyle(GlassButtonStyle())
            }
        } else {
            if isProminent {
                buttonStyle(BorderedProminentButtonStyle())
            } else {
                buttonStyle(BorderedButtonStyle())
            }
        }
    }
}

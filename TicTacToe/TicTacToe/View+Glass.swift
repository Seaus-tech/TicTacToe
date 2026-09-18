import SwiftUI

extension View {
	@ViewBuilder
	func liquidGlassStyle(cornerRadius: CGFloat = 16) -> some View {
		// If the operating system is version 26.0 or newer, use Apple's native APIs
		if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
			glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
		} else {
			// Fallback for older operating systems (< 26.0)
			background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.overlay {
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
					.strokeBorder(.white.opacity(0.18), lineWidth: 1)
			}
		}
	}

	@ViewBuilder
	func liquidGlassButtonStyle(isProminent: Bool = false) -> some View {
		// If the operating system is version 26.0 or newer, use Apple's native styles
		if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
			if isProminent {
				buttonStyle(GlassProminentButtonStyle())
			} else {
				buttonStyle(GlassButtonStyle())
			}
		} else {
			// Fallback for older operating systems (< 26.0)
			if isProminent {
				buttonStyle(BorderedProminentButtonStyle())
			} else {
				buttonStyle(BorderedButtonStyle())
			}
		}
	}
}

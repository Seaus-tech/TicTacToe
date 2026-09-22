import SwiftUI

struct FeatureItem: Identifiable {
    let id = UUID()
    let emoji: String
    let tintColor: Color
    let text: String
}

struct FeatureGroup: Identifiable {
    let id = UUID()
    let sectionTitle: String
    let items: [FeatureItem]
}

struct ReleaseNotesRegistry {
    static let currentVersion = "v3.6.0"
    
    // Type-safe structured timeline array configuration
    static let latestNotes = [
        FeatureGroup(
            sectionTitle: "WHAT'S NEW",
            items: [
                FeatureItem(emoji: "🚀", tintColor: .purple, text: "Ecosystem Parity & Performance Push: This release delivers a sweeping wave of micro-optimizations across the entire NEO-GRID multiplatform architecture."),
                FeatureItem(emoji: "📈", tintColor: .green, text: "Delivering smoother frame rates, refined layout calculations, and enhanced state management across all Apple platforms.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "PLATFORM UPDATES",
            items: [
                FeatureItem(emoji: "🖥️", tintColor: .blue, text: "macOS & iOS: Enhanced responsive grid rendering for high-refresh-rate ProMotion displays and refined view lifecycle management."),
                FeatureItem(emoji: "🥽", tintColor: .cyan, text: "visionOS: Improved spatial alignment and volumetric material depth for immersive grid interactions."),
                FeatureItem(emoji: "📺", tintColor: .orange, text: "tvOS: Streamlined Focus Engine handling to ensure intuitive Siri Remote navigation across grid controls.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "BUG FIXES & REFINEMENTS",
            items: [
                FeatureItem(emoji: "🛠️", tintColor: .red, text: "UI State Restoration: Resolved an issue where localized UserInterfaceState persistence led to unexpected view hierarchy caching between launches."),
                FeatureItem(emoji: "⚡", tintColor: .yellow, text: "General Stability: Applied incremental micro-fixes to reduce runtime overhead and improve overall application responsiveness across devices.")
            ]
        )
    ]
}

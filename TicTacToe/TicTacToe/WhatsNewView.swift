import SwiftUI

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct WhatsNewView: View {
    @Binding var isPresented: Bool
    
    // Feature array dynamically handling multiplatform capabilities
    let features = [
        WhatsNewFeature(icon: "cpu", iconColor: .green, title: "Single Player Engine", description: "Algorithmic defensive-offensive evaluation core with customizable difficulty modes."),
        WhatsNewFeature(icon: "bolt.horizontal.icloud", iconColor: .purple, title: "Quantum Online Mode", description: "Custom WebSocket tunnel layer for lightning-fast, zero-config move relays."),
        WhatsNewFeature(icon: "person.2", iconColor: .blue, title: "Local Double Player", description: "Native shared-device multiplayer utilizing adaptive focus tracking."),
        WhatsNewFeature(icon: "square.stack.3d.glass", iconColor: .cyan, title: "Liquid Glass Design", description: "A fresh, futuristic neon grid interface optimized for iOS 26 and modern Apple operating systems.")
    ]
    
    var body: some View {
        VStyleContainer {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("NEO-GRID")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 40)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(features) { feature in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(feature.iconColor)
                                    .frame(width: 36, alignment: .center)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(feature.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Footer Section with Action Button
            VStack(spacing: 16) {
                Button(action: { isPresented = false }) {
                    Text("Continue")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .liquidGlassButtonStyle(isProminent: true) // Hooks into your custom operating system extensions
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 400, minHeight: 600) // Optimal bounding container sizing across iOS & macOS platforms
    }
}

// Multiplatform background wrapper helper
struct VStyleContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(macOS)
        content
            .background(VisualEffectView().ignoresSafeArea())
        #else
        content
            .background(Color(.systemBackground).ignoresSafeArea())
        #endif
    }
}

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif

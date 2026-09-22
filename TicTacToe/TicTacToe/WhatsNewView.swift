import SwiftUI

struct WhatsNewView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStyleContainer {
            VStack(spacing: 0) {
                // Persistent Title Header Section
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text("NEO-GRID")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                    
                    Text(ReleaseNotesRegistry.currentVersion)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                        .foregroundColor(.secondary)
                }
                .padding(.top, 45)
                .padding(.bottom, 20)
                
                // Pure Native Type-Safe List Feed
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(ReleaseNotesRegistry.latestNotes) { group in
                            VStack(alignment: .leading, spacing: 14) {
                                // Section Title Header Label
                                Text(group.sectionTitle)
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                
                                // Grouped Feature Feeds
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(group.items) { item in
                                        HStack(alignment: .top, spacing: 14) {
                                            Text(item.emoji)
                                                .font(.title3)
                                                .frame(width: 28, alignment: .center)
                                            
                                            Text(item.text)
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.primary)
                                                .lineSpacing(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
                
                // Bottom Fixed CTA Action Area
                VStack(spacing: 16) {
                    Button(action: { isPresented = false }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .liquidGlassButtonStyle(isProminent: true)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 680)
    }
}

// Multiplatform background wrapper helper container frame
struct VStyleContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        #if os(macOS)
        content.background(VisualEffectView().ignoresSafeArea())
        #else
        content.background(Color(.systemBackground).ignoresSafeArea())
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

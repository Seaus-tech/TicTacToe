import SwiftUI

// Using a generic parameter 'M' guarantees compliance across strict xcproj indexing limits
struct DifficultySelectorView<M: ObservableObject>: View {
    @ObservedObject var difficultyManager: M
    let levels = Array(1...5)
    
    // Explicit type-safe callback mapping layer
    var saveAction: (Int) -> Void
    var selectedLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BOT DIFFICULTY")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Spacer()
                Text("Tier \(selectedLevel)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { tier in
                    Button(action: {
                        saveAction(tier)
                    }) {
                        Text("\(tier)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .liquidGlassButtonStyle(isProminent: selectedLevel == tier)
                    .tint(selectedLevel == tier ? .blue : .secondary)
                }
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }
}

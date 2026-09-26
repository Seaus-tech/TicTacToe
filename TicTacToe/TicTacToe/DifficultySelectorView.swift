import SwiftUI

// Tier names — personality matters
private let tierNames = ["Rookie", "Cadet", "Tactician", "Veteran", "Nemesis"]
private let tierColors: [Color] = [.green, .teal, .blue, .purple, .red]

struct DifficultySelectorView<M: ObservableObject>: View {
    @ObservedObject var difficultyManager: M
    let levels = Array(1...5)

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
                Text(tierName(for: selectedLevel))
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(tierColors[selectedLevel - 1])
                    .animation(.spring(response: 0.3), value: selectedLevel)
            }

            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { tier in
                    Button {
                        saveAction(tier)
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(tier)")
                                .font(.subheadline.bold())
                            Text(tierName(for: tier))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .liquidGlassButtonStyle(isProminent: selectedLevel == tier)
                    .tint(selectedLevel == tier ? tierColors[tier - 1] : .secondary)
                }
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }

    private func tierName(for level: Int) -> String {
        guard level >= 1 && level <= tierNames.count else { return "Unknown" }
        return tierNames[level - 1]
    }
}

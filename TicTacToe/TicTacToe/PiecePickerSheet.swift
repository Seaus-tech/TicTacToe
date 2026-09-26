import SwiftUI

struct PiecePickerSheet: View {
    @Binding var humanPiece: String
    var onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 6) {
                Text("Choose Your Piece")
                    .font(.system(.title2, design: .rounded).bold())
                Text("X always goes first")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            HStack(spacing: 24) {
                pieceButton("X", color: .blue)
                pieceButton("O", color: .orange)
            }

            Button(action: onConfirm) {
                Text("Start Game")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .liquidGlassButtonStyle(isProminent: true)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 360)
        #if os(iOS)
        .presentationDetents([.height(320)])
        .presentationCornerRadius(28)
        #endif
    }

    private func pieceButton(_ piece: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                humanPiece = piece
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(humanPiece == piece ? color.opacity(0.15) : Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(humanPiece == piece ? color : Color.clear, lineWidth: 2.5)
                    )
                    .shadow(color: humanPiece == piece ? color.opacity(0.4) : .clear, radius: 10)

                VStack(spacing: 8) {
                    Text(piece)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Text(piece == "X" ? "Goes First" : "Goes Second")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 130, height: 130)
        }
        .buttonStyle(.plain)
        .scaleEffect(humanPiece == piece ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: humanPiece)
    }
}

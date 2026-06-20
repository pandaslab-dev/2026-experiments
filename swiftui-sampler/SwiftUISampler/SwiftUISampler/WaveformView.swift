import SwiftUI

struct WaveformView: View {
    let amplitudes: [CGFloat]
    let playheadProgress: Double
    let selectedSliceIndex: Int?
    let sliceCount: Int

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.1, blue: 0.14),
                                Color(red: 0.12, green: 0.16, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                sliceOverlays(in: size)
                waveformPath(in: size)

                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 2)
                    .offset(x: playheadX(in: size.width) - (size.width / 2))
            }
            .overlay(alignment: .topLeading) {
                Text("waveform")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(12)
            }
        }
    }

    @ViewBuilder
    private func sliceOverlays(in size: CGSize) -> some View {
        let sliceWidth = size.width / CGFloat(max(sliceCount, 1))

        HStack(spacing: 0) {
            ForEach(0..<sliceCount, id: \.self) { index in
                Rectangle()
                    .fill(index == selectedSliceIndex ? Color.orange.opacity(0.2) : Color.clear)
                    .frame(width: sliceWidth)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func waveformPath(in size: CGSize) -> some View {
        Path { path in
            let middleY = size.height / 2
            let barSpacing = size.width / CGFloat(max(amplitudes.count, 1))

            for (index, amplitude) in amplitudes.enumerated() {
                let x = (CGFloat(index) * barSpacing) + (barSpacing / 2)
                let lineHeight = max(6, amplitude * size.height * 0.72)

                path.move(to: CGPoint(x: x, y: middleY - (lineHeight / 2)))
                path.addLine(to: CGPoint(x: x, y: middleY + (lineHeight / 2)))
            }
        }
        .stroke(
            LinearGradient(
                colors: [
                    Color(red: 0.51, green: 0.95, blue: 0.76),
                    Color(red: 0.33, green: 0.74, blue: 1.0)
                ],
                startPoint: .bottom,
                endPoint: .top
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }

    private func playheadX(in width: CGFloat) -> CGFloat {
        CGFloat(min(max(playheadProgress, 0), 1)) * width
    }
}

#Preview {
    WaveformView(
        amplitudes: stride(from: 0, through: 1, by: 0.02).map { value in
            CGFloat(abs(sin(value * 10)))
        },
        playheadProgress: 0.35,
        selectedSliceIndex: 2,
        sliceCount: 8
    )
    .frame(height: 220)
    .padding()
    .background(Color.gray.opacity(0.2))
}

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var sampler = SamplerEngine()
    @State private var showingImporter = false
    @State private var didLoadInitialSample = false

    private let sliceColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                waveformSection
                inputButtons
                transportSection
                pitchSection
                sliceSection
                footerNote
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.audio]
        ) { result in
            switch result {
            case .success(let url):
                sampler.importAudio(from: url)
            case .failure(let error):
                sampler.setError(error.localizedDescription)
            }
        }
        .alert("audio import problem", isPresented: errorAlertBinding) {
            Button("ok", role: .cancel) {
                sampler.clearError()
            }
        } message: {
            Text(sampler.errorMessage ?? "")
        }
        .task {
            guard !didLoadInitialSample else { return }
            didLoadInitialSample = true
            sampler.loadStarterSample()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("pandasample")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var waveformSection: some View {
        VStack(spacing: 10) {
            WaveformView(
                amplitudes: sampler.waveformSamples,
                playheadProgress: sampler.playheadProgress,
                selectedSliceIndex: sampler.selectedSliceIndex,
                sliceCount: sampler.sliceCount
            )
            .frame(height: 220)

            HStack {
                Label(sampler.sampleName, systemImage: "waveform")
                Spacer()
                Text(sampler.statusMessage)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var inputButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingImporter = true
            } label: {
                Label("import audio", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }

            Button {
                sampler.loadStarterSample()
            } label: {
                Label("use demo", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
    }

    private var transportSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    sampler.playFullSample()
                } label: {
                    Label("play full", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SamplerCapsuleButtonStyle(fill: .green.opacity(0.9)))

                Button {
                    sampler.stop()
                } label: {
                    Label("stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SamplerCapsuleButtonStyle(fill: .red.opacity(0.85)))
            }

            HStack {
                Circle()
                    .fill(sampler.isPlaying ? Color.green : Color.secondary.opacity(0.35))
                    .frame(width: 10, height: 10)

                Text(sampler.isPlaying ? "playing right now" : "ready for a short sample")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    private var pitchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("pitch")
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(SamplerEngine.PitchPreset.allCases) { preset in
                    Button {
                        sampler.setPitchPreset(preset)
                    } label: {
                        Text(preset.buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        SelectableCapsuleButtonStyle(
                            isSelected: sampler.pitchPreset == preset
                        )
                    )
                }
            }
        }
    }

    private var sliceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("slices")
                .font(.headline)

            LazyVGrid(columns: sliceColumns, spacing: 12) {
                ForEach(0..<sampler.sliceCount, id: \.self) { index in
                    Button {
                        sampler.playSlice(index)
                    } label: {
                        Text("slice \(index + 1)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        SelectableCapsuleButtonStyle(
                            isSelected: sampler.selectedSliceIndex == index
                        )
                    )
                }
            }
        }
    }

    private var footerNote: some View {
        Text("short files work best here. if you never add a bundled sample, the app makes a tiny demo sound on its own.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { sampler.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    sampler.clearError()
                }
            }
        )
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(red: 0.88, green: 0.95, blue: 0.93)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct SamplerCapsuleButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(
                Capsule()
                    .fill(fill.opacity(configuration.isPressed ? 0.75 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

private struct SelectableCapsuleButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: isSelected ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isSelected {
            return Color.orange.opacity(isPressed ? 0.75 : 0.95)
        }

        return Color.white.opacity(isPressed ? 0.65 : 0.92)
    }
}

#Preview {
    ContentView()
}

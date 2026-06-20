import AVFoundation
import SwiftUI

@MainActor
final class SamplerEngine: ObservableObject {
    enum PitchPreset: String, CaseIterable, Identifiable {
        case down
        case normal
        case up
        case chipmunk

        var id: String { rawValue }

        var buttonTitle: String {
            switch self {
            case .down:
                return "pitch -"
            case .normal:
                return "normal"
            case .up:
                return "pitch +"
            case .chipmunk:
                return "chipmunk"
            }
        }

        var pitch: Float {
            switch self {
            case .down:
                return -500
            case .normal:
                return 0
            case .up:
                return 500
            case .chipmunk:
                return 1_200
            }
        }

        var rate: Float {
            switch self {
            case .chipmunk:
                return 1.08
            default:
                return 1.0
            }
        }
    }

    @Published var waveformSamples: [CGFloat] = Array(repeating: 0.2, count: 160)
    @Published var playheadProgress: Double = 0
    @Published var selectedSliceIndex: Int?
    @Published var isPlaying = false
    @Published var pitchPreset: PitchPreset = .normal
    @Published var sampleName = "demo sample"
    @Published var statusMessage = "waiting for audio"
    @Published var errorMessage: String?

    let sliceCount = 8

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()

    private var audioFile: AVAudioFile?
    private var totalFrames: AVAudioFramePosition = 0
    private var currentStartFrame: AVAudioFramePosition = 0
    private var currentFrameCount: AVAudioFrameCount = 0
    private var playbackTimer: Timer?
    private var playbackToken = 0

    init() {
        configureAudioEngine()
    }

    deinit {
        playbackTimer?.invalidate()
    }

    func loadStarterSample() {
        do {
            try loadBundledOrFallbackSample()
        } catch {
            setError(error.localizedDescription)
        }
    }

    func importAudio(from originalURL: URL) {
        do {
            let copiedURL = try makeLocalCopy(of: originalURL)
            try loadSample(
                from: copiedURL,
                displayName: originalURL.deletingPathExtension().lastPathComponent,
                status: "imported from files"
            )
        } catch {
            setError(error.localizedDescription)
        }
    }

    func playFullSample() {
        guard totalFrames > 0 else { return }
        playSegment(
            startFrame: 0,
            frameCount: AVAudioFrameCount(totalFrames),
            selectedSlice: nil
        )
    }

    func playSlice(_ index: Int) {
        guard totalFrames > 0 else { return }
        let slice = sliceFrameRange(for: index)
        playSegment(
            startFrame: slice.startFrame,
            frameCount: slice.frameCount,
            selectedSlice: index
        )
    }

    func stop() {
        playbackToken += 1
        player.stop()
        isPlaying = false
        stopPlaybackTimer()
    }

    func setPitchPreset(_ preset: PitchPreset) {
        pitchPreset = preset
        timePitch.pitch = preset.pitch
        timePitch.rate = preset.rate
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }

    private func configureAudioEngine() {
        engine.attach(player)
        engine.attach(timePitch)

        // The player feeds into the pitch unit, then out to the speakers.
        engine.connect(player, to: timePitch, format: nil)
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)

        setPitchPreset(.normal)
        startEngineIfNeeded()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            setError("could not start the audio engine: \(error.localizedDescription)")
        }
    }

    private func loadBundledOrFallbackSample() throws {
        if let bundledURL = bundledSampleURL() {
            try loadSample(
                from: bundledURL,
                displayName: bundledURL.lastPathComponent,
                status: "using bundled sample"
            )
            return
        }

        let fallbackURL = try makeFallbackAudioFile()
        try loadSample(
            from: fallbackURL,
            displayName: "demo tone",
            status: "using generated demo sample"
        )
    }

    private func bundledSampleURL() -> URL? {
        let possibleNames = [
            ("sample", "wav"),
            ("sample", "m4a"),
            ("sample", "caf"),
            ("sample", "mp3")
        ]

        for (name, fileExtension) in possibleNames {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }

    private func loadSample(from url: URL, displayName: String, status: String) throws {
        stop()

        let file = try AVAudioFile(forReading: url)
        audioFile = file
        totalFrames = file.length
        waveformSamples = try makeWaveformSamples(from: file, sampleCount: 160)
        file.framePosition = 0

        sampleName = displayName
        statusMessage = status
        playheadProgress = 0
        selectedSliceIndex = nil
        clearError()
    }

    private func playSegment(
        startFrame: AVAudioFramePosition,
        frameCount: AVAudioFrameCount,
        selectedSlice: Int?
    ) {
        guard let audioFile else { return }

        startEngineIfNeeded()
        stop()

        playbackToken += 1
        let token = playbackToken

        currentStartFrame = startFrame
        currentFrameCount = frameCount
        selectedSliceIndex = selectedSlice
        playheadProgress = Double(startFrame) / Double(max(totalFrames, 1))

        player.scheduleSegment(
            audioFile,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.playbackToken == token else { return }
                self.isPlaying = false
                self.stopPlaybackTimer()
                self.playheadProgress = Double(startFrame + AVAudioFramePosition(frameCount)) / Double(max(self.totalFrames, 1))
            }
        }

        player.play()
        isPlaying = true
        startPlaybackTimer()
    }

    private func startPlaybackTimer() {
        stopPlaybackTimer()

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlayhead()
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func updatePlayhead() {
        guard
            isPlaying,
            let renderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: renderTime)
        else {
            return
        }

        let relativeFrame = AVAudioFramePosition(playerTime.sampleTime)
        let absoluteFrame = currentStartFrame + relativeFrame

        guard totalFrames > 0 else { return }

        playheadProgress = min(
            max(Double(absoluteFrame) / Double(totalFrames), 0),
            1
        )
    }

    private func sliceFrameRange(for index: Int) -> (startFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
        let framesPerSlice = max(totalFrames / AVAudioFramePosition(sliceCount), 1)
        let startFrame = AVAudioFramePosition(index) * framesPerSlice

        if index == sliceCount - 1 {
            let finalFrameCount = totalFrames - startFrame
            return (startFrame, AVAudioFrameCount(finalFrameCount))
        }

        return (startFrame, AVAudioFrameCount(framesPerSlice))
    }

    private func makeLocalCopy(of originalURL: URL) throws -> URL {
        let didAccessSecurityScopedResource = originalURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                originalURL.stopAccessingSecurityScopedResource()
            }
        }

        let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ImportedSamples",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )

        let fileExtension = originalURL.pathExtension.isEmpty ? "m4a" : originalURL.pathExtension
        let copyURL = folderURL.appendingPathComponent("sample-\(UUID().uuidString).\(fileExtension)")

        try FileManager.default.copyItem(at: originalURL, to: copyURL)
        return copyURL
    }

    private func makeFallbackAudioFile() throws -> URL {
        let sampleRate = 44_100.0
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        let noteLength = 0.34
        let notes: [Double] = [130.81, 196.00, 261.63, 392.00, 329.63, 220.00, 174.61, 261.63]
        let totalFrameCount = AVAudioFrameCount(sampleRate * noteLength * Double(notes.count))
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("swiftui-sampler-demo.caf")

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrameCount) else {
            throw NSError(domain: "SamplerEngine", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "could not create the fallback audio buffer"
            ])
        }

        buffer.frameLength = totalFrameCount
        guard let channelData = buffer.floatChannelData?[0] else {
            throw NSError(domain: "SamplerEngine", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "could not access the fallback audio channel data"
            ])
        }

        for frame in 0..<Int(totalFrameCount) {
            let time = Double(frame) / sampleRate
            let noteIndex = min(Int(time / noteLength), notes.count - 1)
            let noteStart = Double(noteIndex) * noteLength
            let noteTime = time - noteStart
            let envelope = max(0.0, 1.0 - (noteTime / noteLength))
            let frequency = notes[noteIndex]

            let mainTone = sin(2 * .pi * frequency * time)
            let octaveTone = sin(2 * .pi * frequency * 2 * time) * 0.3
            let subTone = sin(2 * .pi * frequency * 0.5 * time) * 0.15
            let sample = (mainTone + octaveTone + subTone) * envelope * 0.55

            channelData[frame] = Float(sample)
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        try outputFile.write(from: buffer)

        return outputURL
    }

    private func makeWaveformSamples(from file: AVAudioFile, sampleCount: Int) throws -> [CGFloat] {
        file.framePosition = 0
        let floatBuffer = try makeFloatBuffer(from: file)
        file.framePosition = 0

        guard
            let channelData = floatBuffer.floatChannelData,
            floatBuffer.frameLength > 0
        else {
            return Array(repeating: 0.2, count: sampleCount)
        }

        let frameLength = Int(floatBuffer.frameLength)
        let channelCount = Int(floatBuffer.format.channelCount)
        let bucketSize = max(frameLength / sampleCount, 1)
        var samples: [CGFloat] = []
        samples.reserveCapacity(sampleCount)

        for bucketIndex in 0..<sampleCount {
            let startFrame = bucketIndex * bucketSize
            let endFrame = min(startFrame + bucketSize, frameLength)

            guard startFrame < endFrame else {
                samples.append(0.08)
                continue
            }

            var peak: Float = 0

            for frame in startFrame..<endFrame {
                var averageMagnitude: Float = 0

                for channel in 0..<channelCount {
                    averageMagnitude += abs(channelData[channel][frame])
                }

                averageMagnitude /= Float(channelCount)
                peak = max(peak, averageMagnitude)
            }

            // Square root makes quieter sections easier to see.
            samples.append(max(CGFloat(sqrt(peak)), 0.08))
        }

        let maxValue = max(samples.max() ?? 1, 0.08)
        return samples.map { $0 / maxValue }
    }

    private func makeFloatBuffer(from file: AVAudioFile) throws -> AVAudioPCMBuffer {
        let sourceFormat = file.processingFormat
        let sourceFrameCount = AVAudioFrameCount(file.length)

        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: sourceFrameCount
        ) else {
            throw NSError(domain: "SamplerEngine", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "could not create the source audio buffer"
            ])
        }

        try file.read(into: sourceBuffer)

        if sourceFormat.commonFormat == .pcmFormatFloat32 {
            return sourceBuffer
        }

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sourceFormat.sampleRate,
            channels: sourceFormat.channelCount,
            interleaved: false
        ) else {
            throw NSError(domain: "SamplerEngine", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "could not create a float audio format"
            ])
        }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw NSError(domain: "SamplerEngine", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "could not create an audio converter"
            ])
        }

        let estimatedCapacity = AVAudioFrameCount(
            Double(sourceBuffer.frameLength) * (targetFormat.sampleRate / sourceFormat.sampleRate)
        ) + 1

        guard let targetBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: estimatedCapacity
        ) else {
            throw NSError(domain: "SamplerEngine", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "could not create the float audio buffer"
            ])
        }

        var didProvideSourceBuffer = false
        var conversionError: NSError?

        converter.convert(to: targetBuffer, error: &conversionError) { _, outStatus in
            if didProvideSourceBuffer {
                outStatus.pointee = .endOfStream
                return nil
            }

            didProvideSourceBuffer = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        if let conversionError {
            throw conversionError
        }

        return targetBuffer
    }
}

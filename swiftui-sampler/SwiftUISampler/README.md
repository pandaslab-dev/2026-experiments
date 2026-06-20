# swiftui sampler

rough little sampler experiment i made after finishing the developing in swift tutorials.

the point here was just to poke at audio playback, sample slicing, waveforms, and basic swiftui interaction without turning it into a big architecture project.

![app screenshot](../assets/sampler-screenshot.png)

## what is in here

- `SwiftUISamplerApp.swift` starts the app
- `ContentView.swift` builds the single-screen sampler ui
- `SamplerEngine.swift` handles loading audio, slicing, playback, and pitch changes
- `WaveformView.swift` draws the simple waveform/playhead display

## setup

1. in xcode, make a new project:
   `file > new > project > ios app`
2. choose `swiftui` interface and `swift` language
3. replace the generated `App` and `ContentView` files with the ones in this folder
4. add `SamplerEngine.swift` and `WaveformView.swift` to the project
5. run it in the iphone simulator or on a device

you can import an audio file from the files picker. on the simulator, that just means picking a file from your mac.

if you want a bundled sample too, drag in a short file named `sample.wav`, `sample.m4a`, `sample.caf`, or `sample.mp3`. if you do nothing, the app generates a tiny demo tone so the ui still works.

## what i learned / what i'm testing

- using `AVAudioEngine`, `AVAudioPlayerNode`, and `AVAudioUnitTimePitch`
- playing just a frame range instead of the whole file
- pulling simple amplitude data out for a rough waveform
- keeping the swiftui side small and readable

## limitations

- no recording yet
- waveform drawing is intentionally approximate
- it is happiest with short audio files
- there is no fancy editing or trimming ui

## todo maybe

- add record from mic
- let the user change slice count
- drag slice markers around
- add a loop button
- try a nicer waveform style later

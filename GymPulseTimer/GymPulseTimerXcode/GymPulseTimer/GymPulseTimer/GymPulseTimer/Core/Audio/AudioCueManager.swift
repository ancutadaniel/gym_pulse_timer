import AVFoundation
import AudioToolbox
import Foundation
import Combine
import Combine

final class AudioCueManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private var didConfigureSession = false

    private var soundEnabled = true
    private var voiceEnabled = true

    func updatePreferences(soundEnabled: Bool, voiceEnabled: Bool) {
        self.soundEnabled = soundEnabled
        self.voiceEnabled = voiceEnabled
        configureSessionIfNeeded()
    }

    func playPhaseStart(phase: TimerPhase) {
        guard phase != .complete else { return }
        if soundEnabled {
            playBeep()
        }
        if voiceEnabled {
            speak(phrase(for: phase))
        }
    }

    func playCountdown(second: Int) {
        guard second > 0 else { return }
        if soundEnabled {
            playBeep()
        }
        if voiceEnabled {
            speak(String(second))
        }
    }

    func previewSound() {
        playBeep()
    }

    func previewVoice() {
        speak("Get ready")
    }

    private func phrase(for phase: TimerPhase) -> String {
        switch phase {
        case .getReady:
            return "Get ready"
        case .work:
            return "Work"
        case .rest:
            return "Rest"
        case .complete:
            return "Complete"
        }
    }

    private func playBeep() {
        AudioServicesPlaySystemSound(1104)
    }

    private func speak(_ text: String) {
        configureSessionIfNeeded()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        do {
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
            didConfigureSession = true
        } catch {
            // Best-effort only; cues are non-critical.
        }
    }
}

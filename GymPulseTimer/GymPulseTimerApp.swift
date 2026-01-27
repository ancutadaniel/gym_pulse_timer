import SwiftUI

@main
struct GymPulseTimerApp: App {
    @StateObject private var presetStore = PresetStore()
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(presetStore)
                .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        }
    }
}

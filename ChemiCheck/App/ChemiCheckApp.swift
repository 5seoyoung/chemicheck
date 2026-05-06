import SwiftUI

@main
struct ChemiCheckApp: App {
    @State private var appState = AppState()
    @State private var showSplash = true
    @State private var showOnboarding = false

    init() {
        DummyDataLoader.shared.loadAll()
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                            if !appState.hasCompletedOnboarding {
                                showOnboarding = true
                            }
                        }
                    }
                } else if showOnboarding {
                    OnboardingView { profile in
                        appState.familyProfile = profile
                        appState.completeOnboarding()
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .environment(appState)
        }
    }
}

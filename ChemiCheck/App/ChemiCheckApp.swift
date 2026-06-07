import SwiftUI

@main
struct ChemiCheckApp: App {
    @State private var appState = AppState()
    @State private var phase: AppPhase = .splash

    enum AppPhase { case splash, onboarding, main }

    init() {
        DummyDataLoader.shared.loadAll()
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            switch phase {
            case .splash:
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                phase = appState.hasCompletedOnboarding ? .main : .onboarding
                            }
                        }
                    }

            case .onboarding:
                OnboardingView { profile in
                    appState.familyProfile = profile
                    appState.completeOnboarding()
                    withAnimation(.easeInOut(duration: 0.35)) { phase = .main }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .main:
                ContentView()
                    .transition(.opacity)
            }
        }
        .environment(appState)
    }
}

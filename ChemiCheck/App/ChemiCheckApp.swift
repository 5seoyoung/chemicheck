import SwiftUI

// MARK: - RootView
// App 레벨 @State/@StateObject는 iOS 버전에 따라 body 재렌더링이 불안정.
// View 레벨 @State는 SwiftUI가 완전히 보장 → phase 관리를 여기서 담당.

private struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var phase: Phase = .splash

    private enum Phase: Equatable { case splash, onboarding, main }

    var body: some View {
        Group {
            if phase == .splash {
                SplashView {
                    phase = appState.hasCompletedOnboarding ? .main : .onboarding
                }
            } else if phase == .onboarding {
                OnboardingView { profile in
                    appState.familyProfile = profile
                    appState.completeOnboarding()
                    phase = .main
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .onChange(of: appState.hasCompletedOnboarding) { _, completed in
            if !completed { phase = .splash }
        }
    }
}

// MARK: - App

@main
struct ChemiCheckApp: App {
    @State private var appState = AppState()

    init() {
        DummyDataLoader.shared.loadAll()
        NotificationService.shared.requestPermission()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = LocalDBService.shared
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            LabelImageSaver.shared.saveIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

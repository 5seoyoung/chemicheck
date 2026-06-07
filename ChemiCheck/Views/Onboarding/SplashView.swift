import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.75
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // 파스텔 그라디언트 배경
            LinearGradient(
                colors: [Color(hex: "#F0F5FF"), Color(hex: "#E8F4EE"), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 로고 영역
                VStack(spacing: 28) {
                    // 로고 이미지 or 프로그래매틱
                    logoImage
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    // 앱 이름
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("케미")
                                .foregroundStyle(Color.brandNavy)
                            Text("체크")
                                .foregroundStyle(Color.brandGreen)
                        }
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .opacity(textOpacity)

                        Text("안심성분 · 우리집 화학제품 안전 즉답 AI")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .opacity(taglineOpacity)
                    }
                }

                Spacer()

                // 하단 로딩 영역
                VStack(spacing: 14) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.brandNavy.opacity(0.4)).frame(width: 5, height: 5)
                        Circle().fill(Color.brandNavy.opacity(0.65)).frame(width: 5, height: 5)
                        Circle().fill(Color.brandNavy).frame(width: 5, height: 5)
                    }
                    .opacity(taglineOpacity)

                    Text("데이터를 불러오는 중이에요")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                        .opacity(taglineOpacity)
                }
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
                taglineOpacity = 1.0
            }
        }
    }

    @ViewBuilder
    private var logoImage: some View {
        // 실제 로고 이미지 사용 (Assets에 logo.png 추가 시 자동으로 표시됨)
        if UIImage(named: "AppLogo") != nil {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
        } else {
            LogoMark(size: 120)
        }
    }
}

// MARK: - 프로그래매틱 로고 마크 (실제 로고와 유사하게 재현)

struct LogoMark: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // 타원형 아웃라인 (로고 외곽)
            RoundedRectangle(cornerRadius: size * 0.38, style: .continuous)
                .stroke(Color.brandNavy, lineWidth: size * 0.055)
                .frame(width: size * 0.76, height: size * 1.05)

            // 잎 아이콘 (좌상단)
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.26))
                .foregroundStyle(Color.brandGreen)
                .rotationEffect(.degrees(-15))
                .offset(x: -size * 0.22, y: -size * 0.32)

            // 세제 병 (중앙)
            VStack(spacing: size * 0.025) {
                // 병 뚜껑
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.brandNavy)
                    .frame(width: size * 0.14, height: size * 0.09)

                // 병 몸체
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                        .stroke(Color.brandNavy, lineWidth: size * 0.045)
                        .frame(width: size * 0.32, height: size * 0.44)

                    VStack(spacing: size * 0.04) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.brandGreen)
                                .frame(width: size * 0.18, height: size * 0.025)
                        }
                    }
                }
            }
            .offset(x: -size * 0.04, y: size * 0.04)

            // 방패 + 체크마크 (우하단)
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(Color.brandGreen)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.15, weight: .black))
                    .foregroundStyle(.white)
            }
            .offset(x: size * 0.26, y: size * 0.24)
        }
        .frame(width: size * 1.1, height: size * 1.2)
    }
}

// MARK: - 헤더용 소형 로고

struct LogoMarkSmall: View {
    var size: CGFloat = 32

    var body: some View {
        if UIImage(named: "AppLogo") != nil {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            LogoMark(size: size)
        }
    }
}

#Preview {
    SplashView()
}

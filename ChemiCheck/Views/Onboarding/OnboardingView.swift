import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var profile = FamilyProfile()
    @State private var selectedInfantAges: Set<Int> = []
    @State private var selectedAllergyTypes: Set<String> = []
    @State private var selectedPetTypes: Set<PetType> = []

    var onComplete: (FamilyProfile) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i <= currentPage ? Color.brandNavy : Color.separator)
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            TabView(selection: $currentPage) {
                introPage.tag(0)
                infantPage.tag(1)
                pregnantPage.tag(2)
                allergyPage.tag(3)
                petPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Page 0: Intro

    private var introPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color.brandNavy.opacity(0.08))
                        .frame(width: 160, height: 160)
                    LogoMark(size: 90)
                }

                VStack(spacing: 12) {
                    Text("우리 가족의\n화학제품 안전 전문가")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("라벨 사진 한 장으로 즉시\n화학물질 안전성을 확인하세요")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    featureRow(icon: "camera.fill", color: .brandNavy,
                               title: "라벨 즉시 진단", desc: "0.5초 안에 위험 화학물질 분석")
                    featureRow(icon: "person.3.fill", color: .brandGreen,
                               title: "가족 맞춤 위험도", desc: "영유아·임산부·반려동물별 개인화")
                    featureRow(icon: "bell.badge.fill", color: .riskMedium,
                               title: "회수 즉시 알림", desc: "등록 제품 리콜 발생 시 푸시 알림")
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("시작하기") {
                withAnimation { currentPage = 1 }
            }
            .primaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Page 1: 영유아

    private var infantPage: some View {
        onboardingPage(
            step: "1 / 4",
            title: "영유아 자녀가\n있으신가요?",
            subtitle: "영유아 보유 여부에 따라 위험도를 더 엄격하게 계산해요",
            icon: "figure.and.child.holdinghands",
            iconColor: .brandNavy
        ) {
            VStack(spacing: 12) {
                toggleCard(
                    title: "영유아 자녀 있음",
                    subtitle: "0~12세 자녀가 있어요",
                    icon: "figure.and.child.holdinghands",
                    isOn: $profile.hasInfant
                )

                if profile.hasInfant {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("자녀 연령을 선택하세요 (복수 선택)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        let ages = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                            ForEach(ages, id: \.self) { age in
                                let label = age == 0 ? "신생아" : "\(age)세"
                                Button(label) {
                                    if selectedInfantAges.contains(age) {
                                        selectedInfantAges.remove(age)
                                    } else {
                                        selectedInfantAges.insert(age)
                                    }
                                    profile.infantAges = Array(selectedInfantAges).sorted()
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedInfantAges.contains(age) ? .white : Color.textPrimary)
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .background(selectedInfantAges.contains(age) ? Color.brandNavy : Color.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: profile.hasInfant)
        } onNext: {
            withAnimation { currentPage = 2 }
        } onSkip: {
            withAnimation { currentPage = 2 }
        }
    }

    // MARK: - Page 2: 임산부

    private var pregnantPage: some View {
        onboardingPage(
            step: "2 / 4",
            title: "임산부 가족이\n계신가요?",
            subtitle: "임산부는 내분비 교란 물질에 더 민감하게 반응할 수 있어요",
            icon: "person.fill.badge.plus",
            iconColor: .brandGreen
        ) {
            toggleCard(
                title: "임산부 가족 있음",
                subtitle: "임신 중인 가족 구성원이 있어요",
                icon: "person.fill.badge.plus",
                isOn: $profile.hasPregnant
            )
        } onNext: {
            withAnimation { currentPage = 3 }
        } onSkip: {
            withAnimation { currentPage = 3 }
        }
    }

    // MARK: - Page 3: 알레르기

    private var allergyPage: some View {
        onboardingPage(
            step: "3 / 4",
            title: "알레르기·아토피·천식\n가족이 계신가요?",
            subtitle: "향료·보존제 성분에 알레르기 반응을 보일 수 있는 가족에게 맞춤 경고를 드려요",
            icon: "cross.case.fill",
            iconColor: .riskMedium
        ) {
            VStack(spacing: 12) {
                toggleCard(
                    title: "알레르기/아토피/천식 보유",
                    subtitle: "특정 화학성분에 민감한 가족이 있어요",
                    icon: "cross.case.fill",
                    isOn: $profile.hasAllergyMember
                )

                if profile.hasAllergyMember {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("해당하는 항목을 선택하세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        let types = ["알레르기", "아토피 피부염", "천식", "식품 알레르기", "약물 알레르기"]
                        ForEach(types, id: \.self) { t in
                            Button {
                                if selectedAllergyTypes.contains(t) { selectedAllergyTypes.remove(t) }
                                else { selectedAllergyTypes.insert(t) }
                                profile.allergyTypes = Array(selectedAllergyTypes)
                            } label: {
                                HStack {
                                    Image(systemName: selectedAllergyTypes.contains(t) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedAllergyTypes.contains(t) ? Color.brandGreen : Color.textTertiary)
                                    Text(t)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: profile.hasAllergyMember)
        } onNext: {
            withAnimation { currentPage = 4 }
        } onSkip: {
            withAnimation { currentPage = 4 }
        }
    }

    // MARK: - Page 4: 반려동물

    private var petPage: some View {
        onboardingPage(
            step: "4 / 4",
            title: "반려동물을\n키우고 계신가요?",
            subtitle: "고양이는 특정 화학물질에 극도로 민감해요. 반려동물에게 위험한 성분을 알려드려요",
            icon: "pawprint.fill",
            iconColor: .brandNavy
        ) {
            VStack(spacing: 12) {
                toggleCard(
                    title: "반려동물 있음",
                    subtitle: "강아지, 고양이 등 반려동물이 있어요",
                    icon: "pawprint.fill",
                    isOn: $profile.hasPet
                )

                if profile.hasPet {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("반려동물 종류를 선택하세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: 8) {
                            ForEach(PetType.allCases, id: \.rawValue) { pet in
                                Button {
                                    if selectedPetTypes.contains(pet) { selectedPetTypes.remove(pet) }
                                    else { selectedPetTypes.insert(pet) }
                                    profile.petTypes = Array(selectedPetTypes)
                                } label: {
                                    Text(pet.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(selectedPetTypes.contains(pet) ? .white : Color.textPrimary)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedPetTypes.contains(pet) ? Color.brandNavy : Color.bgSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: profile.hasPet)
        } onNext: {
            onComplete(profile)
        } onSkip: {
            onComplete(profile)
        }
    }

    // MARK: - Helpers

    private func onboardingPage<Content: View>(
        step: String, title: String, subtitle: String,
        icon: String, iconColor: Color,
        @ViewBuilder content: () -> Content,
        onNext: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(step)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.brandGreen)

                        Text(title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }

                    content()
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 120)
            }

            // Bottom buttons
            VStack(spacing: 10) {
                Button(currentPage == 4 ? "시작하기" : "다음") { onNext() }
                    .primaryButton()

                Button("건너뛰기") { onSkip() }
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                    .frame(height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [Color.bgPrimary.opacity(0), Color.bgPrimary],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private func toggleCard(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isOn.wrappedValue ? Color.brandNavy.opacity(0.12) : Color.bgSecondary)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isOn.wrappedValue ? Color.brandNavy : Color.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Color.brandGreen)
                .labelsHidden()
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    OnboardingView(onComplete: { _ in })
}

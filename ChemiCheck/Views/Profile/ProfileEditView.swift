import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var profile: FamilyProfile = FamilyProfile()
    @State private var selectedInfantAges: Set<Int> = []
    @State private var selectedAllergyTypes: Set<String> = []
    @State private var selectedPetTypes: Set<PetType> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Infant section
                    profileSection(
                        title: "영유아",
                        icon: "figure.and.child.holdinghands",
                        color: .brandNavy
                    ) {
                        toggleRow(title: "영유아 자녀 있음", isOn: $profile.hasInfant)

                        if profile.hasInfant {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("연령 선택")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.textSecondary)

                                let ages = Array(0...12)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                    ForEach(ages, id: \.self) { age in
                                        let label = age == 0 ? "신생아" : "\(age)세"
                                        Button(label) {
                                            if selectedInfantAges.contains(age) { selectedInfantAges.remove(age) }
                                            else { selectedInfantAges.insert(age) }
                                            profile.infantAges = Array(selectedInfantAges).sorted()
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(selectedInfantAges.contains(age) ? .white : Color.textPrimary)
                                        .frame(height: 34)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedInfantAges.contains(age) ? Color.brandNavy : Color.bgSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Pregnant section
                    profileSection(title: "임산부", icon: "person.fill.badge.plus", color: .brandGreen) {
                        toggleRow(title: "임산부 가족 있음", isOn: $profile.hasPregnant)
                    }

                    // Allergy section
                    profileSection(title: "알레르기/아토피/천식", icon: "cross.case.fill", color: .riskMedium) {
                        toggleRow(title: "해당 가족 있음", isOn: $profile.hasAllergyMember)

                        if profile.hasAllergyMember {
                            VStack(spacing: 8) {
                                let types = ["알레르기", "아토피 피부염", "천식", "식품 알레르기"]
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Elderly section
                    profileSection(title: "노약자 (65세 이상)", icon: "figure.walk.circle.fill", color: .skyFg) {
                        toggleRow(title: "노약자 가족 있음", isOn: $profile.hasElderly)
                    }

                    // Pet section
                    profileSection(title: "반려동물", icon: "pawprint.fill", color: .brandNavy) {
                        toggleRow(title: "반려동물 있음", isOn: $profile.hasPet)

                        if profile.hasPet {
                            HStack(spacing: 8) {
                                ForEach(PetType.allCases, id: \.rawValue) { pet in
                                    Button {
                                        if selectedPetTypes.contains(pet) { selectedPetTypes.remove(pet) }
                                        else { selectedPetTypes.insert(pet) }
                                        profile.petTypes = Array(selectedPetTypes)
                                    } label: {
                                        Text(pet.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(selectedPetTypes.contains(pet) ? .white : Color.textPrimary)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedPetTypes.contains(pet) ? Color.brandNavy : Color.bgSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.2), value: profile.hasInfant)
                .animation(.easeInOut(duration: 0.2), value: profile.hasAllergyMember)
                .animation(.easeInOut(duration: 0.2), value: profile.hasPet)
            }
            .background(Color.bgPrimary)
            .navigationTitle("가족 프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("저장") {
                        appState.familyProfile = profile
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandNavy)
                }
            }
            .onAppear {
                profile = appState.familyProfile
                selectedInfantAges = Set(profile.infantAges)
                selectedAllergyTypes = Set(profile.allergyTypes)
                selectedPetTypes = Set(profile.petTypes)
            }
        }
    }

    private func profileSection<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)

            content()
        }
        .padding(16)
        .cardStyle()
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Color.brandGreen)
                .labelsHidden()
        }
    }
}

#Preview {
    ProfileEditView()
        .environment(AppState())
}

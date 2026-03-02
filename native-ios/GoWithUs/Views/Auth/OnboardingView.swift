import SwiftUI

// MARK: - Onboarding Data
struct OnboardingOption: Identifiable {
    let id: String
    let label: String
    let emoji: String
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    // Steps: 0 = travel style Q, 1 = category Q, 2 = interests (multi)
    @State private var currentStep = 0
    @State private var selectedStyle: String? = nil
    @State private var selectedBudget: String? = nil
    @State private var selectedInterests: Set<String> = []
    @State private var isSaving = false
    @State private var animateIn = false

    // MARK: - Data
    private let travelStyles: [OnboardingOption] = [
        OnboardingOption(id: "adventure", label: "ผจญภัย", emoji: "🏕️"),
        OnboardingOption(id: "relax", label: "พักผ่อน", emoji: "🏖️"),
        OnboardingOption(id: "culture", label: "วัฒนธรรม", emoji: "🏛️"),
        OnboardingOption(id: "foodie", label: "ชิมอาหาร", emoji: "🍜"),
        OnboardingOption(id: "nature", label: "ธรรมชาติ", emoji: "🌿"),
        OnboardingOption(id: "party", label: "สังสรรค์", emoji: "🎉"),
    ]

    private let budgetOptions: [OnboardingOption] = [
        OnboardingOption(id: "budget", label: "ประหยัด", emoji: "💰"),
        OnboardingOption(id: "mid", label: "ปานกลาง", emoji: "💳"),
        OnboardingOption(id: "luxury", label: "หรูหรา", emoji: "✨"),
        OnboardingOption(id: "flexible", label: "ยืดหยุ่น", emoji: "🤝"),
    ]

    private let interestCategories: [OnboardingOption] = [
        OnboardingOption(id: "beach", label: "ทะเล", emoji: "🌊"),
        OnboardingOption(id: "mountain", label: "ภูเขา", emoji: "⛰️"),
        OnboardingOption(id: "city", label: "เมือง", emoji: "🏙️"),
        OnboardingOption(id: "temple", label: "วัด/ศาสนา", emoji: "⛩️"),
        OnboardingOption(id: "food", label: "อาหาร", emoji: "🍽️"),
        OnboardingOption(id: "shopping", label: "ช้อปปิ้ง", emoji: "🛍️"),
        OnboardingOption(id: "photo", label: "ถ่ายรูป", emoji: "📸"),
        OnboardingOption(id: "sport", label: "กีฬา", emoji: "⚽"),
        OnboardingOption(id: "music", label: "ดนตรี", emoji: "🎵"),
        OnboardingOption(id: "art", label: "ศิลปะ", emoji: "🎨"),
        OnboardingOption(id: "cafe", label: "คาเฟ่", emoji: "☕"),
        OnboardingOption(id: "night", label: "ชีวิตกลางคืน", emoji: "🌃"),
    ]

    private let steps = ["สไตล์การท่องเที่ยว", "งบประมาณ", "ความสนใจ"]

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Steps Indicator
                stepsIndicator()

                // Content
                Group {
                    switch currentStep {
                    case 0: travelStyleStep()
                    case 1: budgetStep()
                    case 2: interestsStep()
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)

                Spacer()

                // Bottom Button
                bottomButton()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    // MARK: - Steps Indicator
    @ViewBuilder
    private func stepsIndicator() -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? Color.adaptiveText : Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .animation(.spring(), value: currentStep)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)

            Text("ขั้นตอน \(currentStep + 1)/\(steps.count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Step 1: Travel Style
    @ViewBuilder
    private func travelStyleStep() -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("คุณชอบท่องเที่ยว\nแบบไหน?")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.adaptiveText)
                    .lineSpacing(4)

                Text("เลือกสไตล์ที่ตรงกับตัวคุณมากที่สุด")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(travelStyles) { opt in
                    OptionCard(
                        option: opt,
                        isSelected: selectedStyle == opt.id,
                        isMulti: false
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedStyle = opt.id
                        }
                        HapticManager.shared.impact(style: .light)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 2: Budget
    @ViewBuilder
    private func budgetStep() -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("งบประมาณ\nแต่ละทริป?")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.adaptiveText)
                    .lineSpacing(4)

                Text("บอกเราเพื่อจับคู่ทริปที่เหมาะกับคุณ")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(budgetOptions) { opt in
                    OptionCard(
                        option: opt,
                        isSelected: selectedBudget == opt.id,
                        isMulti: false
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedBudget = opt.id
                        }
                        HapticManager.shared.impact(style: .light)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 3: Interests
    @ViewBuilder
    private func interestsStep() -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("เลือกสิ่งที่คุณ\nสนใจ")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.adaptiveText)
                    .lineSpacing(4)

                Text("เลือกได้หลายข้อ — เพื่อให้จับคู่ได้แม่นยำขึ้น")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(interestCategories) { opt in
                        OptionCard(
                            option: opt,
                            isSelected: selectedInterests.contains(opt.id),
                            isMulti: true
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if selectedInterests.contains(opt.id) {
                                    selectedInterests.remove(opt.id)
                                } else {
                                    selectedInterests.insert(opt.id)
                                }
                            }
                            HapticManager.shared.impact(style: .light)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Bottom Button
    @ViewBuilder
    private func bottomButton() -> some View {
        VStack(spacing: 12) {
            let canProceed: Bool = {
                switch currentStep {
                case 0: return selectedStyle != nil
                case 1: return selectedBudget != nil
                case 2: return !selectedInterests.isEmpty
                default: return false
                }
            }()

            Button {
                if currentStep < steps.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        currentStep += 1
                    }
                } else {
                    Task { await saveAndFinish() }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                    Text(currentStep < steps.count - 1 ? "ถัดไป" : "เริ่มใช้งาน!")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(canProceed ? Color.adaptiveBackground : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed ? Color.adaptiveText : Color.gray.opacity(0.2))
                .cornerRadius(14)
                .animation(.easeInOut(duration: 0.2), value: canProceed)
            }
            .disabled(!canProceed || isSaving)

            if currentStep > 0 {
                Button("ย้อนกลับ") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        currentStep -= 1
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
    }

    // MARK: - Save
    private func saveAndFinish() async {
        isSaving = true
        var interests: [String] = Array(selectedInterests)
        if let style = selectedStyle { interests.append(style) }
        if let budget = selectedBudget { interests.append(budget) }

        await authViewModel.updateProfile(
            name: authViewModel.currentUser?.name ?? authViewModel.name,
            interests: interests,
            travelStyle: travelStyleFromId(selectedStyle)
        )
        isSaving = false
        // ปิด Onboarding
        authViewModel.needsOnboarding = false
    }

    private func travelStyleFromId(_ id: String?) -> TravelStyle? {
        guard let id = id else { return nil }
        switch id {
        case "adventure":
            return TravelStyle(budget: "budget", pace: "fast", social: "group", accommodation: nil, food: nil, nightlife: nil, transport: nil, photography: nil)
        case "relax":
            return TravelStyle(budget: "mid", pace: "slow", social: "small", accommodation: nil, food: nil, nightlife: nil, transport: nil, photography: nil)
        case "culture":
            return TravelStyle(budget: "mid", pace: "moderate", social: "group", accommodation: nil, food: nil, nightlife: nil, transport: nil, photography: nil)
        case "foodie":
            return TravelStyle(budget: "mid", pace: "moderate", social: "any", accommodation: nil, food: "local", nightlife: nil, transport: nil, photography: nil)
        case "nature":
            return TravelStyle(budget: "budget", pace: "moderate", social: "small", accommodation: nil, food: nil, nightlife: nil, transport: nil, photography: nil)
        case "party":
            return TravelStyle(budget: "mid", pace: "fast", social: "group", accommodation: nil, food: nil, nightlife: "active", transport: nil, photography: nil)
        default:
            return nil
        }
    }
}

// MARK: - Option Card
struct OptionCard: View {
    let option: OnboardingOption
    let isSelected: Bool
    let isMulti: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(option.emoji)
                    .font(.system(size: 30))

                Text(option.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? Color.adaptiveBackground : .adaptiveText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? AnyView(Color.adaptiveText)
                    : AnyView(Color.adaptiveCardBackground)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.15),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isSelected ? 0.96 : 1.0)
            .shadow(
                color: isSelected ? Color.adaptiveText.opacity(0.18) : Color.black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                x: 0, y: 3
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
            .environmentObject(AuthViewModel())
    }
}

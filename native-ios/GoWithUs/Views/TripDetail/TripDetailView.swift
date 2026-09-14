import SwiftUI

struct TripDetailView: View {
    @ObservedObject private var settings = SettingsManager.shared
    let tripId: String
    let autoShowJoin: Bool
    @StateObject private var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var selectedImage: ImageViewerItem? = nil
    @State private var kickParticipantId: String? = nil
    @State private var kickParticipantName: String = ""
    @State private var showInterestedSheet = false
    @State private var showMapOptions = false
    @State private var mapLocationToOpen = ""
    
    struct ImageViewerItem: Identifiable {
        let id = UUID()
        let urls: [String]
        let initialIndex: Int
    }
    
    init(tripId: String, autoShowJoin: Bool = false) {
        self.tripId = tripId
        self.autoShowJoin = autoShowJoin
        _viewModel = StateObject(wrappedValue: TripDetailViewModel(tripId: tripId))
    }
    
    private func extractTags(from description: String?) -> [String] {
        guard let desc = description else { return [] }
        return desc.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.hasPrefix("#") && $0.count > 1 }
            .map { String($0.dropFirst()) }
    }
    
    private func formatBudget(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.trip == nil {
                VStack(spacing: 12) {
                    ProgressView().tint(.appPrimary).scaleEffect(1.2)
                    Text(tr("กำลังโหลด…", "Loading…"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.adaptiveSecondaryText)
                }
            } else if let trip = viewModel.trip {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // ══════════════════════════════════════════════
                        // ▸ HERO IMAGE
                        // ══════════════════════════════════════════════
                        heroImage(trip: trip)
                        
                        // ══════════════════════════════════════════════
                        // ▸ TITLE + DESTINATION (below image)
                        // ══════════════════════════════════════════════
                        titleBelowImage(trip: trip)
                        
                        // ══════════════════════════════════════════════
                        // ▸ CONTENT
                        // ══════════════════════════════════════════════
                        VStack(alignment: .leading, spacing: 18) {
                            badgesRow(trip: trip)
                            infoCards(trip: trip)
                            
                            if let score = trip.matchScore {
                                softDivider()
                                compatibilitySection(trip: trip, score: score)
                            }
                            
                            softDivider()
                            creatorSection(trip: trip)
                            
                            softDivider()
                            descriptionSection(trip: trip)
                            tagsSection(trip: trip)
                            
                            itinerarySection(trip: trip)
                            
                            gallerySection(trip: trip)
                            participantsSection(trip: trip)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 200)
                    }
                }
                .refreshable {
                    await viewModel.loadTrip()
                }
                
                // ══════════════════════════════════════════════
                // ▸ FLOATING ACTION BAR
                // ══════════════════════════════════════════════
                VStack(spacing: 0) {
                    Spacer()
                    actionBar(trip: trip)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            
            // ══════════════════════════════════════════════
            // ▸ BACK BUTTON (floating, safe area correct)
            // ══════════════════════════════════════════════
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(11)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .background(Color.black.opacity(0.25))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if viewModel.isCreator || viewModel.isAdmin {
                        Button { showEditSheet = true } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(11)
                                .background(.ultraThinMaterial.opacity(0.6))
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }
                    
                    if viewModel.hasJoined, let trip = viewModel.trip {
                        NavigationLink(destination: ChatDetailView(
                            chatTitle: trip.title, tripId: trip.id, partnerId: nil
                        )) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(11)
                                .background(.ultraThinMaterial.opacity(0.6))
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .hideTabBar(true)
        .onTapGesture { hideKeyboard() }
        .task {
            if viewModel.trip == nil {
                await viewModel.loadTrip() 
            }
            if autoShowJoin {
                viewModel.showJoinSheet = true
            }
        }
        .alert(tr("ยืนยันการลบ", "Confirm deletion"), isPresented: $showDeleteAlert) {
            Button(tr("ยกเลิก", "Cancel"), role: .cancel) {}
            Button(tr("ลบ", "Delete"), role: .destructive) {
                Task { if await viewModel.deleteTrip() { dismiss() } }
            }
        } message: { Text(tr("คุณต้องการลบทริปนี้ใช่หรือไม่?", "Are you sure you want to delete this trip?")) }
        .alert(tr("เตะออกจากทริป", "Remove from trip"), isPresented: Binding(
            get: { kickParticipantId != nil },
            set: { if !$0 { kickParticipantId = nil } }
        )) {
            Button(tr("ยกเลิก", "Cancel"), role: .cancel) { kickParticipantId = nil }
            Button(tr("เตะ ออก", "Remove"), role: .destructive) {
                if let uid = kickParticipantId {
                    Task {
                        await viewModel.removeParticipant(userId: uid)
                        kickParticipantId = nil
                    }
                }
            }
        } message: {
            Text(SettingsManager.shared.currentLanguage == .thai
                 ? "ต้องการนำ \(kickParticipantName) ออกจากทริปนี้ใช่หรือไม่?"
                 : "Remove \(kickParticipantName) from this trip?")
        }
        .confirmationDialog(tr("เลือกแอปแผนที่", "Choose a map app"), isPresented: $showMapOptions, titleVisibility: .visible) {
            Button("Apple Maps") {
                openAppleMaps(location: mapLocationToOpen)
            }
            Button("Google Maps") {
                openGoogleMaps(location: mapLocationToOpen)
            }
            Button(tr("ยกเลิก", "Cancel"), role: .cancel) {}
        }
        .tint(.appPrimary)
        .sheet(isPresented: $showInterestedSheet) {
            InterestTripSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            Task {
                await viewModel.loadTrip()
            }
        }) {
            if let trip = viewModel.trip { CreateTripView(trip: trip) }
        }
        .sheet(isPresented: $viewModel.showLeaveSheet) { LeaveTripSheet(viewModel: viewModel) }
        .sheet(isPresented: $viewModel.showJoinSheet) { JoinTripSheet(viewModel: viewModel) }
        .fullScreenCover(item: $selectedImage) { item in
            ImageViewerView(urls: item.urls, initialIndex: item.initialIndex) {
                selectedImage = nil
            }
        }
    }
    
    // MARK: - Hero Image (รูปอย่างเดียว ไม่มี overlay ชื่อ)
    @ViewBuilder
    private func heroImage(trip: Trip) -> some View {
        let allImages: [String] = {
            var imgs = [String]()
            if let m = trip.imageUrl, !m.isEmpty { imgs.append(m) }
            if let g = trip.gallery { for i in g where !imgs.contains(i) { imgs.append(i) } }
            return imgs
        }()
        
        GeometryReader { geometry in
        ZStack(alignment: .bottom) {
            if allImages.isEmpty {
                Image(trip.category.coverAssetName)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 240).clipped()
            } else {
                TabView {
                    ForEach(Array(allImages.enumerated()), id: \.offset) { index, url in
                        CustomAsyncImage(url: url, contentMode: .fill)
                            .frame(width: geometry.size.width, height: 240).clipped()
                            .onTapGesture { 
                                selectedImage = ImageViewerItem(urls: allImages, initialIndex: index) 
                            }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(width: geometry.size.width, height: 240)
            }
            
            // Gradient scrim (เบาลงเพราะไม่ต้องรองรับตัวอักษรแล้ว)
            LinearGradient(colors: [.clear, .black.opacity(0.35)],
                           startPoint: .center, endPoint: .bottom)
                .frame(height: 80)
        }
        .frame(width: geometry.size.width, height: 240)
        .clipped()
        }
        .frame(height: 240)
    }
    
    // MARK: - Title Below Image
    @ViewBuilder
    private func titleBelowImage(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.adaptiveText)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text(localizedPlaceName(trip.destination))
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.adaptiveSecondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }
    
    // MARK: - Badges
    @ViewBuilder
    private func badgesRow(trip: Trip) -> some View {
        HStack(spacing: 8) {
            let styles = Array(([trip.category.rawValue] + trip.interestTags).reduce(into: [String]()) { result, style in
                if !result.contains(style) { result.append(style) }
            }.prefix(3))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(styles, id: \.self) { style in
                        HStack(spacing: 5) {
                            let iconName = INTEREST_CATEGORIES.first(where: { $0.label == style })?.icon ?? "✈️"
                            Text(iconName).font(.system(size: 11))
                            Text(localizedInterestName(style)).font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.appPrimary)
                        .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)


        }
    }
    
    // MARK: - Title + Meta
    @ViewBuilder
    private func titleSection(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(trip.title)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.adaptiveText)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 18) {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(Color(hex: "#EF4444"))
                    Text(localizedPlaceName(trip.destination))
                }
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#3B82F6"))
                    Text(trip.formattedDateRange)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.adaptiveSecondaryText)
        }
    }
    
    // MARK: - Compatibility Section
    @ViewBuilder
    private func compatibilitySection(trip: Trip, score: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#10B981"))
                Text(tr("ความเข้ากันของคุณ", "Your compatibility"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.adaptiveText)
            }
            
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(
                            LinearGradient(colors: scoreGradientColors(score: score), startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(score)%")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(scoreColor(score: score))
                        Text(tr("แมตช์", "Match"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }

                // Factor list
                VStack(alignment: .leading, spacing: 14) {
                    let bd = trip.matchBreakdown
                    compatibilityRow(
                        icon: "banknote",
                        label: tr("งบประมาณ", "Budget"),
                        color: Color(hex: "#3B82F6"),
                        score: bd?.budget,
                        warningBelow: 50,
                        warningText: tr("งบประมาณไม่เพียงพอสำหรับทริปนี้", "Budget is insufficient for this trip")
                    )
                    compatibilityRow(icon: "list.number", label: tr("จำนวนกิจกรรมต่อวัน", "Activities per day"), color: Color.appSecondary, score: bd?.activityStyle)
                    compatibilityRow(icon: "tag.fill", label: tr("ความชอบ", "Interests"), color: Color(hex: "#F59E0B"), score: bd?.category)
                    compatibilityRow(icon: "clock.fill", label: tr("ช่วงเวลา", "Time of day"), color: Color(hex: "#EF4444"), score: bd?.timeOfDay)
                }

            }
            .padding(18)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(20)
            .shadow(color: scoreColor(score: score).opacity(0.10), radius: 12, x: 0, y: 4)

            Text(scoreLabel(score: score))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.adaptiveSecondaryText)
                .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private func compatibilityRow(
        icon: String,
        label: String,
        color: Color,
        score: Int?,
        warningBelow: Int? = nil,
        warningText: String? = nil
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.adaptiveSecondaryText)
                
                Spacer(minLength: 8)
                
                if let s = score {
                    Text("\(s)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(compatibilityFactorColor(score: s, warningBelow: warningBelow))
                } else {
                    Text(tr("ไม่มีข้อมูล", "No data"))
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            
            if let s = score {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.15))
                            .frame(height: 4)
                        Capsule().fill(compatibilityFactorColor(score: s, warningBelow: warningBelow))
                            .frame(width: geo.size.width * CGFloat(s) / 100.0, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.leading, 26)

                if let warningBelow, let warningText, s < warningBelow {
                    Text(warningText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.leading, 26)
                }
            }
        }
    }

    private func compatibilityFactorColor(score: Int, warningBelow: Int?) -> Color {
        if let warningBelow, score < warningBelow {
            return Color(hex: "#EF4444")
        }
        return scoreColor(score: score)
    }
    
    private func scoreColor(score: Int) -> Color {
        switch score {
        case 75...100: return Color(hex: "#10B981") // Green
        case 50...74:  return Color(hex: "#3B82F6") // Blue
        case 25...49:  return Color(hex: "#F59E0B") // Orange
        default:       return Color(hex: "#EF4444") // Red
        }
    }
    
    private func scoreGradientColors(score: Int) -> [Color] {
        switch score {
        case 75...100: return [Color(hex: "#10B981"), Color(hex: "#34D399")]
        case 50...74:  return [Color(hex: "#3B82F6"), Color(hex: "#60A5FA")]
        case 25...49:  return [Color(hex: "#F59E0B"), Color(hex: "#FCD34D")]
        default:       return [Color(hex: "#EF4444"), Color(hex: "#F87171")]
        }
    }
    
    private func scoreLabel(score: Int) -> String {
        switch score {
        case 75...100: return tr("ความเหมาะสมสูง", "Highly compatible")
        case 50...74:  return tr("ความเหมาะสมปานกลาง", "Moderately compatible")
        case 25...49:  return tr("ความเหมาะสมต่ำ", "Low compatibility")
        default:       return tr("ความเหมาะสมต่ำมาก", "Very low compatibility")
        }
    }

    // MARK: - Trip Summary
    private func tripDateSummary(trip: Trip) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: SettingsManager.shared.currentLanguage == .thai ? "th_TH" : "en_US")
        formatter.dateFormat = "d MMM yyyy"
        let start = formatter.string(from: trip.startDate)
        guard let end = trip.endDate,
              !Calendar.current.isDate(trip.startDate, inSameDayAs: end) else {
            return start
        }
        return "\(start) – \(formatter.string(from: end))"
    }

    private func tripDayCount(trip: Trip) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate ?? trip.startDate)
        return max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
    }

    private func infoCards(trip: Trip) -> some View {
        VStack(spacing: 0) {
            tripSummaryRow(
                icon: "banknote", color: Color.appSecondary,
                title: tr("งบประมาณ", "Budget"),
                value: "\(formatBudget(trip.budget)) \(tr("บาท", "THB"))",
                detail: trip.budgetTypeLabel
            )
            Divider()
                .padding(.leading, 72)
                .padding(.trailing, 18)
            tripSummaryRow(
                icon: "person.2", color: Color(hex: "#0D9488"),
                title: tr("ผู้ร่วมเดินทาง", "Travelers"),
                value: "\(trip.currentParticipants) \(tr("จาก", "of")) \(trip.maxParticipants)",
                detail: trip.isFull ? tr("เต็มแล้ว", "Full") : "\(max(0, trip.maxParticipants - trip.currentParticipants)) \(tr("ที่ว่าง", "spots available"))",
                detailColor: trip.isFull ? Color(hex: "#EF4444") : Color(hex: "#16A34A")
            )
            Divider()
                .padding(.leading, 72)
                .padding(.trailing, 18)
            tripSummaryRow(
                icon: "calendar", color: Color.appPrimary,
                title: tr("วันเดินทาง", "Travel dates"), value: tripDateSummary(trip: trip),
                detail: "\(tripDayCount(trip: trip)) \(tr("วัน", "days"))"
            )
        }
        .background(Color.adaptiveBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private func tripSummaryRow(icon: String, color: Color, title: String, value: String, detail: String? = nil, detailColor: Color? = nil) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.adaptiveSecondaryText)
                    Spacer(minLength: 0)
                    if let detail = detail {
                        Text(detail)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(detailColor ?? color)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background((detailColor ?? color).opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.adaptiveText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Creator Section
    @ViewBuilder
    private func creatorSection(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text(tr("ผู้จัดทริป", "Trip organizer"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.adaptiveText)
            }
            
            // Creator card — tappable for profile ✅
            NavigationLink(destination: UserProfileView(user: trip.creator)) {
                HStack(spacing: 14) {
                    // Avatar dynamically tracking self
                    UserAvatarView(user: trip.creator, size: 50)
                        .shadow(color: Color.appPrimary.opacity(0.2), radius: 6, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(trip.creator.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            if trip.creator.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.appSecondary)
                            }
                        }
                        
                        if trip.creator.role == .admin {
                            Text("ADMIN")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color.appPrimary)
                                .cornerRadius(4)
                        } else {
                            Text(tr("ดูโปรไฟล์ →", "View profile →"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.adaptiveSecondaryText.opacity(0.4))
                }
                .padding(14)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
            
            // Chat with creator — separate button
            NavigationLink(destination: ChatDetailView(
                chatTitle: trip.creator.name, tripId: nil, partnerId: trip.creator.id
            )) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13))
                    Text(tr("ส่งข้อความถึงผู้จัด", "Message organizer"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.appPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.appPrimary.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Description
    @ViewBuilder
    private func descriptionSection(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text") // Minimal
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSecondary)
                Text(tr("รายละเอียด", "Details"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.adaptiveText)
            }
            
            Text(trip.description ?? tr("ไม่มีรายละเอียด", "No description"))
                .font(.system(size: 14))
                .foregroundColor(.adaptiveSecondaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Tags
    @ViewBuilder
    private func tagsSection(trip: Trip) -> some View {
        let tags = extractTags(from: trip.description)
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.appPrimary.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    // MARK: - Itinerary
    @ViewBuilder
    private func itinerarySection(trip: Trip) -> some View {
        if let itinerary = trip.itinerary, !itinerary.isEmpty {
            softDivider()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#10B981"))
                    Text(tr("การเดินทางแต่ละวัน", "Daily itinerary"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.adaptiveText)
                }
                
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(itinerary.sorted(by: { $0.day < $1.day })) { dayPlan in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(SettingsManager.shared.currentLanguage == .thai ? "วันที่ \(dayPlan.day)" : "Day \(dayPlan.day)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.appPrimary.opacity(0.1))
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(dayPlan.activities) { activity in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(activity.time)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .frame(width: 45, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(activity.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.adaptiveText)
                                            
                                            if !activity.location.isEmpty {
                                                Button {
                                                    mapLocationToOpen = activity.location
                                                    showMapOptions = true
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "mappin.circle.fill")
                                                            .foregroundColor(Color(hex: "#EA4335"))
                                                        Text(activity.location)
                                                            .underline()
                                                    }
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Color(hex: "#4285F4"))
                                                }
                                            }
                                            
                                            if !activity.description.isEmpty {
                                                Text(activity.description)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(2)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Gallery
    @ViewBuilder
    private func gallerySection(trip: Trip) -> some View {
        if let gallery = trip.gallery, !gallery.isEmpty {
            softDivider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.stack") // Minimal
                        .font(.system(size: 13))
                        .foregroundColor(Color.appSecondary)
                    Text(tr("รูปภาพ", "Photos"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.adaptiveText)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    let allImgs: [String] = {
                        var imgs = [String]()
                        if let m = trip.imageUrl, !m.isEmpty { imgs.append(m) }
                        if let g = trip.gallery { for i in g where !imgs.contains(i) { imgs.append(i) } }
                        return imgs
                    }()
                    
                    HStack(spacing: 12) {
                        ForEach(Array((trip.gallery ?? []).enumerated()), id: \.offset) { index, url in
                            CustomAsyncImage(url: url)
                                .frame(width: 200, height: 150)
                                .cornerRadius(14).clipped()
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .onTapGesture { 
                                    // Find index in overall list
                                    let globalIndex = allImgs.firstIndex(of: url) ?? 0
                                    selectedImage = ImageViewerItem(urls: allImgs, initialIndex: globalIndex) 
                                }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Participants
    @ViewBuilder
    private func participantsSection(trip: Trip) -> some View {
        if let participants = trip.participants, !participants.isEmpty {
            softDivider()
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "person.3") // Minimal
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#0EA5E9"))
                    Text(SettingsManager.shared.currentLanguage == .thai ? "จำนวนคน (\(participants.count))" : "Participants (\(participants.count))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.adaptiveText)
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(participants.enumerated()), id: \.element.id) { idx, p in
                        let isMe = p.userId == viewModel.currentUserId
                        let name = p.user?.name ?? p.name
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                // ✅ RAINBOW FRAME & AVATAR
                                ZStack {
                                    UserAvatarView(user: p.user, size: 42)
                                    
                                    // ✅ RAINBOW RING FOR GOING
                                    let currentStatus = p.status ?? "going"
                                    if currentStatus == "going" {
                                        Circle()
                                            .stroke(Color.appPrimary, lineWidth: 3.5)
                                            .frame(width: 48, height: 48)
                                    } else if currentStatus == "interested" {
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 2)
                                            .frame(width: 48, height: 48)
                                    }
                                }
                                .frame(width: 50, height: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(name)
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.adaptiveText)
                                        
                                        if p.user?.isVerified == true {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.appSecondary)
                                        }
                                        
                                        if isMe {
                                            Text(tr("(คุณ)", "(You)"))
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                    
                                    // Status Badge (Below Name)
                                    let displayStatus = p.status ?? "going"
                                    HStack(spacing: 5) {
                                        Image(systemName: displayStatus == "interested" ? "star.fill" : "checkmark.seal.fill")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(displayStatus == "interested" ? tr("สนใจทริปนี้", "Interested") : tr("ไปแน่นอน!", "Going!"))
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(displayStatus == "interested" ? .orange : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        displayStatus == "interested" ? AnyView(Color.orange.opacity(0.15)) : AnyView(Color.appPrimary)
                                    )
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                if !isMe {
                                    // ✅ ดูโปรไฟล์ — ใช้ UserProfileView (fetch จาก API)
                                    if let user = p.user {
                                        NavigationLink(destination: UserProfileView(user: user)) {
                                            Image(systemName: "person.crop.circle")
                                                .font(.system(size: 18))
                                                .foregroundColor(.appPrimary)
                                                .frame(width: 34, height: 34)
                                        }
                                    }
                                    
                                    // แชท
                                    NavigationLink(destination: ChatDetailView(
                                        chatTitle: name, tripId: nil, partnerId: p.userId
                                    )) {
                                        Image(systemName: "paperplane")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#0EA5E9"))
                                            .frame(width: 34, height: 34)
                                            .background(Color(hex: "#0EA5E9").opacity(0.08))
                                            .clipShape(Circle())
                                    }
                                    
                                    // ลบ (admin/creator เท่านั้น)
                                    if viewModel.isCreator || viewModel.isAdmin {
                                        Button {
                                            kickParticipantName = name
                                            kickParticipantId = p.userId
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.red.opacity(0.6))
                                                .frame(width: 28, height: 28)
                                                .background(Color.red.opacity(0.06))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            
                            if idx < participants.count - 1 {
                                Divider().padding(.leading, 66)
                            }
                        }
                    }
                }
                .background(Color.adaptiveCardBackground)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
        }
    }
    
    // MARK: - Action Bar
    @ViewBuilder
    private func actionBar(trip: Trip) -> some View {
        VStack(spacing: 0) {
            // Soft fade
            LinearGradient(colors: [Color.adaptiveBackground.opacity(0), Color.adaptiveBackground],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 24).allowsHitTesting(false)
            
            VStack(spacing: 12) {
                if let userId = viewModel.currentUserId,
                   let participant = trip.participants?.first(where: { $0.userId == userId }) {
                    // USER ALREADY JOINED
                    HStack(spacing: 10) {
                        HStack(spacing: 12) {
                            // Switch Status Button (Prominent)
                            Button {
                                let currentStatus = participant.status ?? "going"
                                let newStatus = (currentStatus == "going") ? "interested" : "going"
                                Task {
                                    if await viewModel.joinTrip(interests: participant.interests ?? [], status: newStatus) {
                                        try? await Task.sleep(nanoseconds: 300_000_000)
                                        await viewModel.loadTrip()
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    if viewModel.isJoining {
                                        ProgressView()
                                            .tint(participant.status == "interested" ? .white : .orange)
                                            .scaleEffect(0.8)
                                    }
                                    Text(
                                        viewModel.isJoining
                                            ? tr("กำลังเปลี่ยนสถานะ...", "Updating status…")
                                            : (participant.status == "interested"
                                                ? tr("เปลี่ยนเป็นจะไปแน่นอน", "Mark as going")
                                                : tr("เปลี่ยนเป็นสนใจ", "Mark as interested"))
                                    )
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(participant.status == "interested" ? .white : .orange)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(participant.status == "interested" ? Color.appPrimary : Color.orange.opacity(0.15))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isJoining)
                        }
                        
                        Button { viewModel.showLeaveSheet = true } label: {
                            Text(tr("ออกจากทริป", "Leave trip"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(Color.red.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1))
                                .cornerRadius(14)
                        }
                    }
                } else if !trip.isFull {
                    // USER NOT JOINED
                    HStack(spacing: 12) {
                        // "Interested" button
                        Button {
                            showInterestedSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                if viewModel.isJoining {
                                    ProgressView().tint(.yellow).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                Text(viewModel.isJoining ? tr("กำลังเข้า...", "Joining…") : tr("สนใจ", "Interested"))
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.adaptiveBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                            .cornerRadius(14)
                        }
                        .disabled(viewModel.isJoining)

                        // "Will Go" triggers the join flow (with interests)
                        Button { viewModel.showJoinSheet = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text(tr("จะไปด้วย", "Join trip"))
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.adaptiveBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appPrimary, lineWidth: 3)
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.appAccent.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                    }
                } else {
                    Text(tr("ทริปเต็มแล้ว", "Trip is full"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.adaptiveSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(14)
                }
                
                // Removed Edit/Delete from bottom as requested, keep top buttons instead
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
            .background(Color.adaptiveBackground)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
        }
    }
    
    // MARK: - Soft Divider
    @ViewBuilder
    private func softDivider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.08))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
    
    // MARK: - Map Helpers
    private func openAppleMaps(location: String) {
        guard let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let urlString = "maps://?q=\(query)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openGoogleMaps(location: String) {
        guard let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let urlString = "https://www.google.com/maps/search/?api=1&query=\(query)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openGoogleMapsRoute(locations: [String]) {
        guard locations.count >= 2 else { return }
        let origin = locations.first!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let destination = locations.last!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var urlString = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(destination)"
        
        if locations.count > 2 {
            let waypoints = locations.dropFirst().dropLast()
                .compactMap { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }
                .joined(separator: "|")
            urlString += "&waypoints=\(waypoints)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ImageViewerView with Paging Support
struct ImageViewerView: View {
    let urls: [String]
    let initialIndex: Int
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex: Int
    
    init(urls: [String], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.urls = urls
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    CustomAsyncImage(url: url).scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack { TripDetailView(tripId: "1") }
}

// MARK: - Interest Trip Sheet
struct InterestTripSheet: View {
    @ObservedObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding(.top, 32)
            
            VStack(spacing: 8) {
                Text(tr("สนใจทริปนี้", "Save this trip"))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text(tr("คุณต้องการบันทึกทริปนี้เข้ารายการโปรดใช่หรือไม่?", "Would you like to save this trip to Favorites?"))
                    .font(.system(size: 15))
                    .foregroundColor(.adaptiveSecondaryText)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text(tr("ยกเลิก", "Cancel"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    Task {
                        let success = await viewModel.joinTrip(interests: [], status: "interested")
                        if success {
                            dismiss()
                        } else {
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isJoining {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(viewModel.isJoining ? tr("กำลังบันทึก...", "Saving…") : tr("ยืนยัน", "Confirm"))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isJoining)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.height(280)])
        .alert(tr("ไม่สามารถบันทึกได้", "Unable to save"), isPresented: $showErrorAlert) {
            Button(tr("ตรวจสอบ", "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? tr("เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง", "Something went wrong. Please try again."))
        }
    }
}

import SwiftUI

struct TripDetailView: View {
    let tripId: String
    @StateObject private var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var selectedImage: ImageViewerItem? = nil
    
    struct ImageViewerItem: Identifiable {
        let id = UUID()
        let url: String
    }
    
    init(tripId: String) {
        self.tripId = tripId
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
            
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.appPrimary).scaleEffect(1.2)
                    Text("กำลังโหลด…")
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
                        // ▸ CONTENT
                        // ══════════════════════════════════════════════
                        VStack(alignment: .leading, spacing: 22) {
                            badgesRow(trip: trip)
                            infoCards(trip: trip)
                            
                            softDivider()
                            creatorSection(trip: trip)
                            
                            softDivider()
                            descriptionSection(trip: trip)
                            tagsSection(trip: trip)
                            
                            itinerarySection(trip: trip)
                            
                            gallerySection(trip: trip)
                            participantsSection(trip: trip)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                        .padding(.bottom, 200)
                    }
                }
                
                // ══════════════════════════════════════════════
                // ▸ FLOATING ACTION BAR
                // ══════════════════════════════════════════════
                VStack(spacing: 0) {
                    Spacer()
                    actionBar(trip: trip)
                }
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
                    
                    if viewModel.isCreator {
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
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .hideTabBar(true)
        .onTapGesture { hideKeyboard() }
        .task { await viewModel.loadTrip() }
        .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
            Button("ยกเลิก", role: .cancel) {}
            Button("ลบ", role: .destructive) {
                Task { if await viewModel.deleteTrip() { dismiss() } }
            }
        } message: { Text("คุณต้องการลบทริปนี้ใช่หรือไม่?") }
        .sheet(isPresented: $showEditSheet) {
            if let trip = viewModel.trip { CreateTripView(trip: trip) }
        }
        .sheet(isPresented: $viewModel.showLeaveSheet) { LeaveTripSheet(viewModel: viewModel) }
        .sheet(isPresented: $viewModel.showJoinSheet) { JoinTripSheet(viewModel: viewModel) }
        .fullScreenCover(item: $selectedImage) { item in
            ImageViewerView(url: item.url) {
                selectedImage = nil
            }
        }
    }
    
    // MARK: - Hero Image
    @ViewBuilder
    private func heroImage(trip: Trip) -> some View {
        let allImages: [String] = {
            var imgs = [String]()
            if let m = trip.imageUrl, !m.isEmpty { imgs.append(m) }
            if let g = trip.gallery { for i in g where !imgs.contains(i) { imgs.append(i) } }
            return imgs
        }()
        
        ZStack(alignment: .bottom) {
            if allImages.isEmpty {
                Image("sosuke")
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity).frame(height: 300).clipped()
            } else {
                TabView {
                    ForEach(allImages, id: \.self) { url in
                        CustomAsyncImage(url: url, contentMode: .fill)
                            .frame(maxWidth: .infinity).frame(height: 300).clipped()
                            .onTapGesture { selectedImage = ImageViewerItem(url: url) }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 300)
            }
            
            // Gradient scrim
            LinearGradient(colors: [.clear, .black.opacity(0.8)],
                           startPoint: .center, endPoint: .bottom)
                .frame(height: 140)
            
            // Title Header Overlay
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                    Text(trip.destination)
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white.opacity(0.95))
                
                // Current User Status Badge (Top right of title)
                if let userId = viewModel.currentUserId,
                   let participant = trip.participants?.first(where: { $0.userId == userId }) {
                    HStack(spacing: 4) {
                        Image(systemName: participant.status == "interested" ? "star.fill" : "checkmark.seal.fill")
                        Text(participant.status == "interested" ? "สนใจทริปนี้อยู่" : "คุณจะไปด้วย!")
                    }
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if participant.status == "interested" {
                                Color.yellow
                            } else {
                                Color.rainbowGradient
                            }
                        }
                    )
                    .cornerRadius(10)
                    .shadow(color: (participant.status == "interested" ? Color.yellow : Color.appPrimary).opacity(0.5), radius: 8)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Badges
    @ViewBuilder
    private func badgesRow(trip: Trip) -> some View {
        HStack(spacing: 8) {
            // Category — gradient pill
            HStack(spacing: 5) {
                Image(systemName: "airplane").font(.system(size: 10, weight: .bold))
                Text(trip.category.rawValue).font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(
                LinearGradient(colors: [Color.appPrimary, Color.appSecondary],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            
            Spacer()
            
            // Status
            if trip.isFull {
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 6, height: 6)
                    Text("เต็มแล้ว").font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: "#DC2626"))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Color(hex: "#FEE2E2"))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#22C55E")).frame(width: 6, height: 6)
                    Text("ว่าง \(trip.maxParticipants - trip.currentParticipants) ที่")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: "#16A34A"))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Color(hex: "#DCFCE7"))
                .clipShape(Capsule())
            }
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
                    Image(systemName: "mappin.circle") // Minimal
                        .foregroundColor(Color(hex: "#EF4444"))
                    Text(trip.destination)
                }
                HStack(spacing: 5) {
                    Image(systemName: "calendar") // Minimal
                        .foregroundColor(Color(hex: "#3B82F6"))
                    Text(trip.formattedDateRange)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.adaptiveSecondaryText)
        }
    }
    
    // MARK: - Info Cards
    @ViewBuilder
    private func infoCards(trip: Trip) -> some View {
        HStack(spacing: 12) {
            // Budget card — blue gradient
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#60A5FA")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "banknote")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("งบประมาณ")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.adaptiveSecondaryText)
                Text("\(formatBudget(trip.budget)) ฿")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.adaptiveText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(18)
            .shadow(color: Color(hex: "#3B82F6").opacity(0.08), radius: 10, x: 0, y: 4)
            
            // People card — rose gradient
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#F43F5E"), Color(hex: "#FB7185")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.2")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("จำนวนคน")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.adaptiveSecondaryText)
                Text("\(trip.currentParticipants)/\(trip.maxParticipants)")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.adaptiveText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(18)
            .shadow(color: Color(hex: "#F43F5E").opacity(0.08), radius: 10, x: 0, y: 4)

            // Dates card — purple gradient
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#A78BFA")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("ระยะเวลา")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.adaptiveSecondaryText)
                Text(trip.formattedDateRange)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.adaptiveText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(18)
            .shadow(color: Color(hex: "#8B5CF6").opacity(0.08), radius: 10, x: 0, y: 4)
        }
    }
    
    // MARK: - Creator Section
    @ViewBuilder
    private func creatorSection(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text("ผู้จัดทริป")
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
                                    .foregroundColor(.blue)
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
                            Text("ดูโปรไฟล์ →")
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
                    Text("ส่งข้อความถึงผู้จัด")
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
                    .foregroundColor(Color(hex: "#8B5CF6"))
                Text("รายละเอียด")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.adaptiveText)
            }
            
            Text(trip.description ?? "ไม่มีรายละเอียด")
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
                    Text("การเดินทางแต่ละวัน")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.adaptiveText)
                }
                
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(itinerary.sorted(by: { $0.day < $1.day })) { dayPlan in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("วันที่ \(dayPlan.day)")
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
                                                HStack(spacing: 4) {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .foregroundColor(.red)
                                                    Text(activity.location)
                                                }
                                                .font(.system(size: 12))
                                                .foregroundColor(.adaptiveSecondaryText)
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
                        .foregroundColor(Color(hex: "#EC4899"))
                    Text("รูปภาพ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.adaptiveText)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(gallery, id: \.self) { url in
                            CustomAsyncImage(url: url)
                                .frame(width: 200, height: 150)
                                .cornerRadius(14).clipped()
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .onTapGesture { selectedImage = ImageViewerItem(url: url) }
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
                    Text("ผู้เข้าร่วม (\(participants.count))")
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
                                    
                                    // Colored ring ONLY if status is set
                                    if p.status == "going" {
                                        Circle()
                                            .stroke(Color.rainbowGradient, lineWidth: 2.5) // Tighter & Thinner
                                            .frame(width: 47, height: 47)
                                    } else if p.status == "interested" {
                                        // No rainbow for interested, maybe a subtle yellow or nothing
                                        Circle()
                                            .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
                                            .frame(width: 47, height: 47)
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
                                                .foregroundColor(.blue)
                                        }
                                        
                                        if isMe {
                                            Text("(คุณ)")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                    
                                    // ✅ STATUS DISPLAY
                                    let displayStatus = p.status ?? "interested" // Fallback to interested if not sure
                                    HStack(spacing: 5) {
                                        Image(systemName: displayStatus == "interested" ? "star.fill" : "checkmark.seal.fill")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(displayStatus == "interested" ? "สนใจทริปนี้" : "จะไปด้วยแน่นอน!")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(displayStatus == "interested" ? .black : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Group {
                                            if displayStatus == "going" {
                                                Color.black.opacity(0.85) // Dark background for contrast
                                            } else {
                                                Color.yellow
                                            }
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(displayStatus == "going" ? AnyShapeStyle(Color.rainbowGradient) : AnyShapeStyle(Color.clear), lineWidth: 2)
                                    )
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 3)
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
                                            Task { await viewModel.removeParticipant(userId: p.userId) }
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
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            // Current Status Display
                            HStack {
                                Text("สถานะ:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.adaptiveSecondaryText)
                                Text(participant.status == "interested" ? "สนใจ" : "จะไปด้วย")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(participant.status == "interested" ? .yellow : .appPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(10)
                            
                            Spacer()
                            
                            // Switch Status Button
                            Button {
                                let currentStatus = participant.status ?? "interested" // Use actual status or assume interested
                                let newStatus = (currentStatus == "interested") ? "going" : "interested"
                                Task {
                                    if await viewModel.joinTrip(interests: participant.interests ?? [], status: newStatus) {
                                        // RELOAD TRIP DATA TO ENSURE STATUS UPDATE
                                        await viewModel.loadTrip() 
                                    }
                                }
                            } label: {
                                HStack {
                                    if viewModel.isJoining {
                                        ProgressView().scaleEffect(0.7)
                                    }
                                    Text(participant.status == "interested" ? "เปลี่ยนเป็นจะไปด้วย" : "เปลี่ยนเป็นสนใจ")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(participant.status == "interested" ? .white : .black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(participant.status == "interested" ? Color.appPrimary : Color.yellow)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isJoining)
                        }
                        
                        Button { viewModel.showLeaveSheet = true } label: {
                            Text("ออกจากทริป")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
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
                            Task { await viewModel.joinTrip(interests: [], status: "interested") }
                        } label: {
                            HStack {
                                if viewModel.isJoining {
                                    ProgressView().tint(.yellow).scaleEffect(0.8)
                                }
                                Text(viewModel.isJoining ? "กำลังจด..." : "สนใจ")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.adaptiveBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.yellow, lineWidth: 3) // Yellow Frame for Interested
                            )
                            .cornerRadius(14)
                        }
                        .disabled(viewModel.isJoining)

                        // "Will Go" triggers the join flow (with interests)
                        Button { viewModel.showJoinSheet = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("จะไปด้วย")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.adaptiveBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.rainbowGradient, lineWidth: 3) // RAINBOW FRAME!
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.appAccent.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                    }
                } else {
                    Text("ทริปเต็มแล้ว")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.adaptiveSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(14)
                }
                
                if viewModel.isCreator || viewModel.isAdmin {
                    HStack(spacing: 12) {
                        Button { showEditSheet = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                Text("แก้ไข")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.adaptiveText)
                            .cornerRadius(12)
                        }
                        
                        Button { showDeleteAlert = true } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#DC2626"))
                                .frame(width: 50).padding(.vertical, 14)
                                .background(Color(hex: "#FEE2E2"))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color.adaptiveBackground.ignoresSafeArea(edges: .bottom))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -5)
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
}

// MARK: - ImageViewerView to fix full screen dismiss
struct ImageViewerView: View {
    let url: String
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomAsyncImage(url: url).scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                HStack { Spacer()
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark") // Minimal
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.top, 40) // Status bar clearance
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

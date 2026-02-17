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
    
    // Extract #hashtags from description
    private func extractTags(from description: String?) -> [String] {
        guard let desc = description else { return [] }
        let words = desc.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { $0.hasPrefix("#") && $0.count > 1 }
            .map { String($0.dropFirst()) }
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.adaptiveText)
            } else if let trip = viewModel.trip {
                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image Header (Swipeable)
                        ZStack(alignment: .bottom) {
                            let allImages: [String] = {
                                var images = [String]()
                                if let main = trip.imageUrl, !main.isEmpty {
                                    images.append(main)
                                }
                                if let gallery = trip.gallery {
                                    for img in gallery {
                                        if !images.contains(img) {
                                            images.append(img)
                                        }
                                    }
                                }
                                return images
                            }()
                            
                            if !allImages.isEmpty {
                                TabView {
                                    ForEach(0..<allImages.count, id: \.self) { index in
                                        let imageUrl = allImages[index]
                                        GeometryReader { imgGeo in
                                            CustomAsyncImage(url: imageUrl, contentMode: .fill)
                                                .frame(width: imgGeo.size.width, height: 280)
                                                .clipped()
                                        }
                                        .onTapGesture {
                                            selectedImage = ImageViewerItem(url: imageUrl)
                                        }
                                    }
                                }
                                .tabViewStyle(.page)
                                .indexViewStyle(.page(backgroundDisplayMode: .always))
                                .frame(height: 280)
                                .id("trip_carousel_\(allImages.count)") // Force rebuild when count changes
                            } else {
                                Image("sosuke")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .clipped()
                            }
                            
                            // Buttons moved to overlay
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 24) {
                            // Header Info
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(trip.category.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black)
                                        .cornerRadius(20)
                                    
                                    Spacer()
                                    
                                    // Status Badge
                                    if trip.isFull {
                                        Text("เต็มแล้ว")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red)
                                            .cornerRadius(20)
                                    } else {
                                        Text("ว่าง \(trip.maxParticipants - trip.currentParticipants) ที่")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .cornerRadius(20)
                                    }
                                }
                                
                                Text(trip.title)
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.adaptiveText)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                HStack(spacing: 16) {
                                    Label(trip.destination, systemImage: "map.fill")
                                    Label(trip.formattedDateRange, systemImage: "calendar")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                
                                Divider()
                            }
                            
                            // Creator Info
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ผู้จัด")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                
                                HStack(spacing: 12) {
                                    if let profileImage = trip.creator.profileImage, !profileImage.isEmpty {
                                        CustomAsyncImage(url: profileImage, contentMode: .fill)
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(String(trip.creator.name.prefix(1)))
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.creator.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.adaptiveText)
                                        
                                        if trip.creator.role == .admin {
                                            Text("ADMIN")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.black)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: ChatDetailView(
                                        chatTitle: trip.creator.name,
                                        tripId: nil,
                                        partnerId: trip.creator.id
                                    )) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gray)
                                            .padding(10)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            // Info Grid section
                            VStack(spacing: 16) {
                                InfoRow(icon: "banknote", title: "งบประมาณ", value: "\(trip.budget) บาท")
                                InfoRow(icon: "person.2", title: "จำนวนคน", value: "\(trip.currentParticipants)/\(trip.maxParticipants)")
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("รายละเอียด")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                
                                Text(trip.description ?? "ไม่มีรายละเอียด")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            
                            // Tags
                            if !extractTags(from: trip.description).isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(extractTags(from: trip.description), id: \.self) { tag in
                                            Text("#\(tag)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.appPrimary.opacity(0.12))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            
                            // Gallery Section
                            if let gallery = trip.gallery, !gallery.isEmpty {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("รูปภาพเพิ่มเติม")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(gallery, id: \.self) { imageUrl in
                                                CustomAsyncImage(url: imageUrl)
                                                    .frame(width: 200, height: 150)
                                                    .cornerRadius(12)
                                                    .clipped()
                                                    .onTapGesture {
                                                        selectedImage = ImageViewerItem(url: imageUrl)
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            // Participants
                            if let participants = trip.participants, !participants.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ผู้เข้าร่วม (\(participants.count))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                    
                                    ForEach(participants) { participant in
                                        let isCurrentUser = participant.userId == viewModel.currentUserId
                                        
                                        if isCurrentUser {
                                            // Current user - not tappable
                                            HStack(spacing: 12) {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 36, height: 36)
                                                    .overlay(
                                                        Text(String((participant.user?.name ?? participant.name).prefix(1)))
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.adaptiveText)
                                                    )
                                                
                                                Text(participant.user?.name ?? participant.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.adaptiveText)
                                                
                                                Spacer()
                                                
                                                Text("(คุณ)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            // Other participants - tappable for private chat
                                            HStack(spacing: 12) {
                                                NavigationLink(destination: ChatDetailView(
                                                    chatTitle: participant.user?.name ?? participant.name,
                                                    tripId: nil,
                                                    partnerId: participant.userId
                                                )) {
                                                    HStack(spacing: 12) {
                                                        Circle()
                                                            .fill(Color.gray.opacity(0.2))
                                                            .frame(width: 36, height: 36)
                                                            .overlay(
                                                                Text(String((participant.user?.name ?? participant.name).prefix(1)))
                                                                    .font(.system(size: 14, weight: .bold))
                                                                    .foregroundColor(.adaptiveText)
                                                            )
                                                        
                                                        Text(participant.user?.name ?? participant.name)
                                                            .font(.system(size: 14, weight: .medium))
                                                            .foregroundColor(.adaptiveText)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                if viewModel.isCreator || viewModel.isAdmin {
                                                    Button(action: {
                                                        Task {
                                                            await viewModel.removeParticipant(userId: participant.userId)
                                                        }
                                                    }) {
                                                        Image(systemName: "trash.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.adaptiveText)
                                                            .padding(8)
                                                    }
                                                }
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            }
                        } // End Content VStack
                        .padding(24)
                        .padding(.bottom, 180)
                    } // End Inner VStack
                } // End ScrollView
                
                // Action Buttons (Floating)
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Join / Leave Status
                        if viewModel.hasJoined {
                            Button(action: {
                                viewModel.showLeaveSheet = true
                            }) {
                                Text("ออกจากทริป")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.adaptiveBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.adaptiveText, lineWidth: 2)
                                    )
                                    .cornerRadius(12)
                            }
                        } else if !trip.isFull {
                            Button(action: {
                                viewModel.showJoinSheet = true
                            }) {
                                Text("เข้าร่วมทริป")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.adaptiveBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.adaptiveText)
                                    .cornerRadius(12)
                            }
                        } else {
                            // Trip is full
                            Button(action: {}) {
                                Text("ทริปเต็มแล้ว")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(true)
                        }
                        
                        // Admin / Creator Actions
                        if viewModel.isCreator || viewModel.isAdmin {
                            HStack(spacing: 12) {
                                Button(action: { showEditSheet = true }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("แก้ไข")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.adaptiveBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.adaptiveText)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: { showDeleteAlert = true }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                        .frame(width: 50)
                                        .padding(.vertical, 16)
                                        .background(Color.adaptiveBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.adaptiveText, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.adaptiveBackground)
                }
            } // End else if let trip

            // Header Navigation Buttons (Fixed at Top)
            VStack {
                HStack {
                    // Back Button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Edit Button (If Creator) - Fixed Position
                    if let trip = viewModel.trip, viewModel.isCreator {
                         Button {
                             showEditSheet = true
                         } label: {
                             Image(systemName: "pencil")
                                 .font(.system(size: 18, weight: .bold))
                                 .foregroundColor(.white)
                                 .padding(12)
                                 .background(Color.black.opacity(0.4))
                                 .clipShape(Circle())
                         }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8) // Standard safe area spacing
                
                Spacer()
            }
        } // End ZStack
        .navigationBarHidden(true)
        .hideTabBar(true)
        .onTapGesture {
            hideKeyboard()
        }
        .task {
            await viewModel.loadTrip()
        }
        .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
            Button("ยกเลิก", role: .cancel) {}
            Button("ลบ", role: .destructive) {
                Task {
                    if await viewModel.deleteTrip() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("คุณต้องการลบทริปนี้ใช่หรือไม่?")
        }
        .sheet(isPresented: $showEditSheet) {
            if let trip = viewModel.trip {
                // Ensure CreateTripView is strictly for editing here
                CreateTripView(trip: trip)
            }
        }
        .sheet(isPresented: $viewModel.showLeaveSheet) {
            LeaveTripSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showJoinSheet) {
            JoinTripSheet(viewModel: viewModel)
        }
        .fullScreenCover(item: $selectedImage) { item in
            ZStack {
                Color.black.ignoresSafeArea()
                
                CustomAsyncImage(url: item.url)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { selectedImage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

// Info Row Component


#Preview {
    TripDetailView(tripId: "1")
}

import SwiftUI

struct TripDetailView: View {
    let tripId: String
    @StateObject private var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var selectedImage: ImageViewerItem? = nil
    
    struct ImageViewerItem: Identifiable {
        let id = UUID()
        let url: String
    }
    
    init(tripId: String) {
        self.tripId = tripId
        _viewModel = StateObject(wrappedValue: TripDetailViewModel(tripId: tripId))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.black)
            } else if let trip = viewModel.trip {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image Header (Swipeable)
                        ZStack(alignment: .topLeading) {
                            let allImages = [trip.imageUrl].compactMap { $0 } + (trip.gallery ?? [])
                            
                            if !allImages.isEmpty {
                                TabView {
                                    ForEach(allImages, id: \.self) { imageUrl in
                                        CustomAsyncImage(url: imageUrl)
                                            .frame(height: 280)
                                            .clipped()
                                            .onTapGesture {
                                                selectedImage = ImageViewerItem(url: imageUrl)
                                            }
                                    }
                                }
                                .tabViewStyle(.page)
                                .frame(height: 280)
                            } else {
                                Image("sosuke")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .clipped()
                            }
                            
                            // Header Buttons
                            HStack {
                                Button(action: { dismiss() }) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "arrow.left")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                        )
                                }
                                
                                Spacer()
                                
                                // Chat Button (Group Chat)
                                if viewModel.hasJoined {
                                    NavigationLink(destination: ChatDetailView(
                                        chatTitle: trip.title,
                                        tripId: trip.id,
                                        partnerId: nil
                                    )) {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "message.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.black)
                                            )
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 24) {
                            // Category Badge
                            Text(trip.category.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            
                            // Title
                            Text(trip.title)
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                                .tracking(-0.5)
                            
                            // Info Grid
                            VStack(spacing: 16) {
                                InfoRow(icon: "mappin.circle", title: "สถานที่", value: trip.destination)
                                InfoRow(icon: "calendar", title: "วันที่", value: trip.formattedDateRange)
                                InfoRow(icon: "banknote", title: "งบประมาณ", value: "\(trip.budget) บาท")
                                InfoRow(icon: "person.2", title: "จำนวนคน", value: "\(trip.currentParticipants)/\(trip.maxParticipants)")
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("รายละเอียด")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(trip.description ?? "ไม่มีรายละเอียด")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            
                            // Gallery Section
                            if let gallery = trip.gallery, !gallery.isEmpty {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("รูปภาพเพิ่มเติม")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                    
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
                            
                            // Creator
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ผู้จัด")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(trip.creator.name.prefix(1)))
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.creator.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.black)
                                        
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
                                }
                            }
                            
                            // Participants
                            if let participants = trip.participants, !participants.isEmpty {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ผู้เข้าร่วม (\(participants.count))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                    
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
                                                            .foregroundColor(.black)
                                                    )
                                                
                                                Text(participant.user?.name ?? participant.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.black)
                                                
                                                Spacer()
                                                
                                                Text("(คุณ)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            // Other participants - tappable for private chat
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
                                                                .foregroundColor(.black)
                                                        )
                                                    
                                                    Text(participant.user?.name ?? participant.name)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.black)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 100)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        if viewModel.isCreator || viewModel.isAdmin {
                            Button(action: { showDeleteAlert = true }) {
                                Text("ลบทริป")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black)
                                    .cornerRadius(12)
                            }
                        } else if viewModel.hasJoined {
                            Button(action: {
                                Task { await viewModel.leaveTrip() }
                            }) {
                                Text(viewModel.isLoading ? "กำลังออก..." : "ออกจากทริป")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                        } else if !trip.isFull {
                            Button(action: {
                                viewModel.showJoinSheet = true
                            }) {
                                Text("เข้าร่วมทริป")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black)
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
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .hideTabBar(true)
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





#Preview {
    TripDetailView(tripId: "1")
}

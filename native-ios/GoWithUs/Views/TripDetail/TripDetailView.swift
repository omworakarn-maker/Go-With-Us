import SwiftUI

struct TripDetailView: View {
    let tripId: String
    @StateObject private var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    
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
                        // Image Header
                        ZStack(alignment: .topLeading) {
                            if let imageUrl = trip.imageUrl, !imageUrl.isEmpty {
                                CustomAsyncImage(url: imageUrl)
                                    .frame(height: 280)
                                    .clipped()
                            } else {
                                Image("sosuke")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .clipped()
                            }
                            
                            // Back Button
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
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
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
                        }
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
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
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
}

// MARK: - Join Trip Sheet
struct JoinTripSheet: View {
    @ObservedObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var interests = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("เข้าร่วมทริป")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.black)
                    
                    Text("บอกเราเกี่ยวกับความสนใจของคุณ")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ความสนใจ (ไม่บังคับ)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    TextField("เช่น ถ่ายรูป, ปีนเขา, ดำน้ำ", text: $interests)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                
                Button(action: {
                    Task {
                        let interestArray = interests.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        await viewModel.joinTrip(interests: interestArray)
                        dismiss()
                    }
                }) {
                    Text(viewModel.isLoading ? "กำลังเข้าร่วม..." : "ยืนยัน")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ปิด") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

#Preview {
    TripDetailView(tripId: "1")
}

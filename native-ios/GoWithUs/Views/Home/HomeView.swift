import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TripListViewModel()
    @State private var showNotifications = false
    @State private var unreadCount = 0

    
    @State private var showSideMenu = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                // Main Content
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Title & Menu
                        HStack {
                            Button(action: {
                                withAnimation {
                                    showSideMenu.toggle()
                                }
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            Text("GoWithUs")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                                .tracking(-1)
                            
                            Spacer()
                            
                            // Notification Bell
                            Button(action: {
                                showNotifications = true
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    if unreadCount > 0 {
                                        Text("\(unreadCount)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // New Filter Bar
                        FilterBar(
                            selectedProvince: $viewModel.selectedProvince,
                            selectedDate: $viewModel.selectedDate,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        
                        // Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("ค้นหาทริป...", text: $viewModel.searchText)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // New Segmented Control (Tabs)
                        SegmentedControl(
                            options: ["แนะนำ", "มาใหม่", "มาแรง"],
                            selected: $viewModel.activeTab
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Trip List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.black)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            
                            Text("เกิดข้อผิดพลาด")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                Task { await viewModel.loadTrips() }
                            }) {
                                Text("ลองใหม่")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.black)
                                    .cornerRadius(20)
                            }
                        }
                        Spacer()
                    } else if viewModel.trips.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("?")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.gray.opacity(0.3))
                                )
                            
                            Text("ไม่พบทริป")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("ลองค้นหาด้วยคำอื่นหรือสร้างทริปใหม่")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.trips) { trip in
                                    NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                        TripCardView(trip: trip)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await viewModel.loadTrips()
                        }
                    }
                }
                // Side Menu Overlay
                SideMenuView(isShowing: $showSideMenu)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
        }
        .task {
            await viewModel.loadTrips()
            await loadUnreadCount()
        }
    }
    
    private func loadUnreadCount() async {
        do {
            unreadCount = try await NotificationService.shared.getUnreadCount()
        } catch {
            print("Error loading unread count: \(error)")
        }
    }
}



#Preview {
    HomeView()
}

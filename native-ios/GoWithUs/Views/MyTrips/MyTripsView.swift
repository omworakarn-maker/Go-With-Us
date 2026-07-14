import SwiftUI

struct MyTripsView: View {
    @StateObject private var viewModel = MyTripsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showSideMenu: Bool
    
    @State private var selectedTab: Int
    
    init(showSideMenu: Binding<Bool>, initialTab: Int = 0) {
        self._showSideMenu = showSideMenu
        self._selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            withAnimation {
                                showSideMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.adaptiveText)
                        }
                        
                        Spacer()
                        
                        Text(SettingsManager.shared.localizedString(for: "my_trips"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.adaptiveText)
                        
                        Spacer()
                        
                        // Balance space
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.clear)
                    }
                    .padding()
                    .background(Color.adaptiveBackground)
                    
                    Picker("หมวดหมู่", selection: $selectedTab) {
                        Text("สร้างเอง").tag(0)
                        Text("เข้าร่วมแล้ว").tag(1)
                        Text("รายการโปรด").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    Group {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if selectedTrips.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: selectedTab == 2 ? "heart.fill" : "airplane.departure")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text(emptyStateMessage)
                                    .font(.headline)
                                
                                if selectedTab == 0 {
                                    NavigationLink(destination: CreateTripView()) {
                                         Text(SettingsManager.shared.localizedString(for: "create"))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.black)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(selectedTrips) { trip in
                                        NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                            TripCardView(trip: trip)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                            .refreshable {
                                if let userId = authViewModel.currentUser?.id {
                                    await viewModel.fetchMyTrips(userId: userId)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchMyTrips(userId: userId)
            }
        }
    }
    
    private var selectedTrips: [Trip] {
        switch selectedTab {
        case 0: return viewModel.createdTrips
        case 1: return viewModel.joinedTrips
        case 2: return viewModel.interestedTrips
        default: return []
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedTab {
        case 0: return SettingsManager.shared.currentLanguage == .thai ? "คุณยังไม่มีทริปที่สร้างไว้" : "You haven't created any trips yet"
        case 1: return SettingsManager.shared.currentLanguage == .thai ? "คุณยังไม่ได้เข้าร่วมทริปใดเลย" : "You haven't joined any trips yet"
        case 2: return SettingsManager.shared.currentLanguage == .thai ? "ยังไม่มีทริปในรายการโปรด" : "No favorite trips yet"
        default: return ""
        }
    }
}

class MyTripsViewModel: ObservableObject {
    @Published var createdTrips: [Trip] = []
    @Published var joinedTrips: [Trip] = []
    @Published var interestedTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMyTrips(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            async let createdFetch = TripService.shared.getAllTrips(creatorId: userId, limit: 100)
            async let participatedFetch = TripService.shared.getAllTrips(participantId: userId, limit: 100)
            
            let createdResult = try await createdFetch
            let participatedResult = try await participatedFetch
            
            let created = createdResult.trips
            let participated = participatedResult.trips
            
            let joined = participated.filter { $0.participants?.contains(where: { $0.userId == userId && $0.status == "going" }) == true }
            let interested = participated.filter { $0.participants?.contains(where: { $0.userId == userId && $0.status == "interested" }) == true }
            
            await MainActor.run {
                self.createdTrips = created
                self.joinedTrips = joined
                self.interestedTrips = interested
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = SettingsManager.shared.currentLanguage == .thai ? "โหลดข้อมูลล้มเหลว" : "Failed to load data"
                self.isLoading = false
                print("Error loading my trips: \(error)")
            }
        }
    }
}

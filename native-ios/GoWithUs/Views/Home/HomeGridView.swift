import SwiftUI

struct HomeGridView: View {
    @StateObject private var viewModel = TripListViewModel()
    @ObservedObject private var notificationPoller = NotificationPoller.shared
    @State private var showNotifications = false
    @Binding var showSideMenu: Bool
    @Binding var currentScreen: AppScreen
    
    // Grid Setup: 2 columns with less spacing to make cards larger
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                // Main Content
                VStack(spacing: 0) {
                    // Header (Same as HomeView)
                    VStack(spacing: 16) {
                        // Title & Menu
                        ZStack {
                            // Center Title
                            Text("GoWithUs")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            HStack {
                                // Left actions
                                Button(action: {
                                    HapticManager.shared.impact(style: .light)
                                    withAnimation { showSideMenu.toggle() }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                }
                                
                                Spacer()
                                
                                // Right actions
                                HStack(spacing: 8) {
                                    // Layout Switcher (Back to List)
                                    Button(action: {
                                        SettingsManager.shared.triggerSelection()
                                        SettingsManager.shared.homeLayoutPreference = .home
                                        withAnimation { currentScreen = .home }
                                    }) {
                                         Image(systemName: "list.bullet")
                                             .font(.system(size: 18))
                                             .foregroundColor(.adaptiveText)
                                             .padding(8)
                                             .background(Color.gray.opacity(0.1))
                                             .clipShape(Circle())
                                    }
                                    
                                    // Notification Bell
                                    Button(action: { showNotifications = true }) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(.adaptiveText)
                                            if notificationPoller.unreadCount > 0 {
                                                Text("\(notificationPoller.unreadCount)")
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
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Filter Bar
                        FilterBar(
                            selectedProvince: $viewModel.selectedProvince,
                            selectedDate: $viewModel.selectedDate,
                            selectedEndDate: $viewModel.selectedEndDate,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        
                        // Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField(SettingsManager.shared.localizedString(for: "search_placeholder"), text: $viewModel.searchText)
                                .foregroundColor(.adaptiveText)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Tabs
                        SegmentedControl(
                            options: [
                                SettingsManager.shared.localizedString(for: "tab_recommended"),
                                SettingsManager.shared.localizedString(for: "tab_new"),
                                SettingsManager.shared.localizedString(for: "tab_popular")
                            ],
                            selected: $viewModel.activeTab
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Grid Content
                    ScrollView {
                        if viewModel.isLoading && viewModel.trips.isEmpty {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.adaptiveText)
                                Text(SettingsManager.shared.localizedString(for: "loading_trips"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.adaptiveText)
                                    .padding(.top, 8)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.trips.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("?")
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.gray.opacity(0.3))
                                    )
                                Text(SettingsManager.shared.localizedString(for: "no_trips_found"))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.trips) { trip in
                                    NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                        TripGridCardView(trip: trip)
                                            .staggeredAppear(index: viewModel.trips.firstIndex(where: { $0.id == trip.id }) ?? 0)
                                    }
                                    .buttonStyle(ScaledButtonStyle())
                                }
                            }
                            .padding()
                            .padding(.bottom, 90)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) { NotificationView() }
            .task { 
                if viewModel.trips.isEmpty {
                    await viewModel.loadTrips() 
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TripCreated"))) { _ in
                Task {
                    await viewModel.loadTrips()
                }
            }
        }
    }
}

#Preview {
    HomeGridView(showSideMenu: .constant(false), currentScreen: .constant(.homeGrid))
}

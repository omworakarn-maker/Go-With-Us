import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TripListViewModel()
    @ObservedObject private var notificationPoller = NotificationPoller.shared
    @State private var showNotifications = false
    @FocusState private var isSearchFocused: Bool
    
    @Binding var showSideMenu: Bool
    @Binding var currentScreen: AppScreen
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                // Main Content
                VStack(spacing: 0) {
                    // Header
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
                                    withAnimation {
                                        showSideMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                }
                                
                                Spacer()
                                
                                // Right actions
                                HStack(spacing: 8) {
                                    // Layout Switcher
                                    Button(action: {
                                        SettingsManager.shared.triggerSelection()
                                        SettingsManager.shared.homeLayoutPreference = .homeGrid
                                        withAnimation {
                                            currentScreen = .homeGrid
                                        }
                                    }) {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 18))
                                            .foregroundColor(.adaptiveText)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    
                                    // Notification Bell
                                    Button(action: {
                                        showNotifications = true
                                    }) {
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
                        
                        // New Filter Bar
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
                                .accentColor(.black)
                                .focused($isSearchFocused)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                    isSearchFocused = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
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
                    
                    // Trip List Area
                    if viewModel.isLoading && viewModel.trips.isEmpty {
                        loadingView()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            
                            Text("เกิดข้อผิดพลาด")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
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
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.trips.isEmpty && !viewModel.isLoading {
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
                                .foregroundColor(.adaptiveText)
                            
                            Text(SettingsManager.shared.localizedString(for: "try_another_search"))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.trips) { trip in
                                    NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                        TripCardView(trip: trip)
                                            .staggeredAppear(index: viewModel.trips.firstIndex(where: { $0.id == trip.id }) ?? 0)
                                    }
                                    .buttonStyle(ScaledButtonStyle())
                                }
                            }
                            .padding()
                            .padding(.bottom, 90)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
            .navigationBarHidden(true)
            .hideTabBar(isSearchFocused || !viewModel.searchText.isEmpty)
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
            .task {
                await viewModel.loadTrips()
            }
        }
    }
}

// Adjust loading state with a bit of offset from center
extension HomeView {
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 150) // Push down as requested
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appPrimary)
            Text(SettingsManager.shared.localizedString(for: "loading_trips"))
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView(showSideMenu: .constant(false), currentScreen: .constant(.home))
}

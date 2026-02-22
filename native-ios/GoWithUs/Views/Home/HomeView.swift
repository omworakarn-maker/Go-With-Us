import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TripListViewModel()
    @ObservedObject private var notificationPoller = NotificationPoller.shared
    @State private var showNotifications = false
    
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
                            
                            TextField(LanguageManager.shared.localizedString(for: "search_placeholder"), text: $viewModel.searchText)
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
                        
                        // New Segmented Control (Tabs)
                        SegmentedControl(
                            options: [
                                LanguageManager.shared.localizedString(for: "tab_recommended"),
                                LanguageManager.shared.localizedString(for: "tab_new"),
                                LanguageManager.shared.localizedString(for: "tab_popular")
                            ],
                            selected: $viewModel.activeTab
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Trip List
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.appPrimary)
                            Text(LanguageManager.shared.localizedString(for: "loading_trips"))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
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
                            
                            Text(LanguageManager.shared.localizedString(for: "no_trips_found"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            Text(LanguageManager.shared.localizedString(for: "try_another_search"))
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
                            .padding(.bottom, 90)
                        }
                        .refreshable {
                            await viewModel.loadTrips()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
            .task {
                await viewModel.loadTrips()
            }
        }
    }
}

#Preview {
    HomeView(showSideMenu: .constant(false), currentScreen: .constant(.home))
}

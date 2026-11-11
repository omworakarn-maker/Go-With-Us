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
                            // Center Title & Logo
                            HStack(spacing: 8) {
                                AppBrandLogo(size: 36, animates: true)
                                Text("GoWithUs")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(.adaptiveText)
                            }

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
                                            .appGlass(in: Circle(), interactive: true)
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
                        HomeSearchFilterBar(
                            searchText: $viewModel.searchText,
                            focus: $isSearchFocused,
                            selectedProvince: $viewModel.selectedProvince,
                            selectedDate: $viewModel.selectedDate,
                            selectedEndDate: $viewModel.selectedEndDate,
                            selectedCategory: $viewModel.selectedCategory
                        )

                        // New Segmented Control (Tabs)
                        SegmentedControl(
                            options: [
                                SettingsManager.shared.localizedString(for: "tab_recommended"),
                                SettingsManager.shared.localizedString(for: "tab_new"),
                                SettingsManager.shared.localizedString(for: "tab_popular")
                            ],
                            values: ["แนะนำ", "มาใหม่", "ยอดนิยม"],
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

                            Text(SettingsManager.shared.text(thai: "เกิดข้อผิดพลาด", english: "Something went wrong"))
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
                                Text(SettingsManager.shared.text(thai: "ลองใหม่", english: "Try Again"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appPrimary)
                                    .cornerRadius(20)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -50)
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
                        .offset(y: -50)
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

                        }
                        .safeAreaPadding(.bottom, 16)
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
            .toolbar(.hidden, for: .navigationBar)
            .hideTabBar(isSearchFocused || !viewModel.searchText.isEmpty)
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
            .task {
                if viewModel.trips.isEmpty {
                    await viewModel.loadTrips()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TripCreated"))) { note in
                if let trip = note.object as? Trip { viewModel.includeCreatedTrip(trip) }
                else { Task { await viewModel.refresh() } }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TripDeleted"))) { note in
                if let id = note.object as? String { viewModel.removeTrip(id: id) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppDataRefreshRequested"))) { _ in
                Task { await viewModel.refresh() }
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
            ProgressView()
                .tint(.appPrimary)
            Text(SettingsManager.shared.localizedString(for: "loading_trips"))
                .font(.system(size: 14))
                .foregroundColor(.adaptiveText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -50)
        .transition(.identity)
        .animation(nil, value: UUID())
    }
}


#Preview {
    HomeView(showSideMenu: .constant(false), currentScreen: .constant(.home))
}

// One glass surface changes size; the search field keeps the existing query binding.
struct ExpandingTripSearch: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var expanded: Bool

    var body: some View {
        HStack(spacing: expanded ? 10 : 0) {
            Button {
                SettingsManager.shared.triggerSelection()
                if expanded { focus.wrappedValue = true }
                else { expanded = true }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.adaptiveText)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(SettingsManager.shared.text(thai: "ค้นหาทริป", english: "Search trips"))

            if expanded {
                TextField(SettingsManager.shared.localizedString(for: "search_placeholder"), text: $text)
                    .foregroundStyle(Color.adaptiveText)
                    .tint(.appAccent)
                    .focused(focus)
                    .submitLabel(.search)
                    .onSubmit { focus.wrappedValue = false }
                    .transition(.opacity)
                    .task {
                        do { try await Task.sleep(nanoseconds: 180_000_000) }
                        catch { return }
                        guard !Task.isCancelled else { return }
                        focus.wrappedValue = true
                    }

                Button {
                    focus.wrappedValue = false
                    text = ""
                    expanded = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 44, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(SettingsManager.shared.text(thai: "ปิดการค้นหา", english: "Close search"))
                .transition(.opacity)
            }
        }
        .frame(width: expanded ? nil : 48, height: 48)
        .frame(maxWidth: expanded ? .infinity : nil)
        .clipShape(Capsule())
        .appGlass(in: Capsule(), interactive: true)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.36, dampingFraction: 0.88), value: expanded)
    }
}

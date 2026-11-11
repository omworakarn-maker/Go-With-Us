import Foundation
import Combine

// MARK: - Trip List ViewModel
@MainActor
class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    // Filters
    @Published var activeTab: String {
        didSet {
            UserDefaults.standard.set(activeTab, forKey: Self.activeTabStorageKey)
            Task { await switchTabWithoutClearing() }
        }
    }
    @Published var selectedProvince: String? {
        didSet { Task { await loadTrips(showLoading: false, force: true) } }
    }
    @Published var selectedDate: Date? {
        didSet { Task { await loadTrips(showLoading: false, force: true) } }
    }
    @Published var selectedEndDate: Date? {
        didSet { Task { await loadTrips(showLoading: false, force: true) } }
    }
    @Published var selectedCategory: TripCategory? {
        didSet { Task { await loadTrips(showLoading: false, force: true) } }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private static var lastLoadedByQuery: [String: Date] = [:]
    private static var cachedTripsByQuery: [String: [Trip]] = [:]
    private static let activeTabStorageKey = "GoWithUs.home.activeTripTab"

    private var queryKey: String {
        [activeTab, selectedProvince ?? "*", selectedDate.map(String.init(describing:)) ?? "*",
         selectedEndDate.map(String.init(describing:)) ?? "*", selectedCategory?.rawValue ?? "*"]
            .joined(separator: "|")
    }
    
    static func invalidateCache() {
        lastLoadedByQuery = [:]
        cachedTripsByQuery = [:]
    }
    
    init() {
        let savedTab = UserDefaults.standard.string(forKey: Self.activeTabStorageKey)
        activeTab = savedTab.flatMap {
            ["แนะนำ", "มาใหม่", "ยอดนิยม", "มาแรง"].contains($0) ? $0 : nil
        } ?? "แนะนำ"
        setupSearch()
    }
    
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadTrips()
                }
            }
            .store(in: &cancellables)
    }
    
    private var currentLoadTask: Task<Void, Never>?

    func loadTrips(showLoading: Bool = true, force: Bool = false) async {
        let key = queryKey
        if !force, let lastLoaded = Self.lastLoadedByQuery[key],
           Date().timeIntervalSince(lastLoaded) < 600,
           let cached = Self.cachedTripsByQuery[key], !cached.isEmpty {
            var filtered = cached
            
            // Local search filtering on cached trips
            if !searchText.isEmpty {
                filtered = filtered.filter { trip in
                    trip.title.localizedCaseInsensitiveContains(searchText) ||
                    trip.destination.localizedCaseInsensitiveContains(searchText) ||
                    (trip.description?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
            
            self.trips = filtered
            return
        }
        
        currentLoadTask?.cancel()
        
        let task = Task {
            if showLoading {
                isLoading = true
                errorMessage = nil
                trips = [] 
            }
            
            // Fix: Return early if running in SwiftUI Previews to prevent network timeout
            if AppRuntime.isRunningForPreview {
                self.isLoading = false
                return
            }
            
            do {
                // Map tab to API type
                let type: String
                switch activeTab {
                case "ยอดนิยม", "มาแรง": type = "popular"
                case "แนะนำ": type = "recommended"
                case "มาใหม่": type = "new"
                default: type = "recommended"
                }
                
                // Fetch with filters
                let fetchedTrips = try await TripService.shared.getAllTrips(
                    type: type,
                    destination: selectedProvince == "ทุกจังหวัด" ? nil : selectedProvince,
                    startDate: selectedDate,
                    category: selectedCategory
                )
                
                if Task.isCancelled { return }
                
                var filtered = fetchedTrips
                
                // Local Filtering for End Date
                if let userSelectionEnd = selectedEndDate {
                     filtered = filtered.filter { $0.startDate <= userSelectionEnd }
                }
                
                // Cache before search filtering
                Self.cachedTripsByQuery[key] = filtered
                Self.lastLoadedByQuery[key] = Date()
                
                // Local search filtering
                if !searchText.isEmpty {
                    filtered = filtered.filter { trip in
                        trip.title.localizedCaseInsensitiveContains(searchText) ||
                        trip.destination.localizedCaseInsensitiveContains(searchText) ||
                        (trip.description?.localizedCaseInsensitiveContains(searchText) ?? false)
                    }
                }
                
                self.trips = filtered
                
            } catch let error as URLError where error.code == .cancelled {
                return 
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        currentLoadTask = task
        await task.value
    }
    
    func refresh() async {
        await loadTrips(showLoading: false, force: true)
    }

    private func switchTabWithoutClearing() async {
        currentLoadTask?.cancel()
        let key = queryKey
        if let cached = Self.cachedTripsByQuery[key], !cached.isEmpty {
            trips = cached
            return
        }
        await loadTrips(showLoading: false, force: true)
    }

    func includeCreatedTrip(_ trip: Trip) {
        for key in Array(Self.cachedTripsByQuery.keys) {
            Self.cachedTripsByQuery[key]?.removeAll { $0.id == trip.id }
            Self.cachedTripsByQuery[key]?.insert(trip, at: 0)
        }
        trips.removeAll { $0.id == trip.id }
        trips.insert(trip, at: 0)
    }

    func removeTrip(id: String) {
        for key in Array(Self.cachedTripsByQuery.keys) {
            Self.cachedTripsByQuery[key]?.removeAll { $0.id == id }
        }
        trips.removeAll { $0.id == id }
    }
}

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
    @Published var activeTab: String = "แนะนำ" {
        didSet { Task { await loadTrips() } }
    }
    @Published var selectedProvince: String? {
        didSet { Task { await loadTrips() } }
    }
    @Published var selectedDate: Date? {
        didSet { Task { await loadTrips() } }
    }
    @Published var selectedCategory: TripCategory? {
        didSet { Task { await loadTrips() } }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
    
    func loadTrips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Map tab to API type
            let type: String
            switch activeTab {
            case "มาแรง": type = "popular"
            case "แนะนำ": type = "recommended"
            case "มาใหม่": type = "new"
            default: type = "recommended"
            }
            
            // Fetch with filters
            trips = try await TripService.shared.getAllTrips(
                type: type,
                destination: selectedProvince == "ทุกจังหวัด" ? nil : selectedProvince,
                startDate: selectedDate,
                category: selectedCategory
            )
            
            // Local search filtering only
            if !searchText.isEmpty {
                trips = trips.filter { trip in
                    trip.title.localizedCaseInsensitiveContains(searchText) ||
                    trip.destination.localizedCaseInsensitiveContains(searchText) ||
                    (trip.description?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadTrips()
    }
}

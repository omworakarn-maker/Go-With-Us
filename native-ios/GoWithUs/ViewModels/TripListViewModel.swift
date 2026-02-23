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
    @Published var selectedEndDate: Date? {
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
    
    private var currentLoadTask: Task<Void, Never>?

    func loadTrips(showLoading: Bool = true) async {
        currentLoadTask?.cancel()
        
        let task = Task {
            if showLoading {
                isLoading = true
                errorMessage = nil
                trips = [] 
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
        await loadTrips(showLoading: false)
    }
}

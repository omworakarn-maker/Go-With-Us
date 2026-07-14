import Foundation
import Combine

// MARK: - Trip List ViewModel
@MainActor
class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    // Pagination
    private var currentPage = 1
    private var hasMorePages = true
    private let limit = 20
    
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
            }
            
            currentPage = 1
            hasMorePages = true
            
            do {
                let type = getTabType()
                
                let fetchedResult = try await TripService.shared.getAllTrips(
                    type: type,
                    destination: selectedProvince == "ทุกจังหวัด" ? nil : selectedProvince,
                    startDate: selectedDate,
                    category: selectedCategory,
                    page: currentPage,
                    limit: limit
                )
                
                if Task.isCancelled { return }
                
                self.hasMorePages = fetchedResult.hasMore
                self.trips = filterTrips(fetchedResult.trips)
                
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
    
    func loadMoreTrips() async {
        guard !isLoadingMore, hasMorePages, !isLoading else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let type = getTabType()
            
            let fetchedResult = try await TripService.shared.getAllTrips(
                type: type,
                destination: selectedProvince == "ทุกจังหวัด" ? nil : selectedProvince,
                startDate: selectedDate,
                category: selectedCategory,
                page: currentPage,
                limit: limit
            )
            
            self.hasMorePages = fetchedResult.hasMore
            
            // Append new filtered trips
            let newTrips = filterTrips(fetchedResult.trips)
            
            // Filter out duplicates
            let existingIds = Set(self.trips.map { $0.id })
            let uniqueNewTrips = newTrips.filter { !existingIds.contains($0.id) }
            
            self.trips.append(contentsOf: uniqueNewTrips)
            
        } catch {
            print("Error loading more trips: \(error)")
            // If failed, revert page count
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
    
    private func getTabType() -> String {
        switch activeTab {
        case "ยอดนิยม", "มาแรง": return "popular"
        case "แนะนำ": return "recommended"
        case "มาใหม่": return "new"
        default: return "recommended"
        }
    }
    
    private func filterTrips(_ fetchedTrips: [Trip]) -> [Trip] {
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
        return filtered
    }
    
    func refresh() async {
        await loadTrips(showLoading: false)
    }
}

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
    
    func loadTrips() async {
        isLoading = true
        errorMessage = nil
        trips = [] // Clear list to show loading state
        
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
            trips = try await TripService.shared.getAllTrips(
                type: type,
                destination: selectedProvince == "ทุกจังหวัด" ? nil : selectedProvince,
                startDate: selectedDate, // Filter API by start date (>=)
                category: selectedCategory
            )
            
            // Local Filtering for End Date (Range)
            if let userSelectionEnd = selectedEndDate {
                 // Logic: selectedDate is Start. selectedEndDate is End.
                 // API returns trips starting >= selectedDate.
                 // We want trips starting <= selectedEndDate also?
                 // Or trips occurring within the range?
                 // Usually "Trip Date" filter means the trip *Starts* in this range.
                 trips = trips.filter { trip in
                     trip.startDate <= userSelectionEnd
                 }
            } else if let end = selectedEndDate {
                // If only end date is set? (Shouldn't happen with our UI logic)
                 trips = trips.filter { trip in
                     trip.startDate <= end
                 }
            }
            
            // Local search filtering only
            if !searchText.isEmpty {
                trips = trips.filter { trip in
                    trip.title.localizedCaseInsensitiveContains(searchText) ||
                    trip.destination.localizedCaseInsensitiveContains(searchText) ||
                    (trip.description?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
            
        } catch let error as URLError where error.code == .cancelled {
            return // Ignore cancellation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadTrips()
    }
}

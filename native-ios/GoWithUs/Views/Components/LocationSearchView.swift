import SwiftUI
import MapKit

class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private var completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        // Focus on points of interest and addresses
        completer.resultTypes = [.pointOfInterest, .address]
    }
    
    func search(query: String) {
        if query.isEmpty {
            completions = []
        } else {
            completer.queryFragment = query
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error suggesting locations: \(error.localizedDescription)")
    }
}

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()
    @State private var searchText = ""
    
    var onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("พิมพ์ชื่อสถานที่ เช่น ร้านอาหาร, คาเฟ่...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            viewModel.search(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.search(query: "")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Always allow using the exact typed text
                if !searchText.isEmpty {
                    Button(action: {
                        onSelect(searchText)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.appPrimary)
                            Text("ใช้ \"\(searchText)\" เป็นสถานที่")
                                .foregroundColor(.appPrimary)
                            Spacer()
                        }
                        .padding()
                    }
                }
                
                List(viewModel.completions, id: \.title) { completion in
                    Button(action: {
                        // Extracting the best title
                        let finalLocation = completion.title
                        onSelect(finalLocation)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("ค้นหาสถานที่")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    private static let cache = NSCache<NSString, UIImage>()
    
    func load(from urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty else {
            return
        }
        
        // Check for Base64 string
        if urlString.hasPrefix("data:image") {
            if let base64String = urlString.components(separatedBy: ",").last,
               let data = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: data) {
                self.image = uiImage
                return
            }
        }
        
        // Check cache
        if let cachedImage = Self.cache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                if let loadedImage = loadedImage {
                    Self.cache.setObject(loadedImage, forKey: urlString as NSString)
                    self?.image = loadedImage
                }
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

import SwiftUI
import Combine

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    private var requestID = UUID()
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 80
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    static func clearCache() { cache.removeAllObjects() }

    private func accept(_ loadedImage: UIImage, key: String, request: UUID) {
        guard requestID == request else { return }
        let cost = loadedImage.cgImage.map { $0.bytesPerRow * $0.height }
            ?? Int(loadedImage.size.width * loadedImage.scale * loadedImage.size.height * loadedImage.scale * 4)
        Self.cache.setObject(loadedImage, forKey: key as NSString, cost: cost)
        image = loadedImage
    }

    func load(from urlString: String?) {
        cancel()
        image = nil
        guard !AppRuntime.isRunningForPreview,
              let urlString, !urlString.isEmpty else { return }
        let request = requestID
        if let cachedImage = Self.cache.object(forKey: urlString as NSString) {
            image = cachedImage
            return
        }

        let payload = urlString.hasPrefix("data:image")
            ? (urlString.components(separatedBy: ",").last ?? urlString) : urlString
        if !payload.hasPrefix("http") && payload.count > 100 {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let cleaned = payload.replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
                      let decoded = UIImage(data: data) else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.accept(decoded, key: urlString, request: request)
                }
            }
            return
        }
        guard let url = URL(string: urlString) else { return }
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                guard let loadedImage else { return }
                self?.accept(loadedImage, key: urlString, request: request)
            }
    }

    func cancel() {
        requestID = UUID()
        cancellable?.cancel()
        cancellable = nil
    }
}

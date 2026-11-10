import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: String?
    let contentMode: ContentMode
    let loadDelay: Double // Delay before loading (useful to let animations complete first)
    
    init(url: String?, contentMode: ContentMode = .fill, loadDelay: Double = 0) {
        self.url = url
        self.contentMode = contentMode
        self.loadDelay = loadDelay
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .animation(.easeIn(duration: 0.2), value: loader.image != nil)
        .task(id: url) {
            if loadDelay > 0 {
                do { try await Task.sleep(for: .seconds(loadDelay)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            loader.load(from: url)
        }
        .onDisappear { loader.cancel() }
    }
}

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
        .onAppear {
            if loadDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + loadDelay) {
                    loader.load(from: url)
                }
            } else {
                loader.load(from: url)
            }
        }
        .onChange(of: url) { _, newUrl in
            loader.load(from: newUrl)
        }
    }
}

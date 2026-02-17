import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: String?
    let placeholder: Image
    let contentMode: ContentMode
    
    init(url: String?, placeholder: Image = Image(systemName: "photo"), contentMode: ContentMode = .fill) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .onAppear {
            loader.load(from: url)
        }
        .onChange(of: url) { _, newUrl in
            loader.load(from: newUrl)
        }
    }
}

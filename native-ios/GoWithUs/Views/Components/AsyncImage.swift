import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: String?
    let placeholder: Image
    
    init(url: String?, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder
                    .resizable()
            }
        }
        .onAppear {
            loader.load(from: url)
        }
        .onChange(of: url) { newUrl in
            loader.load(from: newUrl)
        }
    }
}

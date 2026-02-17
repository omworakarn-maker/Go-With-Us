import SwiftUI
import UIKit

struct ImageCropperView: View {
    @Binding var image: UIImage?
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void
    
    // Config
    let aspectRatio: CGFloat = 16.0 / 9.0
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width > 0 ? geometry.size.width : UIScreen.main.bounds.width
            let h = geometry.size.height > 0 ? geometry.size.height : UIScreen.main.bounds.height
            
            let cropWidth = max(w - 40, 100)
            let cropHeight = cropWidth / aspectRatio
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = image {
                    // Image layer
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    },
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale *= delta
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                        )
                    
                    // Overlay Mask
                    VStack {
                        Spacer()
                        ZStack {
                            // Darkened outer area
                            Color.black.opacity(0.6)
                                .mask(
                                    ZStack {
                                        Rectangle()
                                        Rectangle()
                                            .frame(width: cropWidth, height: cropHeight)
                                            .blendMode(.destinationOut)
                                    }
                                )
                            
                            // Border
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: cropWidth, height: cropHeight)
                        }
                        .compositingGroup()
                        .frame(height: cropHeight)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                } else {
                    Text("ไม่พบรูปภาพ")
                        .foregroundColor(.white)
                }
                
                // Toolbar (since we removed NavigationView)
                VStack {
                    HStack {
                        Button("ยกเลิก") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        Text("ปรับแต่งรูปภาพ")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("เสร็จสิ้น") {
                            Task { @MainActor in
                                if let cropped = cropImage(geometry: geometry) {
                                    onCrop(cropped)
                                } else if let img = image {
                                    onCrop(img)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding()
                    }
                    .background(Color.black.opacity(0.5))
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
   
    // Improved Crop Logic
    @MainActor
    func cropImage(geometry: GeometryProxy) -> UIImage? {
        guard let inputImage = image else { return nil }
        
        let cropWidth = geometry.size.width - 40
        let cropHeight = cropWidth / aspectRatio
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropWidth, height: cropHeight))
        
        let croppedImage = renderer.image { context in
            // Translate to center of crop box
            context.cgContext.translateBy(x: cropWidth / 2, y: cropHeight / 2)
            
            // Calculate initial fit size
            let imageSize = inputImage.size
            let containerSize = geometry.size
            let hRatio = containerSize.width / imageSize.width
            let vRatio = containerSize.height / imageSize.height
            let initialScale = min(hRatio, vRatio)
            
            let drawWidth = imageSize.width * initialScale * scale
            let drawHeight = imageSize.height * initialScale * scale
            
            // Draw image with current offset and scale
            let drawRect = CGRect(
                x: -drawWidth / 2 + offset.width,
                y: -drawHeight / 2 + offset.height,
                width: drawWidth,
                height: drawHeight
            )
            
            // Clean orientation-fixed image
            let normalizedImage = inputImage.fixOrientation()
            normalizedImage.draw(in: drawRect)
        }
        
        // Ensure the final image has correct scale and orientation
        if let cgImage = croppedImage.cgImage {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        }
        
        return croppedImage
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

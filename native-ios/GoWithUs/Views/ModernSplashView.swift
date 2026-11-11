import SwiftUI

// Compatibility entry point for the same shared splash artwork.
struct ModernSplashView: View {
    var onFinished: () -> Void = {}
    var body: some View { SplashView(onFinished: onFinished) }
}

import SwiftUI

struct SplashView: View {
    private struct CarPose {
        var travel: CGFloat = 0
        var lift: CGFloat = 0
        var pitch: Double = 0
        var heightScale: CGFloat = 1
    }

    private struct SmokePose {
        var scale: CGFloat = 1
        var x: CGFloat = 0
        var y: CGFloat = 0
        var opacity: Double = 1

        static let waiting = SmokePose(scale: 0.58, x: -0.095, opacity: 0)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var carPose = CarPose()
    @State private var carHasFaded = false
    @State private var smoke = SmokePose.waiting
    @State private var eyeIsClosed = false

    var onFinished: () -> Void = {}

    var body: some View {
        GeometryReader { geometry in
            let artworkWidth = min(geometry.size.width * 0.86, 440)
            let artworkHeight = artworkWidth * 561 / 778
            let exitDistance = (geometry.size.width + artworkWidth) / 2

            ZStack {
                smokeArtwork(smoke, width: artworkWidth, height: artworkHeight)

                artwork("SplashCar", width: artworkWidth, height: artworkHeight)
                    .overlay(alignment: .topLeading) {
                        let scale = artworkWidth / 778
                        ZStack(alignment: .topLeading) {
                            blinkingEye("SplashLeftEye", in: CGRect(x: 213, y: 180, width: 36, height: 15), scale: scale)
                            blinkingEye("SplashEye", in: CGRect(x: 259, y: 176, width: 51, height: 19), scale: scale)
                        }
                    }
                    .scaleEffect(x: 1, y: carPose.heightScale, anchor: UnitPoint(x: 0.5, y: 0.93))
                    .rotationEffect(.degrees(carPose.pitch), anchor: UnitPoint(x: 0.5, y: 0.93))
                    .offset(x: carPose.travel * exitDistance, y: carPose.lift * artworkWidth)
                    .opacity(carHasFaded ? 0 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            await play()
        }
    }

    private func artwork(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        Image(name)
            .resizable()
            .frame(width: width, height: height)
    }

    private func smokeArtwork(_ pose: SmokePose, width: CGFloat, height: CGFloat) -> some View {
        artwork("SplashSmoke", width: width, height: height)
            .scaleEffect(pose.scale, anchor: UnitPoint(x: 0.95, y: 0.75))
            .offset(x: pose.x * width, y: pose.y * width)
            .opacity(pose.opacity)
    }

    private func blinkingEye(_ name: String, in bounds: CGRect, scale: CGFloat) -> some View {
        let width = bounds.width * scale
        let height = bounds.height * scale

        return ZStack {
            Color(red: 1, green: 233.0 / 255, blue: 178.0 / 255)
            artwork(name, width: width, height: height)
                .scaleEffect(x: 1, y: eyeIsClosed ? 0.30 : 1)
                .offset(y: eyeIsClosed ? 2 * scale : 0)
        }
        .frame(width: width, height: height)
        .offset(x: bounds.minX * scale, y: bounds.minY * scale)
    }

    @MainActor
    private func play() async {
        carPose = CarPose()
        carHasFaded = false
        smoke = .waiting
        eyeIsClosed = false

        do {
            try await Task.sleep(nanoseconds: 240_000_000)
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.25)) {
                    carHasFaded = true
                }
                try await Task.sleep(nanoseconds: 250_000_000)
            } else {
                withAnimation(.easeInOut(duration: 0.22)) {
                    carPose = CarPose(travel: 0.025, lift: 0.008, pitch: -1.7, heightScale: 0.96)
                }
                try await Task.sleep(nanoseconds: 5_000_000)
                withAnimation(.easeIn(duration: 0.055)) {
                    eyeIsClosed = true
                }
                try await Task.sleep(nanoseconds: 115_000_000)
                withAnimation(.easeOut(duration: 0.085)) {
                    eyeIsClosed = false
                }
                try await Task.sleep(nanoseconds: 100_000_000)

                withAnimation(.timingCurve(0.45, 0.10, 0.65, 0.44, duration: 0.19)) {
                    carPose = CarPose(travel: -0.16, lift: -0.018, pitch: 3.2, heightScale: 1.02)
                }
                try await Task.sleep(nanoseconds: 35_000_000)
                withAnimation(.easeOut(duration: 0.12)) {
                    smoke = SmokePose(scale: 1.36, x: -0.04, y: -0.035)
                }
                try await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.easeOut(duration: 0.685)) {
                    smoke = SmokePose(scale: 1.70, x: 0.055, y: -0.17, opacity: 0)
                }
                try await Task.sleep(nanoseconds: 35_000_000)

                withAnimation(.timingCurve(0.32, 0.31, 0.61, 0.61, duration: 0.52)) {
                    carPose = CarPose(travel: -1)
                }
                try await Task.sleep(nanoseconds: 650_000_000)
            }
            guard !Task.isCancelled else { return }
            onFinished()
        } catch {
            return
        }
    }
}

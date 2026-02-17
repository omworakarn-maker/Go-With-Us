import SwiftUI
import Combine

/// Simple keyboard observer to provide current keyboard height for SwiftUI views
final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        willShow.merge(with: willHide)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if notification.name == UIResponder.keyboardWillShowNotification,
                   let info = notification.userInfo,
                   let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.currentHeight = frame.height
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.currentHeight = 0
                    }
                }
            }
            .store(in: &cancellableSet)
    }
}

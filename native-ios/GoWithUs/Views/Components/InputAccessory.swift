import SwiftUI

/// A UIViewControllerRepresentable that presents a SwiftUI view as an inputAccessoryView
struct InputAccessory<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        // Create hosting controller directly as the input accessory
        let hosting = HostingAccessoryController(rootView: content)
        hosting.view.backgroundColor = .clear
        return hosting
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }

    // A UIHostingController subclass that provides its view as inputAccessoryView
    class HostingAccessoryController<HostContent: View>: UIHostingController<HostContent> {
        override var canBecomeFirstResponder: Bool { true }
        override var inputAccessoryView: UIView? { view }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            // Make it first responder after view is loaded
            DispatchQueue.main.async {
                self.becomeFirstResponder()
            }
        }
    }
}

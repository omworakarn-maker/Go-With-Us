import UIKit
import Capacitor

@objc(ViewController)
class ViewController: CAPBridgeViewController {

    // --- NATIVE LAYOUT FIX (AUTO LAYOUT) ---
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- Native Animation Demo ---
        self.webView?.alpha = 0
        UIView.animate(withDuration: 1.5) {
            self.webView?.alpha = 1
        }

        // Apply Constraints - Let CSS handle safe areas
        if let webView = self.webView {
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                // Pin to all edges (full screen)
                webView.topAnchor.constraint(equalTo: self.view.topAnchor),
                webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }
    // Remove the manual frame layout to avoid conflicts
    
    // ตัวอย่างฟังก์ชันสั่งสั่น (เขียนแบบ Native Swift แท้ๆ)
    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

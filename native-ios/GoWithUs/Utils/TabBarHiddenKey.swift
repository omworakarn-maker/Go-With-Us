import SwiftUI

struct TabBarHiddenKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func hideTabBar(_ hidden: Bool) -> some View {
        preference(key: TabBarHiddenKey.self, value: hidden)
    }
}

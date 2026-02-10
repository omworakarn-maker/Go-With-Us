import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("ไม่มีการแจ้งเตือน")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification) {
                                Task {
                                    await viewModel.markAsRead(id: notification.id)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteNotification(id: notification.id)
                                    }
                                } label: {
                                    Label("ลบ", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadNotifications()
                    }
                }
            }
            .navigationTitle("การแจ้งเตือน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.notifications.isEmpty {
                        Button("ลบทั้งหมด") {
                            Task { await viewModel.clearAllNotifications() }
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ปิด") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task { await viewModel.loadNotifications() }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Circle()
                    .fill(notification.isRead ? Color.gray.opacity(0.2) : Color.black)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 18))
                            .foregroundColor(notification.isRead ? .gray : .white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: notification.isRead ? .medium : .bold))
                        .foregroundColor(.black)
                    
                    if !notification.message.isEmpty {
                        Text(notification.message)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Text(timeAgoDisplay(dateString: notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch notification.type {
        case "trip": return "map"
        case "alert": return "exclamationmark.triangle"
        default: return "bell"
        }
    }
    
    private func timeAgoDisplay(dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "เมื่อสักครู่"
        }
        
        let relFormatter = RelativeDateTimeFormatter()
        relFormatter.unitsStyle = .abbreviated
        return relFormatter.localizedString(for: date, relativeTo: Date())
    }
}

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewNotification), name: NSNotification.Name("NewNotificationReceived"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNewNotification() {
        Task {
            await loadNotifications()
        }
    }
    
    func loadNotifications() async {
        isLoading = true
        do {
            notifications = try await NotificationService.shared.getNotifications()
        } catch {
            print("Error loading notifications: \(error)")
        }
        isLoading = false
    }
    
    func markAsRead(id: String) async {
        do {
            try await NotificationService.shared.markAsRead(id: id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                notifications[index] = AppNotification(
                    id: notifications[index].id,
                    title: notifications[index].title,
                    message: notifications[index].message,
                    type: notifications[index].type,
                    targetId: notifications[index].targetId,
                    createdAt: notifications[index].createdAt,
                    isRead: true
                )
            }
        } catch {
            print("Error marking as read: \(error)")
        }
    }
    
    func deleteNotification(id: String) async {
        do {
            try await NotificationService.shared.deleteNotification(id: id)
            notifications.removeAll(where: { $0.id == id })
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
    
    func clearAllNotifications() async {
        do {
            try await NotificationService.shared.clearAllNotifications()
            await loadNotifications() // Reload to see what remains (private ones cleared)
        } catch {
            print("Error clearing notifications: \(error)")
        }
    }
}

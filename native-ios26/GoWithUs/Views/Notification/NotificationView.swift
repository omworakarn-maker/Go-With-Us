import Combine
import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath: [String] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.white.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text(tr("ไม่มีการแจ้งเตือน", "No notifications"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(
                                notification: notification,
                                onTap: {
                                    if notification.type == "trip", let tripId = notification.targetId {
                                        navigationPath.append(tripId)
                                    }
                                    Task { await viewModel.markAsRead(id: notification.id) }
                                },
                                onDelete: {
                                    Task { await viewModel.deleteNotification(id: notification.id) }
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadNotifications()
                    }
                }
            }
            .navigationTitle(tr("การแจ้งเตือน", "Notifications"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { tripId in
                TripDetailView(tripId: tripId)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.notifications.isEmpty {
                        Button(tr("ลบทั้งหมด", "Delete all")) {
                            Task { await viewModel.clearAllNotifications() }
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(tr("ปิด", "Close")) {
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
    let onDelete: () -> Void
    @State private var swipeOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.red.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .accessibilityLabel(Text(tr("ลบการแจ้งเตือน", "Delete notification")))

            HStack(alignment: .top, spacing: 12) {
                // Icon
                Circle()
                    .fill(notification.isRead ? Color.gray.opacity(0.2) : Color.appPrimary)
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
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(notification.isRead ? Color.white : Color.appSecondary.opacity(0.05))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .offset(x: swipeOffset)
            .onTapGesture {
                if swipeOffset < 0 {
                    withAnimation(.smooth(duration: 0.22)) { swipeOffset = 0 }
                } else {
                    onTap()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        swipeOffset = min(0, max(-74, value.translation.width))
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let shouldReveal = value.predictedEndTranslation.width < -36
                        withAnimation(.smooth(duration: 0.24)) {
                            swipeOffset = shouldReveal ? -68 : 0
                        }
                    }
            )
        }
        .clipped()
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
        var serverNotifications: [AppNotification] = []
        do {
            serverNotifications = try await NotificationService.shared.getNotifications()
        } catch {
            print("Warning: failed to load server notifications: \(error)")
        }

        // Merge local persisted notifications (newer or offline) with server list
        let local = LocalNotificationStore.shared.notifications

        var map: [String: AppNotification] = [:]
        for n in serverNotifications { map[n.id] = n }
        for n in local { if map[n.id] == nil { map[n.id] = n } }

        notifications = Array(map.values)
        notifications.sort { lhs, rhs in
            let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return (f.date(from: lhs.createdAt) ?? Date()) > (f.date(from: rhs.createdAt) ?? Date())
        }
        isLoading = false
    }

    func markAsRead(id: String) async {
        // Optimistic UI update
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

        do {
            try await NotificationService.shared.markAsRead(id: id)
            LocalNotificationStore.shared.markAsRead(id: id)
        } catch {
            print("Error marking as read: \(error)")
            // Optionally revert the state here if needed
        }
    }

    func deleteNotification(id: String) async {
        // 1. ลบจาก UI ทันที (Optimistic Delete) เพื่อป้องกันแอปเด้งตอน Swipe
        await MainActor.run {
            withAnimation {
                notifications.removeAll(where: { $0.id == id })
            }
        }
        LocalNotificationStore.shared.remove(id: id)

        // 2. ลบจาก Server
        do {
            try await NotificationService.shared.deleteNotification(id: id)
        } catch {
            print("Error deleting notification: \(error)")
        }
    }

    func clearAllNotifications() async {
        do {
            try await NotificationService.shared.clearAllNotifications()
            LocalNotificationStore.shared.clearAll()
            await MainActor.run {
                withAnimation {
                    notifications.removeAll()
                }
            }
            await loadNotifications() // Reload to see what remains (private ones cleared)
        } catch {
            print("Error clearing notifications: \(error)")
        }
    }
}

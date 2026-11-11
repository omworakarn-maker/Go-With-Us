import SwiftUI

import PhotosUI

struct AppPromotion: Codable, Identifiable {
    var id = "main"
    var enabled = false
    var image = ""
    var frequency = "daily"
    var targetType = "none"
    var target = ""
    var title = ""
    var revision = ""
    var artwork: UIImage? {
        guard let comma = image.firstIndex(of: ","),
              let data = Data(base64Encoded: String(image[image.index(after: comma)...])) else { return nil }
        return UIImage(data: data)
    }
}
private struct PromotionResponse: Decodable { let promotion: AppPromotion? }

struct AdminPromotionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var promotion = AppPromotion()
    @State private var photo: PhotosPickerItem?
    @State private var loading = true
    @State private var saving = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(tr("โปรโมชัน", "Promotion")) {
                    Toggle(tr("แสดงป๊อปอัป", "Enable popup"), isOn: $promotion.enabled)
                    TextField(tr("ชื่อโปรโมชัน", "Title"), text: $promotion.title)
                    if let image = promotion.artwork {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 260)
                    }
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label(tr("เลือกรูป", "Choose image"), systemImage: "photo")
                    }
                }
                Section(tr("ความถี่", "Frequency")) {
                    Picker(tr("แสดงเมื่อ", "Show"), selection: $promotion.frequency) {
                        Text(tr("วันละครั้ง", "Once per day")).tag("daily")
                        Text(tr("ทุกครั้งที่เปิดแอป", "Every app launch")).tag("launch")
                        Text(tr("ครั้งเดียวต่อโปรโมชัน", "Once per campaign")).tag("once")
                    }
                }
                Section(tr("เมื่อกดรูป", "Banner action")) {
                    Picker(tr("ปลายทาง", "Destination"), selection: $promotion.targetType) {
                        Text(tr("ไม่มี", "None")).tag("none")
                        Text(tr("เว็บไซต์", "Website")).tag("url")
                        Text(tr("ทริป", "Trip")).tag("trip")
                    }
                    if promotion.targetType != "none" {
                        TextField(promotion.targetType == "url" ? "https://…" : "Trip ID", text: $promotion.target)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                }
                if let message { Text(message) }
                Button(tr("บันทึก", "Save")) { Task { await save() } }
                    .disabled(loading || saving || promotion.artwork == nil)
                if loading || saving { ProgressView() }
            }
            .navigationTitle(tr("ป๊อปอัปโปรโมชัน", "Promotion popup"))
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button(tr("ปิด", "Close")) { dismiss() }
            }}
            .task {
                do {
                    let response: PromotionResponse = try await APIService.shared.request(endpoint: "/promotions/settings")
                    promotion = response.promotion ?? AppPromotion()
                } catch { message = error.localizedDescription }
                loading = false
            }
            .task(id: photo) {
                guard let photo else { return }
                do {
                    guard let data = try await photo.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    try Task.checkCancellation()
                    let ratio = min(1, 1400 / max(image.size.width, image.size.height))
                    let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1
                    let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                        image.draw(in: CGRect(origin: .zero, size: size))
                    }
                    guard let jpeg = resized.jpegData(compressionQuality: 0.8), jpeg.count < 2 * 1024 * 1024 else {
                        message = tr("รูปใหญ่เกินไป กรุณาเลือกรูปใหม่", "Image too large. Choose another image.")
                        return
                    }
                    promotion.image = "data:image/jpeg;base64," + jpeg.base64EncodedString()
                    message = nil
                } catch is CancellationError {
                } catch { message = error.localizedDescription }
            }
        }
    }
    @MainActor private func save() async {
        saving = true
        defer { saving = false }
        do {
            let _: MessageResponse = try await APIService.shared.request(
                endpoint: "/promotions/settings", method: .put, body: promotion)
            message = tr("บันทึกแล้ว", "Saved")
        } catch { message = error.localizedDescription }
    }
}

struct PromotionStartupOverlay: View {
    let ready: Bool
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.openURL) private var openURL
    @State private var promotion: AppPromotion?
    @State private var checkedUser: String?
    @State private var selectedTrip: PromotionTrip?
    private struct PromotionTrip: Identifiable { let id: String }
    private var requestKey: String {
        guard ready, !auth.needsOnboarding, !auth.showOTPVerification else { return "" }
        return auth.currentUser?.id ?? ""
    }
    var body: some View {
        ZStack {
            if let promotion, let image = promotion.artwork {
                Color.black.opacity(0.45).ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button { self.promotion = nil } label: {
                            Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                                .frame(width: 44, height: 44).background(.black.opacity(0.5), in: Circle())
                        }.accessibilityLabel(tr("ปิดโปรโมชัน", "Close promotion"))
                    }
                    Button {
                        if promotion.targetType == "trip" {
                            selectedTrip = PromotionTrip(id: promotion.target)
                            self.promotion = nil
                        } else if promotion.targetType == "url",
                                  let url = URL(string: promotion.target), url.scheme == "https" {
                            self.promotion = nil
                            openURL(url)
                        }
                    } label: {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(promotion.title.isEmpty ? tr("โปรโมชัน", "Promotion") : promotion.title)
                }.padding(24).frame(maxWidth: 480)
            }
        }
        .task(id: requestKey) {
            let userId = requestKey
            guard !userId.isEmpty, auth.isAuthenticated, checkedUser != userId else { return }
            do {
                let response: PromotionResponse = try await APIService.shared.request(endpoint: "/promotions")
                try Task.checkCancellation()
                guard auth.currentUser?.id == userId else { return }
                checkedUser = userId
                guard let candidate = response.promotion, candidate.enabled, candidate.artwork != nil else { return }
                let key = "promotion.seen." + userId + "." + candidate.revision
                let last = UserDefaults.standard.object(forKey: key) as? Date
                if candidate.frequency == "once", last != nil { return }
                if candidate.frequency == "daily", let last, Calendar.current.isDateInToday(last) { return }
                promotion = candidate
                UserDefaults.standard.set(Date(), forKey: key)
            } catch { /* A promotion failure must not block the app. */ }
        }
        .onChange(of: auth.isAuthenticated) { _, authenticated in
            if !authenticated { promotion = nil; checkedUser = nil }
        }
        .sheet(item: $selectedTrip) { trip in
            NavigationStack { TripDetailView(tripId: trip.id) }
        }
    }
}


struct AdminAlertView: View {
    @StateObject private var viewModel = AdminAlertViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(tr("รายละเอียดการแจ้งเตือน", "Notification details"))) {
                    TextField(tr("หัวข้อ", "Title"), text: $viewModel.title)
                    
                    TextEditor(text: $viewModel.message)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section(header: Text(tr("ประเภท", "Type"))) {
                    Picker(tr("ประเภท", "Type"), selection: $viewModel.type) {
                        Text(tr("ทั่วไป", "General")).tag("alert")
                        Text(tr("ทริป", "Trip")).tag("trip")
                        Text(tr("ระบบ", "System")).tag("system")
                    }
                    .pickerStyle(.segmented)
                }
                
                if viewModel.type == "trip" {
                    Section(header: Text(tr("ทริป (ถ้ามี)", "Trip (optional)"))) {
                        TextField("Trip ID", text: $viewModel.targetId)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.createAlert()
                            if viewModel.success {
                                dismiss()
                            }
                        }
                    }) {
                        if viewModel.isCreating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(tr("ส่งการแจ้งเตือน", "Send notification"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isCreating || viewModel.title.isEmpty)
                }
            }
            .navigationTitle(tr("สร้างการแจ้งเตือน", "Create notification"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("ยกเลิก", "Cancel")) {
                        dismiss()
                    }
                }
            }
            .alert(tr("ข้อผิดพลาด", "Error"), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(tr("ตกลง", "OK")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

@MainActor
class AdminAlertViewModel: ObservableObject {
    @Published var title = ""
    @Published var message = ""
    @Published var type = "alert"
    @Published var targetId = ""
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var success = false
    
    func createAlert() async {
        isCreating = true
        errorMessage = nil
        success = false
        
        do {
            _ = try await NotificationService.shared.createNotification(
                title: title,
                message: message,
                type: type,
                targetId: targetId.isEmpty ? nil : targetId
            )
            success = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCreating = false
    }
}

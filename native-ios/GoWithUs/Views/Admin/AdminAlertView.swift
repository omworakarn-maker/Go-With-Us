import SwiftUI

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

import SwiftUI

struct AdminAlertView: View {
    @StateObject private var viewModel = AdminAlertViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("รายละเอียดการแจ้งเตือน")) {
                    TextField("หัวข้อ", text: $viewModel.title)
                    
                    TextEditor(text: $viewModel.message)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section(header: Text("ประเภท")) {
                    Picker("ประเภท", selection: $viewModel.type) {
                        Text("ทั่วไป").tag("alert")
                        Text("ทริป").tag("trip")
                        Text("ระบบ").tag("system")
                    }
                    .pickerStyle(.segmented)
                }
                
                if viewModel.type == "trip" {
                    Section(header: Text("ทริป (ถ้ามี)")) {
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
                            Text("ส่งการแจ้งเตือน")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isCreating || viewModel.title.isEmpty)
                }
            }
            .navigationTitle("สร้างการแจ้งเตือน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                }
            }
            .alert("ข้อผิดพลาด", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("ตกลง") {
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

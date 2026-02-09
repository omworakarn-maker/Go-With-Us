import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var interests: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ข้อมูลส่วนตัว")) {
                    TextField("ชื่อ", text: $name)
                }
                
                Section(header: Text("ความสนใจ (คั่นด้วยจุลภาค)")) {
                    TextEditor(text: $interests)
                        .frame(height: 100)
                    Text("เช่น: เดินป่า, ทะเล, ถ่ายรูป, อาหาร")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if authViewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("แก้ไขโปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") { dismiss() }
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("บันทึก") {
                        Task {
                            let interestArray = interests.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
                            await authViewModel.updateProfile(name: name, interests: interestArray)
                            dismiss()
                        }
                    }
                    .foregroundColor(.black)
                    .disabled(authViewModel.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    name = user.name
                    interests = user.interests?.joined(separator: ", ") ?? ""
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}

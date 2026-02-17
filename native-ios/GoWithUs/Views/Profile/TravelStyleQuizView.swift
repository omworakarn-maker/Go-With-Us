import SwiftUI

struct TravelStyleQuizView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var step = 0
    @State private var isLoading = false
    @State private var budget: String?
    @State private var pace: String?
    @State private var social: String?
    @State private var accommodation: String?
    @State private var food: String?
    @State private var nightlife: String?
    @State private var transport: String?
    @State private var photography: String?
    
    let questions: [QuizQuestion] = [
        QuizQuestion(
            key: "budget",
            question: "งบประมาณต่อทริปของคุณ?",
            options: [
                QuizOption(value: "budget", label: "ประหยัด (Budget)", desc: "เน้นคุ้มค่า เก็บตังค์ไว้กินของอร่อย"),
                QuizOption(value: "moderate", label: "ปานกลาง (Standard)", desc: "จ่ายได้ถ้าคุ้มค่า ไม่ถูกไม่แพง"),
                QuizOption(value: "luxury", label: "จัดเต็ม (Luxury)", desc: "ขอสบายไว้ก่อน แพงหน่อยไม่ว่ากัน")
            ]
        ),
        QuizQuestion(
            key: "pace",
            question: "สไตล์การท่องเที่ยว (Pace)?",
            options: [
                QuizOption(value: "fast", label: "แน่นเอี๊ยด (Fast)", desc: "เก็บครบทุกแลนด์มาร์ค ตื่นเช้าลุยยันดึก"),
                QuizOption(value: "moderate", label: "สบายๆ (Flexible)", desc: "มีแผนบ้าง ปรับเปลี่ยนได้หน้างาน"),
                QuizOption(value: "relaxed", label: "ชิลล์ (Slow Life)", desc: "นอนตื่นสาย เน้นซึมซับบรรยากาศ")
            ]
        ),
        QuizQuestion(
            key: "social",
            question: "ชอบเที่ยวกับใคร?",
            options: [
                QuizOption(value: "pair", label: "คู่หู (Pair)", desc: "ไปกับเพื่อนสนิท 1 คน"),
                QuizOption(value: "small_group", label: "กลุ่มเล็ก (3-5 คน)", desc: "แก๊งเพื่อนสนิท คล่องตัว"),
                QuizOption(value: "large_group", label: "ปาร์ตี้ (6+ คน)", desc: "ยิ่งเยอะยิ่งมันส์ เฮฮาได้เต็มที่")
            ]
        ),
        QuizQuestion(
            key: "accommodation",
            question: "ชอบที่พักแบบไหน?",
            options: [
                QuizOption(value: "hostel", label: "โฮสเทล (Hostel)", desc: "เน้นถูก ได้เจอเพื่อนใหม่"),
                QuizOption(value: "camping", label: "กางเต็นท์ (Camping)", desc: "ใกล้ชิดธรรมชาติ นอนดูดาว"),
                QuizOption(value: "hotel", label: "โรงแรม (Hotel)", desc: "สะดวกสบาย มาตรฐานครบ"),
                QuizOption(value: "resort", label: "รีสอร์ท (Resort)", desc: "พักผ่อนเต็มที่ บรรยากาศดี")
            ]
        ),
        QuizQuestion(
            key: "food",
            question: "สไตล์การกิน?",
            options: [
                QuizOption(value: "street", label: "Street Food", desc: "กินง่าย อยู่ง่าย เน้นรสชาติท้องถิ่น"),
                QuizOption(value: "cafe", label: "Cafe Hopping", desc: "เน้นร้านสวย ถ่ายรูปปัง กาแฟดี"),
                QuizOption(value: "local", label: "ร้านดังเจ้าถิ่น", desc: "ร้านตำนานที่ต้องไปลอง"),
                QuizOption(value: "fine_dining", label: "Fine Dining", desc: "อาหารหรู บรรยากาศเลิศ")
            ]
        ),
        QuizQuestion(
            key: "nightlife",
            question: "ยามค่ำคืน?",
            options: [
                QuizOption(value: "party", label: "Party Animal", desc: "แดนซ์ยับ ผับบาร์ต้องไป"),
                QuizOption(value: "chill", label: "Nang Chill", desc: "นั่งชิลล์ ฟังเพลง จิบเครื่องดื่ม"),
                QuizOption(value: "quiet", label: "Sleep Early", desc: "นอนเร็ว เก็บแรงไว้เที่ยวพรุ่งนี้")
            ]
        ),
        QuizQuestion(
            key: "transport",
            question: "การเดินทาง?",
            options: [
                QuizOption(value: "public", label: "ขนส่งสาธารณะ", desc: "รถเมล์ รถไฟ ไปได้หมด ประหยัดดี"),
                QuizOption(value: "rent_car", label: "เช่ารถขับ", desc: "ขับเอง อิสระ อยากแวะไหนก็แวะ"),
                QuizOption(value: "private_driver", label: "เหมารถพร้อมคนขับ", desc: "นั่งสวยๆ สบายๆ ไม่ต้องขับเอง")
            ]
        ),
        QuizQuestion(
            key: "photography",
            question: "เรื่องถ่ายรูป?",
            options: [
                QuizOption(value: "pro", label: "ตากล้องมือโปร", desc: "อุปกรณ์ครบ รูปต้องสวยเป๊ะ"),
                QuizOption(value: "instagram", label: "สายคอนเทนต์", desc: "เน้นถ่ายคน มุมสวย ลงไอจี"),
                QuizOption(value: "snap", label: "Snap & Go", desc: "ถ่ายเก็บความทรงจำ ไม่เน้นสวยงาม"),
                QuizOption(value: "none", label: "ไม่เน้นถ่าย", desc: "เก็บภาพไว้ในความทรงจำก็พอ")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("กำลังบันทึกข้อมูล...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else if step < questions.count {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        if step > 0 {
                            Button(action: {
                                withAnimation {
                                    step -= 1
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            }
                        } else {
                            Button(action: { dismiss() }) {
                                Text("ยกเลิก")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(step + 1) / \(questions.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(1)
                    }
                    .padding()
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(questions.count), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            // Question Text
                            VStack(alignment: .leading, spacing: 8) {
                                Text(questions[step].question)
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.black)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("เลือกคำตอบที่เป็นตัวคุณที่สุด")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 24)
                            
                            // Options
                            VStack(spacing: 12) {
                                ForEach(questions[step].options) { option in
                                    Button(action: {
                                        handleSelect(option.value)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(option.label)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.black)
                                            
                                            Text(option.desc)
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 24)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                        )
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(24)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
    
    private func handleSelect(_ value: String) {
        // Assign value based on current step
        switch questions[step].key {
        case "budget": budget = value
        case "pace": pace = value
        case "social": social = value
        case "accommodation": accommodation = value
        case "food": food = value
        case "nightlife": nightlife = value
        case "transport": transport = value
        case "photography": photography = value
        default: break
        }
        
        if step < questions.count - 1 {
            withAnimation {
                step += 1
            }
        } else {
            // Final Step - Save
            saveQuiz()
        }
    }
    
    private func saveQuiz() {
        isLoading = true
        
        let style = TravelStyle(
            budget: budget,
            pace: pace,
            social: social,
            accommodation: accommodation,
            food: food,
            nightlife: nightlife,
            transport: transport,
            photography: photography
        )
        
        Task {
            if let user = authViewModel.currentUser {
                await authViewModel.updateProfile(
                    name: user.name,
                    interests: user.interests ?? [],
                    travelStyle: style
                )
            }
            isLoading = false
            dismiss()
        }
    }
}

struct QuizQuestion {
    let key: String
    let question: String
    let options: [QuizOption]
}

struct QuizOption: Identifiable {
    let id = UUID()
    let value: String
    let label: String
    let desc: String
}

#Preview {
    TravelStyleQuizView()
        .environmentObject(AuthViewModel())
}

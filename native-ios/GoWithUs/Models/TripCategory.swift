import Foundation

struct InterestCategory: Identifiable, Hashable {
    let id: String
    let icon: String // Changed from emoji to icon (SF Symbol name)
    let label: String
}

let INTEREST_CATEGORIES: [InterestCategory] = [
    InterestCategory(id: "ทะเล", icon: "🏖️", label: "ทะเล"),
    InterestCategory(id: "ภูเขา", icon: "🏔️", label: "ภูเขา"),
    InterestCategory(id: "แคมป์ปิ้ง", icon: "🏕️", label: "แคมป์ปิ้ง"),
    InterestCategory(id: "เที่ยวเมือง", icon: "🏙️", label: "เที่ยวเมือง"),
    InterestCategory(id: "คาเฟ่", icon: "☕️", label: "คาเฟ่"),
    InterestCategory(id: "อาหาร", icon: "🍜", label: "อาหาร"),
    InterestCategory(id: "แฮงเอาต์", icon: "🍻", label: "แฮงเอาต์"),
    InterestCategory(id: "ถ่ายรูป", icon: "📸", label: "ถ่ายรูป"),
    InterestCategory(id: "ช้อปปิ้ง", icon: "🛍️", label: "ช้อปปิ้ง"),
    InterestCategory(id: "คอนเสิร์ต", icon: "🎫", label: "คอนเสิร์ต"),
    InterestCategory(id: "ผจญภัย", icon: "🧗", label: "ผจญภัย"),
    InterestCategory(id: "ไหว้พระ", icon: "🏛️", label: "ไหว้พระ")
]


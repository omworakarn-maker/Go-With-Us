import Foundation

struct InterestCategory: Identifiable, Hashable {
    let id: String
    let icon: String // Changed from emoji to icon (SF Symbol name)
    let label: String
}

struct InterestSection: Identifiable {
    let id = UUID()
    let title: String
    let categories: [InterestCategory]
}

let INTEREST_SECTIONS: [InterestSection] = [
    InterestSection(title: "🍃 สายธรรมชาติ & ผจญภัย", categories: [
        InterestCategory(id: "ทะเล", icon: "🏖️", label: "ทะเล"),
        InterestCategory(id: "ภูเขา", icon: "🏔️", label: "ภูเขา"),
        InterestCategory(id: "แคมป์ปิ้ง", icon: "🏕️", label: "แคมป์ปิ้ง"),
        InterestCategory(id: "ผจญภัย", icon: "🧗", label: "ผจญภัย")
    ]),
    InterestSection(title: "🏙️ สายเมือง & ไลฟ์สไตล์", categories: [
        InterestCategory(id: "เที่ยวเมือง", icon: "🏙️", label: "เที่ยวเมือง"),
        InterestCategory(id: "คาเฟ่", icon: "☕️", label: "คาเฟ่"),
        InterestCategory(id: "อาหาร", icon: "🍜", label: "อาหาร"),
        InterestCategory(id: "ช้อปปิ้ง", icon: "🛍️", label: "ช้อปปิ้ง")
    ]),
    InterestSection(title: "🎨 สายศิลปะ & บันเทิง", categories: [
        InterestCategory(id: "ถ่ายรูป", icon: "📸", label: "ถ่ายรูป"),
        InterestCategory(id: "คอนเสิร์ต", icon: "🎫", label: "คอนเสิร์ต"),
        InterestCategory(id: "แฮงเอาต์", icon: "🍻", label: "แฮงเอาต์"),
        InterestCategory(id: "ไหว้พระ", icon: "🏛️", label: "ไหว้พระ")
    ])
]

let INTEREST_CATEGORIES: [InterestCategory] = INTEREST_SECTIONS.flatMap { $0.categories }


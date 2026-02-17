import Foundation

struct InterestCategory: Identifiable, Hashable {
    let id: String
    let emoji: String
    let label: String
}

let INTEREST_CATEGORIES: [InterestCategory] = [
    InterestCategory(id: "ธรรมชาติ", emoji: "🌳", label: "ธรรมชาติ"),
    InterestCategory(id: "ทะเล", emoji: "🏖️", label: "ทะเล"),
    InterestCategory(id: "ภูเขา", emoji: "⛰️", label: "ภูเขา"),
    InterestCategory(id: "แคมป์ปิ้ง", emoji: "⛺", label: "แคมป์ปิ้ง"),
    InterestCategory(id: "ผจญภัย", emoji: "🧗", label: "ผจญภัย"),
    InterestCategory(id: "กีฬา", emoji: "🏃", label: "กีฬา"),
    InterestCategory(id: "ปาร์ตี้", emoji: "🎉", label: "ปาร์ตี้"),
    InterestCategory(id: "วัฒนธรรม", emoji: "🏯", label: "วัฒนธรรม"),
    InterestCategory(id: "ประวัติศาสตร์", emoji: "🏛️", label: "ประวัติศาสตร์"),
    InterestCategory(id: "ถ่ายรูป", emoji: "📸", label: "ถ่ายรูป"),
    InterestCategory(id: "คาเฟ่", emoji: "☕", label: "คาเฟ่"),
    InterestCategory(id: "อาหาร", emoji: "🍜", label: "อาหาร"),
    InterestCategory(id: "ช้อปปิ้ง", emoji: "🛍️", label: "ช้อปปิ้ง"),
    InterestCategory(id: "จิตอาสา", emoji: "🤝", label: "จิตอาสา"),
    InterestCategory(id: "ครอบครัว", emoji: "👨‍👩‍👧‍👦", label: "ครอบครัว"),
    InterestCategory(id: "อื่นๆ", emoji: "✨", label: "อื่นๆ")
]


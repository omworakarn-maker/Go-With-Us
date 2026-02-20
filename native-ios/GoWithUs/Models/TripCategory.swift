import Foundation

struct InterestCategory: Identifiable, Hashable {
    let id: String
    let icon: String // Changed from emoji to icon (SF Symbol name)
    let label: String
}

let INTEREST_CATEGORIES: [InterestCategory] = [
    InterestCategory(id: "ธรรมชาติ", icon: "leaf.fill", label: "ธรรมชาติ"),
    InterestCategory(id: "ทะเล", icon: "water.waves", label: "ทะเล"),
    InterestCategory(id: "ภูเขา", icon: "mountain.2.fill", label: "ภูเขา"),
    InterestCategory(id: "แคมป์ปิ้ง", icon: "tent.fill", label: "แคมป์ปิ้ง"),
    InterestCategory(id: "ผจญภัย", icon: "figure.climbing", label: "ผจญภัย"),
    InterestCategory(id: "กีฬา", icon: "figure.run", label: "กีฬา"),
    InterestCategory(id: "ปาร์ตี้", icon: "party.popper.fill", label: "ปาร์ตี้"),
    InterestCategory(id: "วัฒนธรรม", icon: "building.columns.fill", label: "วัฒนธรรม"),
    InterestCategory(id: "ประวัติศาสตร์", icon: "clock.arrow.circlepath", label: "ประวัติศาสตร์"),
    InterestCategory(id: "ถ่ายรูป", icon: "camera.fill", label: "ถ่ายรูป"),
    InterestCategory(id: "คาเฟ่", icon: "cup.and.saucer.fill", label: "คาเฟ่"),
    InterestCategory(id: "อาหาร", icon: "fork.knife", label: "อาหาร"),
    InterestCategory(id: "ช้อปปิ้ง", icon: "bag.fill", label: "ช้อปปิ้ง"),
    InterestCategory(id: "จิตอาสา", icon: "heart.fill", label: "จิตอาสา"),
    InterestCategory(id: "ครอบครัว", icon: "figure.2.and.child.holdinghands", label: "ครอบครัว"),
    InterestCategory(id: "อื่นๆ", icon: "sparkles", label: "อื่นๆ")
]


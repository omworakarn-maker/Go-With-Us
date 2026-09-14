import SwiftUI
import PhotosUI
import MapKit

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = SettingsManager.shared
    @State private var title = ""
    @State private var destination = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate: Date? = nil
    @State private var budget = ""
    @State private var budgetType = "per_person"
    @State private var maxParticipants = "10"
    @State private var selectedCategoryRaw: String = TripCategory.adventure.rawValue
    @State private var additionalInterests: [String] = []
    @State private var imageUrl = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isPublic = true // Default to Public
    @State private var isLoading = false
    @State private var isGeneratingAI = false
    @State private var errorMessage: String?
    @State private var tags: [String] = []
    @State private var tagInput: String = ""
    @State private var itinerary: [DayPlan]?
    @State private var showDeleteAlert = false
    @State private var specificLocation = ""
    @State private var activityStyle: Double = 3.0
    @State private var timeOfDay: [String] = []
    @State private var aiPrompt: String = ""
    @State private var creationStep = 0

    private var creationStepTitles: [String] {
        SettingsManager.shared.currentLanguage == .thai
            ? ["ข้อมูลทริป", "วันและงบประมาณ", "แผนการเดินทาง", "ตรวจสอบข้อมูล"]
            : ["Trip details", "Dates & budget", "Itinerary", "Review"]
    }
    
    var timeSlots: [(String, String, String)] {
        SettingsManager.shared.currentLanguage == .thai ? [
            ("morning", "ช่วงเช้า (06:00 - 11:00 น.)", "เช่น ชมพระอาทิตย์ขึ้น, เยี่ยมชมตลาดเช้า"),
            ("noon", "ช่วงกลางวัน (11:00 - 16:00 น.)", "เช่น รับประทานอาหาร, พักผ่อนในคาเฟ่, เข้าชมพิพิธภัณฑ์"),
            ("evening", "ช่วงเย็น (16:00 - 20:00 น.)", "เช่น เดินพักผ่อน, ชมพระอาทิตย์ตก, รับประทานอาหารค่ำ"),
            ("night", "ช่วงกลางคืน (20:00 น. เป็นต้นไป)", "เช่น สัมผัสบรรยากาศยามค่ำคืน, เข้าร่วมงานสังสรรค์")
        ] : [
            ("morning", "Morning (6:00 AM – 11:00 AM)", "e.g. sunrise views or morning markets"),
            ("noon", "Afternoon (11:00 AM – 4:00 PM)", "e.g. lunch, cafes, or museums"),
            ("evening", "Evening (4:00 PM – 8:00 PM)", "e.g. walks, sunset views, or dinner"),
            ("night", "Night (after 8:00 PM)", "e.g. nightlife or social events")
        ]
    }

    private var selectedTripStyles: [String] {
        var styles = [selectedCategoryRaw]
        for style in additionalInterests where !styles.contains(style) {
            styles.append(style)
        }
        return Array(styles.prefix(3))
    }

    private func toggleTripStyle(_ style: String) {
        if selectedCategoryRaw == style {
            guard !additionalInterests.isEmpty else { return }
            selectedCategoryRaw = additionalInterests.removeFirst()
        } else if additionalInterests.contains(style) {
            additionalInterests.removeAll { $0 == style }
        } else if selectedTripStyles.count < 3 {
            additionalInterests.append(style)
        }
    }
    

    
    // Draft Injection
    var draft: TripDraft?
    // Edit Injection
    var editingTrip: Trip?
    
    init(draft: TripDraft? = nil) {
        self.draft = draft
        self.editingTrip = nil
        
        if let draft = draft {
            _title = State(initialValue: draft.title)
            _destination = State(initialValue: draft.destination)
            _description = State(initialValue: draft.description)
            _budget = State(initialValue: String(draft.budget))
            _budgetType = State(initialValue: draft.budgetType ?? "per_person")
            _maxParticipants = State(initialValue: String(draft.maxParticipants))
            _itinerary = State(initialValue: draft.itinerary)
            
            // Date Parsing
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let start = formatter.date(from: draft.startDate) {
                _startDate = State(initialValue: start)
            }
            if let endString = draft.endDate, let end = formatter.date(from: endString) {
                _endDate = State(initialValue: end)
            }
            
            // Category Matching
            let allowedCategories = Set(INTEREST_CATEGORIES.map(\.label))
            _selectedCategoryRaw = State(
                initialValue: allowedCategories.contains(draft.category)
                    ? draft.category
                    : TripCategory.adventure.rawValue
            )
            _additionalInterests = State(
                initialValue: Array(
                    (draft.interestTags ?? [])
                        .filter { allowedCategories.contains($0) && $0 != draft.category }
                        .prefix(2)
                )
            )
            
            // Tags from AI draft
            if let draftTags = draft.tags {
                _tags = State(initialValue: draftTags)
            }
            
            if let draftActivityStyle = draft.activityStyle {
                _activityStyle = State(initialValue: Double(draftActivityStyle))
            }
            
            if let draftTimeOfDay = draft.timeOfDay {
                _timeOfDay = State(initialValue: draftTimeOfDay)
            }
        }
    }
    
    // Initializer for Editing
    init(trip: Trip) {
        self.draft = nil
        self.editingTrip = trip
        
        _title = State(initialValue: trip.title)
        _destination = State(initialValue: trip.destination)
        _description = State(initialValue: trip.description ?? "")
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _budget = State(initialValue: String(trip.budget))
        _budgetType = State(initialValue: trip.budgetType ?? "per_person")
        _maxParticipants = State(initialValue: String(trip.maxParticipants))
        _selectedCategoryRaw = State(
            initialValue: INTEREST_CATEGORIES.contains { $0.label == trip.category.rawValue }
                ? trip.category.rawValue
                : TripCategory.adventure.rawValue
        )
        _additionalInterests = State(
            initialValue: Array(
                trip.interestTags
                    .filter { $0 != trip.category.rawValue }
                    .prefix(2)
            )
        )
        _imageUrl = State(initialValue: trip.imageUrl ?? "")
        _isPublic = State(initialValue: trip.isPublic)
        _itinerary = State(initialValue: trip.itinerary)
        _activityStyle = State(initialValue: Double(trip.activityStyle ?? 3))
        _timeOfDay = State(initialValue: trip.timeOfDay ?? [])
        
        // Parse province and specific location from destination
        let dest = trip.destination
        if let range = dest.range(of: " (") {
            _destination = State(initialValue: String(dest[..<range.lowerBound]))
            var spec = String(dest[range.lowerBound...])
            spec = spec.replacingOccurrences(of: " (", with: "").replacingOccurrences(of: ")", with: "")
            _specificLocation = State(initialValue: spec)
        } else {
            _destination = State(initialValue: dest)
            _specificLocation = State(initialValue: "")
        }
        
        let desc = trip.description ?? ""
        _description = State(initialValue: desc)
    }
    
    #if false
    // Kept temporarily for reference while the wizard was split into smaller views.
    private var legacyBody: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                    .tint(.appPrimary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(editingTrip != nil ? "\(tr("แก้ไข", "Edit")) \(title)" : tr("สร้างทริปใหม่", "Create a new trip"))
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.adaptiveText)
                                .lineLimit(2)
                                .tracking(-0.5)
                            
                            Text(creationStepTitles[creationStep])
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            ProgressView(value: Double(creationStep + 1), total: 4)
                                .tint(.appPrimary)
                                .padding(.top, 6)
                            Text(SettingsManager.shared.currentLanguage == .thai
                                 ? "ขั้นตอนที่ \(creationStep + 1) จาก 4"
                                 : "Step \(creationStep + 1) of 4")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        
                        // Form
                        VStack(spacing: 20) {
                            if creationStep == 0 {
                                AnyView(VStack(spacing: 20) {
                            // Title
                            FormField(label: tr("ชื่อทริป", "Trip name"), placeholder: tr("เช่น เที่ยวเชียงใหม่ 3 วัน 2 คืน", "e.g. 3 days and 2 nights in Chiang Mai"), text: $title)
                            
                            // Photos and Image URL section
                            TripMultiImagePickerView(
                                selectedImages: $selectedImages,
                                imageUrl: $imageUrl,
                                existingUrls: {
                                    if let trip = editingTrip {
                                        return ([trip.imageUrl].compactMap { $0 } + (trip.gallery ?? []))
                                    }
                                    return []
                                }()
                            )
                            .padding(.bottom, 8)
                            // Destination Selection & Specific Place
                            VStack(alignment: .leading, spacing: 12) {
                                // Province Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(tr("จังหวัด", "Province"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                    
                                    Menu {
                                        ForEach(thaiProvinces, id: \.self) { province in
                                            Button(localizedPlaceName(province)) {
                                                destination = province
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(destination.isEmpty ? tr("เลือกจังหวัด", "Select province") : localizedPlaceName(destination))
                                                .foregroundColor(destination.isEmpty ? .gray : .adaptiveText)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // Specific Location
                                FormField(label: tr("ระบุสถานที่เจาะจง (ไม่จำเป็น)", "Specific location (optional)"), placeholder: tr("เช่น ชื่อดอย, ชื่อชายหาด, ชื่อร้านค้า", "e.g. mountain, beach, or venue name"), text: $specificLocation)
                            }

                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("สไตล์ของทริป", "Trip styles"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                Menu {
                                    ForEach(TripCategory.allCases, id: \.self) { category in
                                        Button(category.rawValue) {
                                            selectedCategoryRaw = category.rawValue
                                        }
                                    }
                                    // Extra user categories
                                    ForEach(extraCategories, id: \.self) { cat in
                                        Button(cat) { selectedCategoryRaw = cat }
                                    }

                                    Divider()
                                    Button(tr("เพิ่มสไตล์...", "Add style…")) {
                                        showAddCategory = true
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategoryRaw)
                                            .foregroundColor(.adaptiveText)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(tr("รายละเอียด", "Details"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                    Spacer()
                                    Button(action: generateAITrip) {
                                        HStack(spacing: 4) {
                                            if isGeneratingAI {
                                                ProgressView().scaleEffect(0.6).tint(.white)
                                            } else {
                                                Image(systemName: "sparkles")
                                            }
                                            Text(isGeneratingAI ? tr("กำลังจัดทริป...", "Planning trip…") : tr("AI ช่วยจัดทริป", "Plan with AI"))
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.appPrimary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isGeneratingAI)
                                }
                                
                                if !aiPrompt.isEmpty || true {
                                    TextField(tr("ความต้องการพิเศษให้ AI (เช่น เน้นคาเฟ่, สายมู)...", "Special requests for AI (e.g. cafes or temples)…"), text: $aiPrompt)
                                        .font(.system(size: 13))
                                        .padding(10)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .padding(.bottom, 4)
                                }
                                

                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $description)
                                        .foregroundColor(.adaptiveText)
                                        .tint(.appPrimary)
                                        .frame(minHeight: 120)
                                        .padding(8)
                                        .scrollContentBackground(.hidden) // Remove white background
                                        .background(Color.clear)
                                    
                                    if description.isEmpty {
                                        Text(tr("เขียนรายละเอียดตรงนี้", "Enter details here"))
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }

                            // Tags / Keywords
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("แท็ก / คีย์เวิร์ด", "Tags / Keywords"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                // Tag chips
                                if !tags.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(tags, id: \.self) { tag in
                                                HStack(spacing: 4) {
                                                    Text("#\(tag)")
                                                        .font(.system(size: 13, weight: .medium))
                                                    Button(action: {
                                                        withAnimation { tags.removeAll { $0 == tag } }
                                                    }) {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                    }
                                                }
                                                .foregroundColor(.appPrimary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.appPrimary.opacity(0.1))
                                                .cornerRadius(16)
                                            }
                                        }
                                    }
                                }
                                
                                // Tag input
                                HStack {
                                    TextField(tr("เช่น ทะเล, คาเฟ่, ธรรมชาติ", "e.g. beach, cafe, nature"), text: $tagInput)
                                        .foregroundColor(.adaptiveText)
                                        .tint(.appPrimary)
                                        .onSubmit {
                                            addTag()
                                        }
                                    
                                    Button(action: { addTag() }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.3) : .appPrimary)
                                    }
                                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            
                            // Visibility Toggle
                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading) {
                                    Text(tr("สาธารณะ", "Public"))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                    Text(tr("ทุกคนสามารถเห็นทริปนี้ได้", "Everyone can see this trip"))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                                })
                            }
                            
                            if creationStep == 1 {
                                AnyView(VStack(spacing: 20) {
                            // Dates
                            TripDateInputView(startDate: $startDate, endDate: $endDate)
                            
                            // Budget & Max Participants
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    FormField(label: tr("งบประมาณ (บาท)", "Budget (THB)"), placeholder: tr("ระบุจำนวนเงิน", "Enter amount"), text: $budget)
                                        .keyboardType(.numberPad)
                                    
                                    FormField(label: tr("จำนวนคน", "Participants"), placeholder: "10", text: $maxParticipants)
                                        .keyboardType(.numberPad)
                                }
                                
                                HStack(spacing: 8) {
                                    Text(tr("ประเภทงบ:", "Budget type:"))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.adaptiveSecondaryText)
                                    
                                    Button(action: { budgetType = "per_person" }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: budgetType == "per_person" ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 13))
                                            Text(tr("ต่อคน", "Per person"))
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(budgetType == "per_person" ? .appAccent : .adaptiveSecondaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(budgetType == "per_person" ? Color.appAccent.opacity(0.12) : Color.gray.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { budgetType = "per_trip" }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: budgetType == "per_trip" ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 13))
                                            Text(tr("ต่อทริป (รวม)", "Per trip (total)"))
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(budgetType == "per_trip" ? .appAccent : .adaptiveSecondaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(budgetType == "per_trip" ? Color.appAccent.opacity(0.12) : Color.gray.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 2)
                            }
                            
                            // Time of Day (activity style is calculated from the itinerary)
                            VStack(alignment: .leading, spacing: 16) {
                                Text(tr("ช่วงเวลาของทริป", "Trip time preferences"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                    .padding(.top, 8)
                                
                                VStack(spacing: 8) {
                                    ForEach(timeSlots, id: \.0) { slot in
                                        let (key, label, desc) = slot
                                        let isSelected = timeOfDay.contains(key)
                                        
                                        Button {
                                            if isSelected {
                                                timeOfDay.removeAll { $0 == key }
                                            } else {
                                                timeOfDay.append(key)
                                            }
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(label)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(isSelected ? .white : .adaptiveText)
                                                    Text(desc)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                                                }
                                                Spacer()
                                                if isSelected {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.white)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding()
                                            .background(isSelected ? Color.appPrimary : Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                                })
                            }
                            
                            if creationStep == 2 {
                                AnyView(VStack(spacing: 20) {
                                    // Itinerary Section
                                    ItineraryEditorView(itinerary: $itinerary)
                                })
                            }

                            if creationStep == 3 {
                                AnyView(VStack(alignment: .leading, spacing: 16) {
                                    Text(editingTrip != nil
                                         ? tr("ตรวจสอบก่อนบันทึก", "Review before saving")
                                         : tr("ตรวจสอบก่อนสร้างทริป", "Review before creating"))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.adaptiveText)

                                    ReviewRow(label: tr("ชื่อทริป", "Trip name"), value: title)
                                    ReviewRow(label: tr("สถานที่", "Location"), value: specificLocation.isEmpty ? destination : "\(destination) (\(specificLocation))")
                                    ReviewRow(label: tr("สไตล์ของทริป", "Trip styles"), value: selectedTripStyles.map(localizedInterestName).joined(separator: ", "))
                                    ReviewRow(label: tr("วันที่เริ่ม", "Start date"), value: startDate.formatted(date: .abbreviated, time: .omitted))
                                    ReviewRow(label: tr("วันที่สิ้นสุด", "End date"), value: endDate?.formatted(date: .abbreviated, time: .omitted) ?? tr("วันเดียว", "One day"))
                                    ReviewRow(label: tr("งบประมาณ", "Budget"), value: "\(budget.isEmpty ? "0" : budget) \(tr("บาท", "THB")) \(budgetType == "per_trip" ? tr("ต่อทริป", "per trip") : tr("ต่อคน", "per person"))")
                                    ReviewRow(label: tr("จำนวนผู้ร่วมทริป", "Participants"), value: "\(tr("สูงสุด", "Up to")) \(maxParticipants) \(tr("คน", "people"))")
                                    ReviewRow(label: tr("แผนการเดินทาง", "Itinerary"), value: "\(itinerary?.count ?? 0) \(tr("วัน", "days")) · \(itinerary?.reduce(0) { $0 + $1.activities.count } ?? 0) \(tr("กิจกรรม", "activities"))")
                                    ReviewRow(label: tr("การมองเห็น", "Visibility"), value: isPublic ? tr("สาธารณะ", "Public") : tr("ส่วนตัว", "Private"))
                                }
                                .padding(18)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15))))
                            }
                            
                            // Error Message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            HStack(spacing: 12) {
                                if creationStep > 0 {
                                    Button {
                                        errorMessage = nil
                                        withAnimation(.easeInOut) { creationStep -= 1 }
                                    } label: {
                                        Text(tr("ย้อนกลับ", "Back"))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.adaptiveText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }

                                Button {
                                    if creationStep == 3 {
                                        saveTrip()
                                    } else {
                                        advanceCreationStep()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        if isLoading {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text(creationStep == 3 ? (editingTrip != nil ? tr("บันทึกการแก้ไข", "Save changes") : tr("สร้างทริป", "Create trip")) : tr("ถัดไป", "Next"))
                                                .font(.system(size: 15, weight: .bold))
                                            Image(systemName: creationStep == 3 ? "checkmark.circle.fill" : "arrow.right")
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.appPrimary)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                .id(creationStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("ยกเลิก", "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.adaptiveText)
                }
                
                if editingTrip != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert(tr("ยืนยันการลบทริป", "Confirm trip deletion"), isPresented: $showDeleteAlert) {
                Button(tr("ยกเลิก", "Cancel"), role: .cancel) { }
                Button(tr("ลบ", "Delete"), role: .destructive) {
                    deleteTrip()
                }
            } message: {
                Text(tr("คุณแน่ใจหรือไม่ว่าต้องการลบทริปนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้", "Are you sure you want to delete this trip? This action cannot be undone."))
            }
        }
        .tint(.appPrimary)
        .onAppear { 
            loadExtraCategories()
            if description.isEmpty {
                description = ""
            }
            
            // Synchronize state when view appears (fixes SwiftUI state retention bug in sheets)
            if let t = editingTrip {
                title = t.title
                destination = t.destination
                if let d = t.description, !d.isEmpty { description = d }
                startDate = t.startDate
                if let e = t.endDate { endDate = e }
                budget = String(t.budget)
                budgetType = t.budgetType ?? "per_person"
                maxParticipants = String(t.maxParticipants)
                selectedCategoryRaw = t.category.rawValue
                isPublic = t.isPublic
                if let itin = t.itinerary { itinerary = itin }
                activityStyle = Double(t.activityStyle ?? 3)
                timeOfDay = t.timeOfDay ?? []
            } else if let d = draft {
                title = d.title
                destination = d.destination
                description = d.description
                budget = String(d.budget)
                budgetType = d.budgetType ?? "per_person"
                maxParticipants = String(d.maxParticipants)
                if let itin = d.itinerary { itinerary = itin }
                if let a = d.activityStyle { activityStyle = Double(a) }
                if let tod = d.timeOfDay { timeOfDay = tod }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            NavigationView {
                VStack(spacing: 16) {
                    TextField(tr("ชื่อสไตล์ใหม่", "New style name"), text: $newCategoryText)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .tint(.appPrimary)
                        .cornerRadius(8)

                    Spacer()
                }
                .padding()
                .navigationTitle(tr("เพิ่มสไตล์", "Add style"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(tr("ยกเลิก", "Cancel")) { showAddCategory = false; newCategoryText = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(tr("บันทึก", "Save")) {
                            let trimmed = newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                saveExtraCategory(trimmed)
                                selectedCategoryRaw = trimmed
                            }
                            showAddCategory = false
                            newCategoryText = ""
                        }
                    }
                }
            }
        }
    }
    #endif

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                wizardHeader
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear
                            .frame(height: 0)
                            .id("createTripStepTop")

                        currentStepView
                            .padding(24)
                    }
                    .onChange(of: creationStep) { _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("createTripStepTop", anchor: .top)
                        }
                    }
                }
                Divider()
                wizardNavigation
            }
            .background(Color.adaptiveBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(tr("ยกเลิก", "Cancel")) { dismiss() }
                        .foregroundColor(.adaptiveText)
                }
                if editingTrip != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                    }
                }
            }
            .alert(tr("ยืนยันการลบทริป", "Confirm trip deletion"), isPresented: $showDeleteAlert) {
                Button(tr("ยกเลิก", "Cancel"), role: .cancel) { }
                Button(tr("ลบ", "Delete"), role: .destructive) { deleteTrip() }
            } message: {
                Text(tr("คุณแน่ใจหรือไม่ว่าต้องการลบทริปนี้?", "Are you sure you want to delete this trip?"))
            }
        }
        .tint(.appPrimary)
        .onAppear {
            synchronizeInjectedTrip()
        }
    }

    private var wizardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(editingTrip != nil
                 ? SettingsManager.shared.text(thai: "แก้ไขทริป", english: "Edit trip")
                 : SettingsManager.shared.text(thai: "สร้างทริปใหม่", english: "Create a new trip"))
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.adaptiveText)
            Text(creationStepTitles[creationStep])
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            ProgressView(value: Double(creationStep + 1), total: 4)
                .tint(.appPrimary)
            Text(SettingsManager.shared.currentLanguage == .thai
                 ? "ขั้นตอนที่ \(creationStep + 1) จาก 4"
                 : "Step \(creationStep + 1) of 4")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch creationStep {
        case 0: basicInfoStep
        case 1: scheduleAndBudgetStep
        case 2: itineraryStep
        default: reviewStep
        }
    }

    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            FormField(
                label: SettingsManager.shared.text(thai: "ชื่อทริป", english: "Trip name"),
                placeholder: SettingsManager.shared.text(thai: "เช่น เที่ยวเชียงใหม่ 3 วัน 2 คืน", english: "e.g. 3 days and 2 nights in Chiang Mai"),
                text: $title
            )
            TripMultiImagePickerView(
                selectedImages: $selectedImages,
                imageUrl: $imageUrl,
                existingUrls: editingTrip.map { [$0.imageUrl].compactMap { $0 } + ($0.gallery ?? []) } ?? []
            )
            provincePicker
            FormField(
                label: SettingsManager.shared.text(thai: "ระบุสถานที่เจาะจง (ไม่จำเป็น)", english: "Specific location (optional)"),
                placeholder: SettingsManager.shared.text(thai: "เช่น ดอยอินทนนท์", english: "e.g. Doi Inthanon"),
                text: $specificLocation
            )
            categoryPicker
            descriptionEditor
            tagsEditor
            Toggle(isOn: $isPublic) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(SettingsManager.shared.text(thai: "สาธารณะ", english: "Public")).font(.system(size: 15, weight: .bold))
                    Text(SettingsManager.shared.text(thai: "ทุกคนสามารถเห็นทริปนี้ได้", english: "Everyone can see this trip")).font(.caption).foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            stepError
        }
    }

    private var provincePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SettingsManager.shared.text(thai: "จังหวัด", english: "Province")).font(.system(size: 11, weight: .bold)).foregroundColor(.gray)
            Menu {
                ForEach(thaiProvinces, id: \.self) { province in
                    Button(localizedPlaceName(province)) { destination = province }
                }
            } label: {
                pickerLabel(destination.isEmpty ? SettingsManager.shared.text(thai: "เลือกจังหวัด", english: "Select province") : localizedPlaceName(destination))
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SettingsManager.shared.text(thai: "สไตล์ของทริป", english: "Trip styles"))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.adaptiveText)
            HStack {
                Text(SettingsManager.shared.text(thai: "เลือกได้สูงสุด 3 รายการ เพื่อใช้จับคู่กับความสนใจของผู้ใช้", english: "Select up to 3 styles for interest matching"))
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
                Spacer()
                Text("\(selectedTripStyles.count)/3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.appPrimary.opacity(0.10))
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(INTEREST_CATEGORIES) { category in
                    let isSelected = selectedTripStyles.contains(category.label)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        toggleTripStyle(category.label)
                    } label: {
                        VStack(spacing: 8) {
                            Text(category.icon)
                                .font(.system(size: 30))
                            Text(category.displayLabel)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .background(isSelected ? Color.appPrimary : Color.gray.opacity(0.06))
                        .foregroundColor(isSelected ? .white : .adaptiveText)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isSelected ? Color.appPrimary : Color.gray.opacity(0.18),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(
                            color: isSelected ? Color.appPrimary.opacity(0.22) : .clear,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(!isSelected && selectedTripStyles.count >= 3 ? 0.45 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isSelected && selectedTripStyles.count >= 3)
                    .accessibilityLabel(SettingsManager.shared.currentLanguage == .thai
                                        ? "สไตล์ทริป \(category.label)"
                                        : "Trip style \(category.displayLabel)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func pickerLabel(_ text: String) -> some View {
        HStack {
            Text(text).foregroundColor(.adaptiveText)
            Spacer()
            Image(systemName: "chevron.down").foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
        .cornerRadius(12)
    }

    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tr("รายละเอียด", "Details")).font(.system(size: 11, weight: .bold)).foregroundColor(.gray)
                Spacer()
                Button(action: generateAITrip) {
                    Label(isGeneratingAI ? tr("กำลังจัดทริป...", "Planning trip…") : tr("AI ช่วยจัดทริป", "Plan with AI"), systemImage: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.appPrimary).cornerRadius(12)
                }.disabled(isGeneratingAI)
            }
            TextField(tr("ความต้องการพิเศษให้ AI (ไม่จำเป็น)", "Special requests for AI (optional)"), text: $aiPrompt)
                .padding(10).background(Color.gray.opacity(0.05)).cornerRadius(8)
            TextEditor(text: $description)
                .frame(minHeight: 120)
                .padding(8)
                .scrollContentBackground(.hidden)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
        }
    }

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("แท็ก / คีย์เวิร์ด", "Tags / Keywords")).font(.system(size: 11, weight: .bold)).foregroundColor(.gray)
            if !tags.isEmpty {
                Text(tags.map { "#\($0)" }.joined(separator: "  "))
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.appPrimary)
            }
            HStack {
                TextField(tr("เช่น ทะเล, คาเฟ่, ธรรมชาติ", "e.g. beach, cafe, nature"), text: $tagInput).onSubmit(addTag)
                Button(action: addTag) { Image(systemName: "plus.circle.fill") }
                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
        }
    }

    private var scheduleAndBudgetStep: some View {
        VStack(spacing: 20) {
            TripDateInputView(startDate: $startDate, endDate: $endDate)
            HStack(spacing: 12) {
                FormField(label: tr("งบประมาณ (บาท)", "Budget (THB)"), placeholder: tr("ระบุจำนวนเงิน", "Enter amount"), text: $budget).keyboardType(.numberPad)
                FormField(label: tr("จำนวนคน", "Participants"), placeholder: "10", text: $maxParticipants).keyboardType(.numberPad)
            }
            budgetTypePicker
            timeSlotPicker
            stepError
        }
    }

    private var budgetTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("ประเภทงบ", "Budget type")).font(.system(size: 13, weight: .semibold)).foregroundColor(.gray)
            HStack(spacing: 10) {
                choiceButton(tr("ต่อคน", "Per person"), selected: budgetType == "per_person") { budgetType = "per_person" }
                choiceButton(tr("ต่อทริป (รวม)", "Per trip (total)"), selected: budgetType == "per_trip") { budgetType = "per_trip" }
            }
        }
    }

    private func choiceButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 13, weight: .bold))
                .foregroundColor(selected ? .white : .adaptiveText)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selected ? Color.appPrimary : Color.gray.opacity(0.08)).cornerRadius(10)
        }
    }

    private var timeSlotPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("ช่วงเวลาของทริป", "Trip time preferences")).font(.system(size: 15, weight: .bold))
            ForEach(timeSlots, id: \.0) { slot in
                let selected = timeOfDay.contains(slot.0)
                Button {
                    if selected { timeOfDay.removeAll { $0 == slot.0 } } else { timeOfDay.append(slot.0) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(slot.1).font(.system(size: 14, weight: .bold))
                            Text(slot.2).font(.system(size: 12)).opacity(0.75)
                        }
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    }
                    .foregroundColor(selected ? .white : .adaptiveText)
                    .padding().background(selected ? Color.appPrimary : Color.gray.opacity(0.05)).cornerRadius(12)
                }
            }
        }
    }

    private var itineraryStep: some View {
        VStack(spacing: 20) {
            Text(tr("เพิ่มกิจกรรมแยกตามวัน ระบบจะใช้แผนนี้คำนวณจำนวนกิจกรรมเฉลี่ยต่อวัน", "Add activities by day. The system uses this plan to calculate average activities per day."))
                .font(.subheadline).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading)
            ItineraryEditorView(itinerary: $itinerary)
            stepError
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingTrip != nil
                 ? tr("ตรวจสอบก่อนบันทึก", "Review before saving")
                 : tr("ตรวจสอบก่อนสร้างทริป", "Review before creating"))
                .font(.system(size: 20, weight: .bold))
            ReviewRow(label: tr("ชื่อทริป", "Trip name"), value: title)
            ReviewRow(label: tr("สถานที่", "Location"), value: specificLocation.isEmpty ? destination : "\(destination) (\(specificLocation))")
            ReviewRow(label: tr("สไตล์ของทริป", "Trip styles"), value: selectedTripStyles.map(localizedInterestName).joined(separator: ", "))
            ReviewRow(label: tr("วันที่เริ่ม", "Start date"), value: startDate.formatted(date: .abbreviated, time: .omitted))
            ReviewRow(label: tr("วันที่สิ้นสุด", "End date"), value: endDate?.formatted(date: .abbreviated, time: .omitted) ?? tr("วันเดียว", "One day"))
            ReviewRow(label: tr("งบประมาณ", "Budget"), value: "\(budget) \(tr("บาท", "THB")) \(budgetType == "per_trip" ? tr("ต่อทริป", "per trip") : tr("ต่อคน", "per person"))")
            ReviewRow(label: tr("จำนวนผู้ร่วมทริป", "Participants"), value: "\(tr("สูงสุด", "Up to")) \(maxParticipants) \(tr("คน", "people"))")
            ReviewRow(label: tr("แผนการเดินทาง", "Itinerary"), value: "\(itinerary?.count ?? 0) \(tr("วัน", "days")) · \(itinerary?.reduce(0) { $0 + $1.activities.count } ?? 0) \(tr("กิจกรรม", "activities"))")
            stepError
        }
        .padding(18).background(Color.gray.opacity(0.05)).cornerRadius(16)
    }

    @ViewBuilder
    private var stepError: some View {
        if let errorMessage {
            Text(errorMessage).font(.system(size: 13, weight: .medium)).foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var wizardNavigation: some View {
        HStack(spacing: 12) {
            if creationStep > 0 {
                Button(tr("ย้อนกลับ", "Back")) {
                    errorMessage = nil
                    withAnimation { creationStep -= 1 }
                }
                .buttonStyle(WizardSecondaryButtonStyle())
            }
            Button {
                creationStep == 3 ? saveTrip() : advanceCreationStep()
            } label: {
                if isLoading { ProgressView().tint(.white) }
                else {
                    Text(creationStep == 3
                         ? (editingTrip != nil
                            ? SettingsManager.shared.text(thai: "บันทึกการแก้ไข", english: "Save changes")
                            : SettingsManager.shared.text(thai: "สร้างทริป", english: "Create trip"))
                         : SettingsManager.shared.text(thai: "ถัดไป", english: "Next"))
                }
            }
            .buttonStyle(WizardPrimaryButtonStyle())
            .disabled(isLoading)
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(Color.adaptiveBackground)
    }

    private func synchronizeInjectedTrip() {
        if let trip = editingTrip {
            title = trip.title; destination = trip.destination
            description = trip.description ?? ""; startDate = trip.startDate; endDate = trip.endDate
            budget = String(trip.budget); budgetType = trip.budgetType ?? "per_person"
            maxParticipants = String(trip.maxParticipants); selectedCategoryRaw = trip.category.rawValue
            additionalInterests = Array(trip.interestTags.filter { $0 != trip.category.rawValue }.prefix(2))
            isPublic = trip.isPublic; itinerary = trip.itinerary; timeOfDay = trip.timeOfDay ?? []
        } else if let draft {
            title = draft.title; destination = draft.destination; description = draft.description
            budget = String(draft.budget); budgetType = draft.budgetType ?? "per_person"
            maxParticipants = String(draft.maxParticipants); itinerary = draft.itinerary
            additionalInterests = Array((draft.interestTags ?? []).filter { $0 != draft.category }.prefix(2))
            timeOfDay = draft.timeOfDay ?? []
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation { tags.append(trimmed) }
        tagInput = ""
    }

    private func advanceCreationStep() {
        errorMessage = nil

        if creationStep == 0 {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = tr("กรุณากรอกชื่อทริปก่อนดำเนินการต่อ", "Enter a trip name to continue")
                return
            }
            guard !destination.isEmpty else {
                errorMessage = tr("กรุณาเลือกจังหวัดก่อนดำเนินการต่อ", "Select a province to continue")
                return
            }
            guard INTEREST_CATEGORIES.contains(where: { $0.label == selectedCategoryRaw }) else {
                errorMessage = tr("กรุณาเลือกสไตล์ของทริปจากรายการที่กำหนด", "Select at least one trip style")
                return
            }
        }

        if creationStep == 1 {
            guard let budgetValue = Int(budget), budgetValue >= 0 else {
                errorMessage = tr("กรุณากรอกงบประมาณที่ถูกต้อง", "Enter a valid budget")
                return
            }
            guard let participantCount = Int(maxParticipants), participantCount > 0 else {
                errorMessage = tr("กรุณากรอกจำนวนผู้ร่วมทริปที่ถูกต้อง", "Enter a valid number of participants")
                return
            }
            if let end = endDate, end < startDate {
                errorMessage = tr("วันสิ้นสุดต้องมากกว่าหรือเท่ากับวันเริ่ม", "The end date must be on or after the start date")
                return
            }
        }

        hideKeyboard()
        withAnimation(.easeInOut) { creationStep = min(creationStep + 1, 3) }
    }
    
    private func saveTrip() {
        // Validation
        guard !title.isEmpty else {
            errorMessage = tr("กรุณากรอกชื่อทริป", "Enter a trip name")
            return
        }
        
        guard !destination.isEmpty else {
            errorMessage = tr("กรุณากรอกสถานที่", "Enter a location")
            return
        }

        guard INTEREST_CATEGORIES.contains(where: { $0.label == selectedCategoryRaw }) else {
            errorMessage = tr("กรุณาเลือกสไตล์ของทริปจากรายการที่กำหนด", "Select at least one trip style")
            return
        }
        
        guard let budgetValue = Int(budget), budgetValue >= 0 else {
            errorMessage = tr("กรุณากรอกงบประมาณที่ถูกต้อง (ระบุจำนวนเงิน)", "Enter a valid budget amount")
            return
        }
        
        guard let maxPart = Int(maxParticipants), maxPart > 0 else {
            errorMessage = tr("กรุณากรอกจำนวนคนที่ถูกต้อง", "Enter a valid number of participants")
            return
        }
        
        if let end = endDate, end < startDate {
            errorMessage = tr("วันสิ้นสุดต้องมากกว่าหรือเท่ากับวันเริ่ม", "The end date must be on or after the start date")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Append tags as hashtags to description
        let tagsString = tags.isEmpty ? "" : "\n" + tags.map { "#\($0)" }.joined(separator: " ")
        let cleanDescription = description
        let fullDescription = (cleanDescription.isEmpty ? "" : cleanDescription) + tagsString
        
        let fullDestination = specificLocation.isEmpty ? destination : "\(destination) (\(specificLocation))"
        
        // Prepare images
        let base64Images = selectedImages.compactMap { img -> String? in
            guard let scaledImg = img.resized(toWidth: 800),
                  let data = scaledImg.jpegData(compressionQuality: 0.6) else { return nil }
            return "data:image/jpeg;base64,\(data.base64EncodedString())"
        }
        
        let mainImageUrl: String?
        let galleryImages: [String]?
        
        if !base64Images.isEmpty {
            // New images selected, they take precedence
            mainImageUrl = base64Images.first
            galleryImages = base64Images.count > 1 ? Array(base64Images.dropFirst()) : nil
        } else {
            // No new images selected, keep existing ones (if any)
            mainImageUrl = imageUrl.isEmpty ? nil : imageUrl
            galleryImages = editingTrip?.gallery
        }

        Task {
            do {
                if let trip = editingTrip {
                    // Update
                    _ = try await TripService.shared.updateTrip(
                        id: trip.id,
                        title: title,
                        destination: fullDestination,
                        description: fullDescription,
                        startDate: startDate,
                        endDate: endDate,
                        budget: budgetValue,
                        budgetType: budgetType,
                        maxParticipants: maxPart,
                        category: selectedCategoryRaw,
                        interestTags: additionalInterests,
                        isPublic: isPublic,
                        imageUrl: mainImageUrl,
                        gallery: galleryImages,
                        itinerary: itinerary,
                        activityStyle: Int(activityStyle),
                        timeOfDay: timeOfDay
                    )
                } else {
                    // Create
                    _ = try await TripService.shared.createTrip(
                        title: title,
                        destination: fullDestination,
                        description: fullDescription,
                        startDate: startDate,
                        endDate: endDate,
                        budget: budgetValue,
                        budgetType: budgetType,
                        maxParticipants: maxPart,
                        category: selectedCategoryRaw,
                        interestTags: additionalInterests,
                        isPublic: isPublic,
                        imageUrl: mainImageUrl,
                        gallery: galleryImages,
                        itinerary: itinerary,
                        activityStyle: Int(activityStyle),
                        timeOfDay: timeOfDay
                    )
                }
                
                NotificationCenter.default.post(name: NSNotification.Name("TripCreated"), object: nil)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deleteTrip() {
        guard let tripId = editingTrip?.id else { return }
        isLoading = true
        
        Task {
            do {
                try await TripService.shared.deleteTrip(id: tripId)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "\(tr("ไม่สามารถลบทริปได้", "Unable to delete trip")): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - AI Generate Trip
    private func generateAITrip() {
        guard !destination.isEmpty || !title.isEmpty else {
            errorMessage = tr("กรุณากรอกชื่อทริปหรือสถานที่ก่อนให้ AI ช่วยจัด", "Enter a trip name or location before using AI planning")
            return
        }
        
        isGeneratingAI = true
        errorMessage = nil
        
        // Ensure budget is valid integer for JSON
        let budgetValue = Int(budget) ?? 0
        
        let totalDays: Int = {
            if let end = endDate {
                let d = Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? 0
                return max(1, d + 1)
            }
            return 1
        }()
        
        let prompt = """
        คุณเป็นนักวางแผนการเดินทางมืออาชีพ ช่วยเติมข้อมูลและจัดแผนทริปนี้ให้พร้อมใช้งาน

        ข้อมูลที่ผู้ใช้กำหนด (ต้องรักษาเงื่อนไขเหล่านี้):
        - ชื่อทริปปัจจุบัน: \(title.isEmpty ? "ยังไม่ได้ระบุ" : title)
        - จุดหมาย: \(destination.isEmpty ? "ยังไม่ได้ระบุ" : destination) \(specificLocation.isEmpty ? "" : "สถานที่เจาะจง: \(specificLocation)")
        - วันเริ่ม: \(startDate.formatted(.iso8601.year().month().day()))
        - วันสิ้นสุด: \((endDate ?? startDate).formatted(.iso8601.year().month().day()))
        - จำนวนวันทั้งหมด: \(totalDays) วัน
        - จำนวนคนสูงสุด: \(maxParticipants)
        - งบประมาณ: \(budgetValue == 0 ? "ไม่ได้ระบุ" : "\(budgetValue) บาท") (\(budgetType == "per_trip" ? "ต่อทริป" : "ต่อคน"))
        - หมวดหมู่: \(selectedCategoryRaw)
        - ความชอบเพิ่มเติม: \(additionalInterests.isEmpty ? "ไม่ได้เลือก" : additionalInterests.joined(separator: ", "))
        - ช่วงเวลาที่เลือก: \(timeOfDay.isEmpty ? "ไม่ได้จำกัด" : timeOfDay.joined(separator: ", "))
        - รายละเอียดเดิม: \(description.isEmpty ? "ยังไม่มี" : description)
        \(aiPrompt.isEmpty ? "" : "- คำขอพิเศษที่ต้องปฏิบัติตาม: \(aiPrompt)")

        กฎการวางแผน:
        1. itinerary ต้องมี \(totalDays) รายการพอดี โดย day เรียง 1 ถึง \(totalDays) ห้ามขาดหรือเกิน
        2. ทุกวันต้องมีกิจกรรมอย่างน้อย 1 รายการ เวลาเรียงจากน้อยไปมากและไม่ซ้อนกัน
        3. เผื่อเวลาเดินทาง พัก และรับประทานอาหาร สถานที่ในวันเดียวกันต้องอยู่ใกล้กันและเดินทางได้จริง
        4. วันแรกคำนึงถึงการเดินทางมาถึง/เช็กอิน วันสุดท้ายคำนึงถึงเช็กเอาต์/เดินทางกลับ
        5. จำนวนกิจกรรมต้องเหมาะกับจำนวนวัน งบประมาณ และช่วงเวลาที่ผู้ใช้เลือก ไม่อัดกิจกรรมมากเกินไป
        6. description เขียนสั้น 2–3 ประโยคในมุมเจ้าของทริปที่ชวนเพื่อนไปเที่ยว ห้ามกล่าวถึง AI
        7. ห้ามสร้างชื่อสถานที่หรือข้อเท็จจริงเฉพาะที่ไม่มั่นใจ และห้ามใช้อีโมจิ
        8. category ต้องเป็นหนึ่งในรายการนี้เท่านั้น: ทะเล, ภูเขา, แคมป์ปิ้ง, ผจญภัย, เที่ยวเมือง, คาเฟ่, อาหาร, ช้อปปิ้ง, ถ่ายรูป, คอนเสิร์ต, แฮงเอาต์, ไหว้พระ ห้ามใช้คำว่าอื่นๆ และห้ามสร้างหมวดหมู่ใหม่
        9. interestTags เลือกได้ไม่เกิน 2 รายการจากรายการเดียวกับ category ห้ามซ้ำกับ category และต้องสัมพันธ์กับ itinerary จริง
        10. ตอบ JSON เพียงก้อนเดียว ห้าม Markdown และห้ามข้อความอื่น

        JSON schema ที่ต้องตอบ:
        { 
          "title": "...", 
          "destination": "...", 
          "description": "...", 
          "tags": ["..."], 
          "category": "...",
          "interestTags": ["..."],
          "activityStyle": 3,
          "timeOfDay": ["morning", "noon"],
          "itinerary": [
            {
              "day": 1,
              "activities": [
                { "time": "09:00", "name": "...", "location": "...", "description": "..." }
              ]
            }
          ]
        }
        - activityStyle คือจำนวนกิจกรรมเฉลี่ยต่อวันจริง คำนวณจากจำนวนกิจกรรมทั้งหมดหารด้วยจำนวนวัน แล้วปัดเป็นจำนวนเต็มอย่างน้อย 1
        - timeOfDay: เลือกเวลาที่เหมาะสมกับทริปจาก array นี้เท่านั้น: ["morning", "noon", "evening", "night"] (เลือกได้หลายช่วงเวลา)
        """
        
        Task {
            do {
                let jsonString = try await GeminiService.shared.chat(message: prompt, history: [], responseJSON: true)
                // Clean markdown if AI sends it
                let cleanJson = jsonString
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let data = cleanJson.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        guard let itinData = dict["itinerary"] as? [[String: Any]],
                              let itineraryData = try? JSONSerialization.data(withJSONObject: itinData),
                              let decodedItinerary = try? JSONDecoder().decode([DayPlan].self, from: itineraryData) else {
                            self.errorMessage = tr("AI ส่งแผนการเดินทางไม่ถูกต้อง กรุณาลองอีกครั้ง", "AI returned an invalid itinerary. Please try again.")
                            self.isGeneratingAI = false
                            return
                        }

                        let normalized = decodedItinerary.sorted { $0.day < $1.day }
                        let hasEveryDay = normalized.count == totalDays
                            && normalized.enumerated().allSatisfy { entry in
                                entry.element.day == entry.offset + 1 && !entry.element.activities.isEmpty
                            }
                        guard hasEveryDay else {
                            self.errorMessage = SettingsManager.shared.currentLanguage == .thai
                                ? "AI สร้างแผนไม่ครบ \(totalDays) วัน กรุณากดให้ AI จัดทริปอีกครั้ง"
                                : "AI did not create all \(totalDays) days. Please generate the itinerary again."
                            self.isGeneratingAI = false
                            return
                        }

                        if let t = dict["title"] as? String, title.isEmpty { self.title = t }
                        if let d = dict["destination"] as? String, destination.isEmpty { self.destination = d }
                        if let desc = dict["description"] as? String { self.description = desc }
                        if let c = dict["category"] as? String,
                           INTEREST_CATEGORIES.contains(where: { $0.label == c }) {
                            self.selectedCategoryRaw = c
                        }
                        if let extraInterests = dict["interestTags"] as? [String] {
                            self.additionalInterests = Array(
                                extraInterests
                                    .filter { interest in
                                        interest != self.selectedCategoryRaw
                                            && INTEREST_CATEGORIES.contains(where: { $0.label == interest })
                                    }
                                    .reduce(into: [String]()) { result, interest in
                                        if !result.contains(interest) { result.append(interest) }
                                    }
                                    .prefix(2)
                            )
                        }
                        if let tTags = dict["tags"] as? [String] {
                            for tag in tTags {
                                if !self.tags.contains(tag) { self.tags.append(tag) }
                            }
                        }
                        self.itinerary = normalized
                        if let actStyle = dict["activityStyle"] as? Int {
                            self.activityStyle = Double(actStyle)
                        }
                        if let timeArr = dict["timeOfDay"] as? [String] {
                            self.timeOfDay = timeArr
                        }
                        self.isGeneratingAI = false
                    }
                } else {
                    await MainActor.run {
                        self.description = cleanJson // Fallback to raw text
                        self.isGeneratingAI = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = tr("ไม่สามารถเชื่อมต่อ AI ได้ กรุณาลองใหม่", "Unable to connect to AI. Please try again.")
                    self.isGeneratingAI = false
                }
            }
        }
    }
}

private struct ReviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 105, alignment: .leading)
            Text(value.isEmpty ? tr("ไม่ระบุ", "Not specified") : value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.adaptiveText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct WizardPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.appPrimary.opacity(configuration.isPressed ? 0.75 : 1))
            .cornerRadius(12)
    }
}

private struct WizardSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.adaptiveText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(configuration.isPressed ? 0.18 : 0.1))
            .cornerRadius(12)
    }
}

let thaiProvinces = [
    "เชียงราย", "เชียงใหม่", "น่าน", "พะเยา", "แพร่", "แม่ฮ่องสอน", "ลำปาง", "ลำพูน", "อุตรดิตถ์",
    "กาฬสินธุ์", "ขอนแก่น", "ชัยภูมิ", "นครพนม", "นครราชสีมา", "บึงกาฬ", "บุรีรัมย์", "มหาสารคาม",
    "มุกดาหาร", "ยโสธร", "ร้อยเอ็ด", "เลย", "ศรีสะเกษ", "สกลนคร", "สุรินทร์", "หนองคาย", "หนองบัวลำภู",
    "อำนาจเจริญ", "อุดรธานี", "อุบลราชธานี",
    "กำแพงเพชร", "ชัยนาท", "นครนายก", "นครปฐม", "นครสวรรค์", "นนทบุรี", "ปทุมธานี", "พระนครศรีอยุธยา",
    "พิจิตร", "พิษณุโลก", "เพชรบูรณ์", "ลพบุรี", "สมุทรปราการ", "สมุทรสงคราม", "สมุทรสาคร", "สระบุรี",
    "สิงห์บุรี", "สุโขทัย", "สุพรรณบุรี", "อ่างทอง", "อุทัยธานี", "กรุงเทพมหานคร",
    "จันทบุรี", "ฉะเชิงเทรา", "ชลบุรี", "ตราด", "ปราจีนบุรี", "ระยอง", "สระแก้ว",
    "กาญจนบุรี", "ตาก", "ประจวบคีรีขันธ์", "เพชรบุรี", "ราชบุรี",
    "กระบี่", "ชุมพร", "ตรัง", "นครศรีธรรมราช", "นราธิวาส", "ปัตตานี", "พังงา", "พัทลุง", "ภูเก็ต",
    "ยะลา", "ระนอง", "สงขลา", "สตูล"
].sorted()

// MARK: - Identifiable image wrapper
struct CreateTripImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Multi-Image Picker Subview
struct TripMultiImagePickerView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Binding var selectedImages: [UIImage]
    @Binding var imageUrl: String
    var existingUrls: [String] = []
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var displayImages: [CreateTripImageItem] = []
    @State private var isFirstLoad = true
    
    // Image Cropping State
    @State private var itemToCrop: CreateTripImageItem?
    @State private var croppingIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SettingsManager.shared.text(thai: "รูปภาพ", english: "Photos"))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            // Selected images gallery
            if !displayImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(displayImages.enumerated()), id: \.element.id) { (idx, item) in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                // Crop Button (Top Left)
                                Button {
                                    itemToCrop = item
                                    croppingIndex = idx
                                } label: {
                                    Image(systemName: "crop")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                
                                // Remove button (Top Right)
                                Button {
                                    removeImage(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                               
                                // Badge for main image (Bottom Left)
                                if idx == 0 {
                                    VStack {
                                        Spacer()
                                        Text(SettingsManager.shared.text(thai: "หน้าปก", english: "Cover"))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.appPrimary)
                                            .cornerRadius(6)
                                            .padding(6)
                                    }
                                    .frame(width: 140, height: 140, alignment: .bottomLeading)
                                }
                            }
                        }
                        
                        // Add more button
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images, photoLibrary: .shared()) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                Text(SettingsManager.shared.text(thai: "เพิ่มรูป", english: "Add photo"))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 140)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                    }
                }
                .frame(height: 145)
            } else {
                // Empty state — photo picker
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images, photoLibrary: .shared()) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                            .frame(height: 60)
                        Text(SettingsManager.shared.text(thai: "เลือกรูปภาพ (ได้หลายรูป)", english: "Select photos"))
                            .font(.system(size: 14, weight: .bold))
                        Text(SettingsManager.shared.text(thai: "รูปแรกจะเป็นรูปหน้าปก", english: "The first photo will be the cover"))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gray)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                
                // Paste URL fallback
                HStack {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    TextField(SettingsManager.shared.text(thai: "หรือวาง URL รูปภาพ", english: "Or paste an image URL"), text: $imageUrl)
                        .foregroundColor(.adaptiveText)
                        .tint(.appPrimary)
                        .font(.system(size: 14))
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .onAppear {
            if isFirstLoad && !existingUrls.isEmpty {
                loadExistingImages()
                isFirstLoad = false
            }
        }
        .onChange(of: selectedItems) {
            if !selectedItems.isEmpty {
                loadImages(from: selectedItems)
            }
        }
        .sheet(item: $itemToCrop) { item in
            ImageCropperView(
                image: Binding(
                    get: { item.image },
                    set: { _ in } // Ignored since we don't bind back this way
                ),
                onCrop: { croppedImage in
                    if let index = croppingIndex {
                        updateImage(at: index, with: croppedImage)
                    }
                    itemToCrop = nil
                },
                onCancel: {
                    itemToCrop = nil
                }
            )
        }
    }
    
    private func updateImage(at index: Int, with image: UIImage) {
        guard index >= 0 && index < displayImages.count else { return }
        
        // Update display image
        let newIdentifiableImage = CreateTripImageItem(image: image)
        displayImages[index] = newIdentifiableImage
        
        // Update selectedImages (source of truth for upload)
        selectedImages = displayImages.map { $0.image }
    }
    
    private func removeImage(at index: Int) {
        guard index >= 0 && index < displayImages.count else { return }
        withAnimation {
            displayImages.remove(at: index)
            selectedImages = displayImages.map { $0.image }
            selectedItems = []
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                let newIdentifiableImages = images.map { CreateTripImageItem(image: $0) }
                displayImages.append(contentsOf: newIdentifiableImages)
                selectedImages = displayImages.map { $0.image }
                selectedItems = []
            }
        }
    }
    
    private func loadExistingImages() {
        Task {
            var loadedImages: [UIImage] = []
            for urlString in existingUrls {
                if let image = await loadExistingImage(from: urlString) {
                    loadedImages.append(image)
                }
            }
            
            await MainActor.run {
                let items = loadedImages.map { CreateTripImageItem(image: $0) }
                // Avoid duplicates if already loaded
                if displayImages.isEmpty {
                    displayImages = items
                    selectedImages = items.map { $0.image }
                }
            }
        }
    }

    private func loadExistingImage(from source: String) async -> UIImage? {
        // Trips created from the iOS app store images as data URLs. URLSession
        // cannot reliably load those, so decode their Base64 payload directly.
        if source.hasPrefix("data:image"),
           let commaIndex = source.firstIndex(of: ",") {
            let payloadStart = source.index(after: commaIndex)
            let payload = String(source[payloadStart...])
            guard let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters) else {
                return nil
            }
            return UIImage(data: data)
        }

        // Also accept a plain Base64 value for compatibility with older trips.
        if !source.hasPrefix("http"),
           let data = Data(base64Encoded: source, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            return image
        }

        guard let url = URL(string: source),
              let (data, response) = try? await URLSession.shared.data(from: url),
              ((response as? HTTPURLResponse)?.statusCode ?? 200) < 400 else {
            return nil
        }
        return UIImage(data: data)
    }
}

struct TripDateInputView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date?
    @State private var isShowingPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Start Date Button
            VStack(alignment: .leading, spacing: 8) {
                Text(tr("วันเริ่ม", "Start date"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Button(action: { isShowingPicker = true }) {
                    Text(startDate, formatter: itemFormatter)
                        .foregroundColor(.adaptiveText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
            
            // End Date Button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(tr("วันสิ้นสุด", "End date"))
                    Spacer()
                    if endDate != nil {
                        Button(action: { withAnimation { endDate = nil } }) {
                            Text(tr("ลบออก", "Remove"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
                
                Button(action: { isShowingPicker = true }) {
                    HStack {
                        if let end = endDate {
                            Text(end, formatter: itemFormatter)
                                .foregroundColor(.adaptiveText)
                        } else {
                            Text(tr("วันเดียว (ไม่มีวันกลับ)", "One day (no return date)"))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    CustomDateRangePicker(
                        startDate: Binding(
                            get: { startDate },
                            set: { if let newDate = $0 { startDate = newDate } }
                        ),
                        endDate: $endDate
                    )
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    Button(action: { isShowingPicker = false }) {
                        Text(tr("ตกลง", "OK"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appPrimary)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .navigationTitle(tr("เลือกวันเดินทางไป-กลับ", "Select travel dates"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(tr("ปิด", "Close")) { isShowingPicker = false }
                            .foregroundColor(.adaptiveText)
                    }
                }
            }
            .presentationDetents([.large, .fraction(0.7)])
        }
    }
    
    // Formatter
    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "th_TH")
        return formatter
    }
}

// MARK: - Form Field
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.adaptiveText)
                .tint(.appPrimary)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

#Preview {
    CreateTripView()
}

// MARK: - Itinerary Editor Subviews

struct ItineraryEditorView: View {
    @Binding var itinerary: [DayPlan]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(tr("แผนการเดินทางแต่ละวัน", "Daily itinerary"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
            }
            
            if let itin = itinerary, !itin.isEmpty {
                VStack(spacing: 20) {
                    ForEach(itin.indices, id: \.self) { idx in
                        DayEditorView(dayPlan: Binding(
                            get: { itin[idx] },
                            set: { if var ni = itinerary { ni[idx] = $0; itinerary = ni } }
                        ), onRemove: {
                            removeDay(at: idx)
                        })
                    }
                }
                
                Button(action: addDay) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text(tr("เพิ่มวันใหม่", "Add another day"))
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
                .padding(.top, 4)
            } else {
                Button(action: {
                    itinerary = [DayPlan(day: 1, activities: [])]
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text(tr("เริ่มสร้างแผนท่องเที่ยว", "Start building your itinerary"))
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func addDay() {
        let nextDay = (itinerary?.map { $0.day }.max() ?? 0) + 1
        if itinerary == nil {
            itinerary = [DayPlan(day: nextDay, activities: [])]
        } else {
            itinerary?.append(DayPlan(day: nextDay, activities: []))
        }
    }
    
    private func removeDay(at index: Int) {
        itinerary?.remove(at: index)
        // Re-index days
        if let count = itinerary?.count {
            for i in 0..<count {
                itinerary?[i].day = i + 1
            }
        }
    }
}

struct DayEditorView: View {
    @Binding var dayPlan: DayPlan
    var onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(SettingsManager.shared.currentLanguage == .thai ? "วันที่ \(dayPlan.day)" : "Day \(dayPlan.day)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appPrimary)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(8)
            
            VStack(spacing: 12) {
                ForEach(dayPlan.activities.indices, id: \.self) { actIdx in
                    ActivityEditorView(activity: Binding(
                        get: { dayPlan.activities[actIdx] },
                        set: { dayPlan.activities[actIdx] = $0 }
                    ), onRemove: {
                        dayPlan.activities.remove(at: actIdx)
                    })
                }
                
                Button(action: {
                    dayPlan.activities.append(Activity(time: "09:00", name: "", location: "", description: ""))
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(tr("เพิ่มกิจกรรม", "Add activity"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
            }
            .padding(.leading, 8)
        }
    }
}

struct ActivityEditorView: View {
    @Binding var activity: Activity
    var onRemove: () -> Void
    
    @State private var isShowingLocationSearch = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("09:00", text: $activity.time)
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 50)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                
                TextField(tr("ชื่อกิจกรรม", "Activity name"), text: $activity.name)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red.opacity(0.5))
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                Button(action: {
                    isShowingLocationSearch = true
                }) {
                    Text(activity.location.isEmpty ? tr("เพิ่มสถานที่ (ค้นหาได้เลย)", "Add a location") : activity.location)
                        .font(.system(size: 12))
                        .foregroundColor(activity.location.isEmpty ? .gray : .adaptiveText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.leading, 4)
            .sheet(isPresented: $isShowingLocationSearch) {
                LocationSearchView { selectedLocation in
                    activity.location = selectedLocation
                }
            }
            
            TextField(tr("เขียนรายละเอียดตรงนี้", "Enter details here"), text: $activity.description)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.leading, 4)
        }
        .padding(12)
        .background(Color.adaptiveBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
import SwiftUI
import MapKit

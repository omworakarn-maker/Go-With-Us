import SwiftUI
import PhotosUI

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var destination = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400)
    @State private var budget = ""
    @State private var maxParticipants = "10"
    @State private var selectedCategoryRaw: String = TripCategory.adventure.rawValue
    @State private var extraCategories: [String] = []
    @State private var showAddCategory = false
    @State private var newCategoryText: String = ""
    @State private var imageUrl = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isPublic = true // Default to Public
    @State private var isLoading = false
    @State private var isGeneratingAI = false
    @State private var errorMessage: String?
    @State private var tags: [String] = []
    @State private var tagInput: String = ""
    

    
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
            _maxParticipants = State(initialValue: String(draft.maxParticipants))
            
            // Date Parsing
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let start = formatter.date(from: draft.startDate) {
                _startDate = State(initialValue: start)
            }
            if let end = formatter.date(from: draft.endDate) {
                _endDate = State(initialValue: end)
            }
            
            // Category Matching
            _selectedCategoryRaw = State(initialValue: draft.category)
            
            // Tags from AI draft
            if let draftTags = draft.tags {
                _tags = State(initialValue: draftTags)
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
        _endDate = State(initialValue: trip.endDate ?? trip.startDate)
        _budget = State(initialValue: String(trip.budget))
        _maxParticipants = State(initialValue: String(trip.maxParticipants))
        _selectedCategoryRaw = State(initialValue: trip.category.rawValue)
        _imageUrl = State(initialValue: trip.imageUrl ?? "")
        _isPublic = State(initialValue: trip.isPublic)
        
        // Note: For now, we don't load current gallery URLs back into the picker (selectedImages),
        // but we handle them in saveTrip to ensure they aren't deleted.
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(editingTrip != nil ? "แก้ไขทริป" : "สร้างทริปใหม่")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.adaptiveText)
                                .tracking(-1)
                            
                            Text(editingTrip != nil ? "อัปเดตข้อมูลการเดินทางของคุณ" : "เริ่มต้นการผจญภัยของคุณ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Title
                            FormField(label: "ชื่อทริป", placeholder: "เช่น เที่ยวเชียงใหม่ 3 วัน 2 คืน", text: $title)
                            
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
                            // Tags / Keywords (Moved Up)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("แท็ก / คีย์เวิร์ด")
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
                                    TextField("เช่น ทะเล, คาเฟ่, ธรรมชาติ", text: $tagInput)
                                        .foregroundColor(.adaptiveText)
                                        .tint(.adaptiveText)
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
                            
                            // Destination (Restored)
                            FormField(label: "สถานที่", placeholder: "เช่น เชียงใหม่", text: $destination)

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("รายละเอียด")
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
                                            Text(isGeneratingAI ? "กำลังจัดทริป..." : "AI ช่วยจัดทริป")
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(
                                            LinearGradient(colors: [Color.appPrimary, Color.appSecondary], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .cornerRadius(12)
                                    }
                                    .disabled(isGeneratingAI)
                                }
                                
                                TextEditor(text: $description)
                                    .foregroundColor(.adaptiveText)
                                    .tint(.adaptiveText)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            
                            // Category (Restored)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("หมวดหมู่")
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
                                    Button("เพิ่มหมวดหมู่...") {
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
                            
                            // Visibility Toggle
                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading) {
                                    Text("สาธารณะ")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                    Text("ทุกคนสามารถเห็นทริปนี้ได้")
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
                            
                            // Dates
                            TripDateInputView(startDate: $startDate, endDate: $endDate)
                            
                            // Budget & Max Participants
                            HStack(spacing: 12) {
                                FormField(label: "งบประมาณ (บาท)", placeholder: "0 = ฟรี", text: $budget)
                                    .keyboardType(.numberPad)
                                
                                FormField(label: "จำนวนคน", placeholder: "10", text: $maxParticipants)
                                    .keyboardType(.numberPad)
                            }
                            
                            // Error Message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            // Create/Update Button
                            Button(action: saveTrip) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: editingTrip != nil ? "checkmark.circle.fill" : "plus.circle.fill")
                                        Text(editingTrip != nil ? "บันทึกการแก้ไข" : "สร้างทริป")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.adaptiveText)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                    .foregroundColor(.adaptiveText)
                }
            }
        }
        .onAppear { loadExtraCategories() }
        .sheet(isPresented: $showAddCategory) {
            NavigationView {
                VStack(spacing: 16) {
                    TextField("ชื่อหมวดหมู่ใหม่", text: $newCategoryText)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .tint(.adaptiveText)
                        .cornerRadius(8)

                    Spacer()
                }
                .padding()
                .navigationTitle("เพิ่มหมวดหมู่")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("ยกเลิก") { showAddCategory = false; newCategoryText = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("บันทึก") {
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

    // Load saved extra categories and provide add-category sheet
    private func loadExtraCategories() {
        if let data = UserDefaults.standard.array(forKey: "extra_trip_categories_v1") as? [String] {
            extraCategories = data
        }
    }

    private func saveExtraCategory(_ category: String) {
        var list = extraCategories
        if !list.contains(category) {
            list.insert(category, at: 0)
            extraCategories = list
            UserDefaults.standard.set(list, forKey: "extra_trip_categories_v1")
        }
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation { tags.append(trimmed) }
        tagInput = ""
    }
    
    private func saveTrip() {
        // Validation
        guard !title.isEmpty else {
            errorMessage = "กรุณากรอกชื่อทริป"
            return
        }
        
        guard !destination.isEmpty else {
            errorMessage = "กรุณากรอกสถานที่"
            return
        }
        
        guard let budgetValue = Int(budget), budgetValue >= 0 else {
            errorMessage = "กรุณากรอกงบประมาณที่ถูกต้อง (0 = ฟรี)"
            return
        }
        
        guard let maxPart = Int(maxParticipants), maxPart > 0 else {
            errorMessage = "กรุณากรอกจำนวนคนที่ถูกต้อง"
            return
        }
        
        guard endDate >= startDate else {
            errorMessage = "วันสิ้นสุดต้องมากกว่าหรือเท่ากับวันเริ่ม"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Append tags as hashtags to description
        let tagsString = tags.isEmpty ? "" : "\n" + tags.map { "#\($0)" }.joined(separator: " ")
        let fullDescription = (description.isEmpty ? "ไม่มีรายละเอียด" : description) + tagsString
        
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
                        destination: destination,
                        description: fullDescription,
                        startDate: startDate,
                        endDate: endDate,
                        budget: budgetValue,
                        maxParticipants: maxPart,
                        category: selectedCategoryRaw,
                        isPublic: isPublic,
                        imageUrl: mainImageUrl,
                        gallery: galleryImages
                    )
                } else {
                    // Create
                    _ = try await TripService.shared.createTrip(
                        title: title,
                        destination: destination,
                        description: fullDescription,
                        startDate: startDate,
                        endDate: endDate,
                        budget: budgetValue,
                        maxParticipants: maxPart,
                        category: selectedCategoryRaw,
                        isPublic: isPublic,
                        imageUrl: mainImageUrl,
                        gallery: galleryImages
                    )
                }
                
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    // MARK: - AI Generate Trip
    private func generateAITrip() {
        guard !destination.isEmpty || !title.isEmpty else {
            errorMessage = "กรุณากรอกชื่อทริปหรือสถานที่ก่อนให้ AI ช่วยจัด"
            return
        }
        
        isGeneratingAI = true
        errorMessage = nil
        
        // Ensure budget is valid integer for JSON
        let budgetValue = Int(budget) ?? 0
        
        let prompt = """
        ช่วยร่างทริปสำหรับ \(destination.isEmpty ? title : destination)
        หัวข้อ: \(title)
        จำนวนคน: \(maxParticipants)
        งบประมาณ: \(budgetValue == 0 ? "ไม่ได้ระบุ" : "\(budgetValue) บาท")
        ตอบกลับเป็น JSON format ตามโครงสร้างนี้ ห้ามใส่ Markdown block เนื้อหาแบบ text/plain เท่านั้น:
        { "title": "...", "destination": "...", "description": "...", "tags": ["..."], "category": "..." }
        """
        
        Task {
            do {
                let jsonString = try await GeminiService.shared.chat(message: prompt, history: [])
                // Clean markdown if AI sends it
                let cleanJson = jsonString
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let data = cleanJson.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        if let t = dict["title"] as? String, title.isEmpty { self.title = t }
                        if let d = dict["destination"] as? String, destination.isEmpty { self.destination = d }
                        if let desc = dict["description"] as? String { self.description = desc }
                        if let c = dict["category"] as? String { self.selectedCategoryRaw = c }
                        if let tTags = dict["tags"] as? [String] {
                            for tag in tTags {
                                if !self.tags.contains(tag) { self.tags.append(tag) }
                            }
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
                    self.errorMessage = "ไม่สามารถเชื่อมต่อ AI ได้ กรุณาลองใหม่"
                    self.isGeneratingAI = false
                }
            }
        }
    }
}

// MARK: - Identifiable image wrapper
struct CreateTripImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Multi-Image Picker Subview
struct TripMultiImagePickerView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var imageUrl: String
    var existingUrls: [String] = []
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var displayImages: [CreateTripImageItem] = []
    @State private var isFirstLoad = true
    
    // Image Cropping State
    @State private var showImageCropper = false
    @State private var imageToCrop: UIImage?
    @State private var croppingIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("รูปภาพ")
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
                                    imageToCrop = item.image
                                    croppingIndex = idx
                                    showImageCropper = true
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
                                        Text("หน้าปก")
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
                                Text("เพิ่มรูป")
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
                        Text("เลือกรูปภาพ (ได้หลายรูป)")
                            .font(.system(size: 14, weight: .bold))
                        Text("รูปแรกจะเป็นรูปหน้าปก")
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
                    TextField("หรือวาง URL รูปภาพ", text: $imageUrl)
                        .foregroundColor(.adaptiveText)
                        .tint(.adaptiveText)
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
        .sheet(isPresented: $showImageCropper) {
            if let image = imageToCrop {
                ImageCropperView(image: $imageToCrop, onCrop: { croppedImage in
                    if let index = croppingIndex {
                        updateImage(at: index, with: croppedImage)
                    }
                    showImageCropper = false
                }, onCancel: {
                    showImageCropper = false
                })
            }
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
                if let url = URL(string: urlString),
                   let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
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
}

struct TripDateInputView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var isShowingPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Start Date Button
            VStack(alignment: .leading, spacing: 8) {
                Text("วันเริ่ม")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Button(action: { isShowingPicker = true }) {
                    Text(startDate, formatter: itemFormatter)
                        .foregroundColor(.black)
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
                Text("วันสิ้นสุด")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Button(action: { isShowingPicker = true }) {
                    Text(endDate, formatter: itemFormatter)
                        .foregroundColor(.black)
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
                            set: { startDate = $0 ?? Date() }
                        ),
                        endDate: Binding(
                            get: { endDate },
                            set: { endDate = $0 ?? startDate.addingTimeInterval(86400) }
                        )
                    )
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    Button(action: { isShowingPicker = false }) {
                        Text("ตกลง")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .navigationTitle("เลือกวันเดินทางไป-กลับ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("ปิด") { isShowingPicker = false }
                            .foregroundColor(.black)
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
                .tint(.adaptiveText)
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

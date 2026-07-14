sed -i '' 's/creatorId: String? = nil,/creatorId: String? = nil, page: Int = 1, limit: Int = 20,/g' native-ios/GoWithUs/Services/TripService.swift
sed -i '' 's/participantId: String? = nil/participantId: String? = nil, page: Int = 1, limit: Int = 20/g' native-ios/GoWithUs/Services/TripService.swift

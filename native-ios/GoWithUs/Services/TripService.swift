import Foundation

// MARK: - Trip Service
class TripService {
    static let shared = TripService()
    
    private init() {}
    
    // MARK: - Get All Trips
    func getAllTrips(
        type: String? = nil,
        destination: String? = nil,
        startDate: Date? = nil,
        category: TripCategory? = nil,
        creatorId: String? = nil,
        participantId: String? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> (trips: [Trip], hasMore: Bool) {
        struct PaginationInfo: Decodable {
            let page: Int
            let limit: Int
            let total: Int
            let totalPages: Int
        }
        
        struct TripsResponse: Decodable {
            let trips: [Trip]
            let pagination: PaginationInfo?
        }
        
        var queryItems: [URLQueryItem] = []
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        if let creatorId = creatorId {
            queryItems.append(URLQueryItem(name: "creatorId", value: creatorId))
        }
        if let participantId = participantId {
            queryItems.append(URLQueryItem(name: "participantId", value: participantId))
        }
        if let destination = destination {
            queryItems.append(URLQueryItem(name: "destination", value: destination))
        }
        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            queryItems.append(URLQueryItem(name: "startDate", value: formatter.string(from: startDate)))
        }
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        // Cache buster to bypass iOS aggressive caching
        queryItems.append(URLQueryItem(name: "cb", value: String(Date().timeIntervalSince1970)))
        
        let response: TripsResponse = try await APIService.shared.request(
            endpoint: "/trips",
            method: .get,
            queryItems: queryItems
        )
        
        let hasMore = (response.pagination?.page ?? 1) < (response.pagination?.totalPages ?? 1)
        return (trips: response.trips, hasMore: hasMore)
    }
    
    // MARK: - Get Trip by ID
    func getTrip(id: String) async throws -> Trip {
        struct TripResponse: Decodable {
            let trip: Trip
        }
        
        let response: TripResponse = try await APIService.shared.request(
            endpoint: "/trips/\(id)",
            method: .get
        )
        
        return response.trip
    }
    
    // MARK: - Create Trip
    func createTrip(
        title: String,
        destination: String,
        description: String,
        startDate: Date,
        endDate: Date?,
        budget: Int,
        maxParticipants: Int,
        category: String,
        isPublic: Bool = true,
        imageUrl: String? = nil,
        gallery: [String]? = nil,
        itinerary: [DayPlan]? = nil,
        activityStyle: Int? = nil,
        timeOfDay: [String]? = nil
    ) async throws -> Trip {
        struct CreateTripRequest: Encodable {
            let title: String
            let destination: String
            let description: String
            let startDate: Date
            let endDate: Date?
            let budget: Int
            let maxParticipants: Int
            let category: String
            let isPublic: Bool
            let imageUrl: String?
            let gallery: [String]?
            let itinerary: [DayPlan]?
            let activityStyle: Int?
            let timeOfDay: [String]?
        }
        
        struct CreateTripResponse: Decodable {
            let message: String
            let trip: Trip
        }
        
        let request = CreateTripRequest(
            title: title,
            destination: destination,
            description: description,
            startDate: startDate,
            endDate: endDate,
            budget: budget,
            maxParticipants: maxParticipants,
            category: category,
            isPublic: isPublic,
            imageUrl: imageUrl,
            gallery: gallery,
            itinerary: itinerary,
            activityStyle: activityStyle,
            timeOfDay: timeOfDay
        )
        
        let response: CreateTripResponse = try await APIService.shared.request(
            endpoint: "/trips",
            method: .post,
            body: request
        )
        
        return response.trip
    }
    
    // MARK: - Update Trip
    func updateTrip(
        id: String,
        title: String,
        destination: String,
        description: String,
        startDate: Date,
        endDate: Date?,
        budget: Int,
        maxParticipants: Int,
        category: String,
        isPublic: Bool? = nil,
        imageUrl: String? = nil,
        gallery: [String]? = nil,
        itinerary: [DayPlan]? = nil,
        activityStyle: Int? = nil,
        timeOfDay: [String]? = nil
    ) async throws -> Trip {
        struct UpdateTripRequest: Encodable {
            let title: String
            let destination: String
            let description: String
            let startDate: Date
            let endDate: Date?
            let budget: Int
            let maxParticipants: Int
            let category: String
            let isPublic: Bool
            let imageUrl: String?
            let gallery: [String]?
            let itinerary: [DayPlan]?
            let activityStyle: Int?
            let timeOfDay: [String]?
        }
        
        let request = UpdateTripRequest(
            title: title,
            destination: destination,
            description: description,
            startDate: startDate,
            endDate: endDate,
            budget: budget,
            maxParticipants: maxParticipants,
            category: category,
            isPublic: isPublic ?? true,
            imageUrl: imageUrl,
            gallery: gallery,
            itinerary: itinerary,
            activityStyle: activityStyle,
            timeOfDay: timeOfDay
        )
        
        struct UpdateTripResponse: Decodable {
             let message: String
             let trip: Trip
        }

        let response: UpdateTripResponse = try await APIService.shared.request(
            endpoint: "/trips/\(id)",
            method: .put,
            body: request
        )
        return response.trip
    }
    
    // MARK: - Delete Trip
    func deleteTrip(id: String) async throws {
        struct MessageResponse: Decodable { let message: String }
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/trips/\(id)",
            method: .delete
        )
    }
    
    // MARK: - Join Trip
    func joinTrip(id: String, name: String, interests: [String], status: String = "going") async throws -> Trip {
        struct JoinTripRequest: Encodable {
            let name: String
            let interests: [String]
            let status: String
        }
        
        struct JoinTripResponse: Decodable {
            let message: String
            let participant: Participant
        }
        
        let request = JoinTripRequest(name: name, interests: interests, status: status)
        
        let _: JoinTripResponse = try await APIService.shared.request(
            endpoint: "/trips/\(id)/join",
            method: .post,
            body: request
        )
        
        // After joining, fetch the updated trip details
        return try await getTrip(id: id)
    }
    
    // MARK: - Leave Trip
    func leaveTrip(id: String) async throws {
        struct MessageResponse: Decodable { let message: String }
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/trips/\(id)/leave",
            method: .delete
        )
    }
    
    // MARK: - Remove Participant (Kick)
    func removeParticipant(tripId: String, userId: String) async throws {
        struct MessageResponse: Decodable { let message: String }
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/trips/\(tripId)/participants/\(userId)",
            method: .delete
        )
    }
}

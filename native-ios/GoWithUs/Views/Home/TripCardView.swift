import SwiftUI

struct TripCardView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
            if let imageUrl = trip.imageUrl, !imageUrl.isEmpty {
                CustomAsyncImage(url: imageUrl)
                    .frame(height: 200)
                    .clipped()
            } else {
                Image("sosuke")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            }
                
                // Category Badge
                Text(trip.category.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(trip.title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.black)
                    .tracking(-0.5)
                    .lineLimit(2)
                
                // Destination
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 4, height: 4)
                    
                    Text(trip.destination)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Date Range
                Text(trip.formattedDateRange)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                // Bottom Info
                HStack {
                    // Participants
                    HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(trip.currentParticipants)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.black)
                            )
                        
                        Text("/\(trip.maxParticipants)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Creator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(trip.creator.name.prefix(1)))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(trip.creator.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    TripCardView(trip: Trip(
        id: "1",
        title: "เที่ยวเชียงใหม่ 3 วัน 2 คืน",
        destination: "เชียงใหม่",
        description: "ทริปสุดชิล",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 2),
        budget: 5000,
        maxParticipants: 10,
        category: .adventure,
        creator: User(id: "1", name: "John", email: "john@example.com", role: .user),
        participants: []
    ))
    .padding()
}

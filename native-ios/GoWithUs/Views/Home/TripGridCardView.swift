import SwiftUI

struct TripGridCardView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let imageUrl = trip.imageUrl, !imageUrl.isEmpty {
                    CustomAsyncImage(url: imageUrl, contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else {
                    Image("sosuke")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                }
                
                // Category Badge (Mini)
                Text(trip.category.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.adaptiveText)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    Text(trip.destination)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(trip.formattedDateRange)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(trip.currentParticipants)/\(trip.maxParticipants)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.appPrimary)
                }
                .padding(.top, 2)
            }
            .padding(10)
        }
        .background(Color.adaptiveCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    TripGridCardView(trip: Trip(
        id: "1",
        title: "ทริปเชียงใหม่",
        destination: "เชียงใหม่",
        startDate: Date(),
        budget: 5000,
        maxParticipants: 10,
        category: .adventure,
        creator: User(id: "1", name: "John", email: "john@example.com", role: .user)
    ))
    .frame(width: 170)
    .padding()
}

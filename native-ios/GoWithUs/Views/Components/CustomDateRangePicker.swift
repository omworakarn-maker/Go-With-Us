import SwiftUI

struct CustomDateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    @State private var currentMonth: Date = Date()
    
    // Calendar config
    private let calendar = Calendar.current
    private let daysInWeek = 7
    private let weekDays = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"] // Thai weekdays
    
    var body: some View {
        VStack(spacing: 20) {
            // Header: Month, Year and Arrows
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.black)
                        .padding(8)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.black)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            
            // Weekday labels
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: daysInWeek), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            startDate: $startDate,
                            endDate: $endDate
                        )
                        .onTapGesture {
                            handleDateTapped(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func handleDateTapped(_ date: Date) {
        if startDate == nil {
            startDate = date
            endDate = nil
        } else if let start = startDate, endDate == nil {
            if date < start {
                startDate = date // Tapped before start date, so reset start date
            } else if date == start {
                // Tapped same day twice, do nothing or unset? Let's keep it.
                endDate = date
            } else {
                endDate = date // Valid range
            }
        } else {
            // Both are already set, restart selection
            startDate = date
            endDate = nil
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek?.start ?? currentMonth
        let endDate = monthInterval.end
        
        // Find starting offset
        let firstDayOfMonth = monthInterval.start
        let weekdayOffset = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        for _ in 0..<weekdayOffset {
            days.append(nil) // Empty leading cells
        }
        
        var currentDay = firstDayOfMonth
        while currentDay < endDate {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
        
        // Add trailing empty cells to align grid
        let trailingOffset = (7 - (days.count % 7)) % 7
        for _ in 0..<trailingOffset {
            days.append(nil)
        }
        
        return days
    }
}

// Separate view for the cell to handle drawing the continuous highlighting
struct DayCell: View {
    let date: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    var isStartDate: Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: start)
    }
    
    var isEndDate: Bool {
        guard let end = endDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: end)
    }
    
    var isBetween: Bool {
        guard let start = startDate, let end = endDate else { return false }
        // Ensure same day doesn't count as between if they are the exact same day
        if Calendar.current.isDate(start, inSameDayAs: end) { return false }
        return date > start && date < end
    }
    
    var body: some View {
        ZStack {
            // Connecting Background (Span highlight)
            if isBetween {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
            } else if isStartDate && endDate != nil && !Calendar.current.isDate(startDate!, inSameDayAs: endDate!) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .padding(.leading, 20) // Only cover right half
            } else if isEndDate && startDate != nil && !Calendar.current.isDate(startDate!, inSameDayAs: endDate!) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .padding(.trailing, 20) // Only cover left half
            }
            
            // The Circle selection
            if isStartDate || isEndDate {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
            }
            
            // Text Label
            Text(dayString(from: date))
                .font(.system(size: 16, weight: (isStartDate || isEndDate) ? .bold : .regular))
                .foregroundColor((isStartDate || isEndDate) ? .white : .black)
        }
        .frame(height: 40)
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

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
                        .foregroundColor(.adaptiveText)
                        .padding(8)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.adaptiveText)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.adaptiveText)
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
                ForEach(daysToDisplay(), id: \.self) { date in
                    DayCell(
                        date: date,
                        currentMonth: currentMonth,
                        startDate: $startDate,
                        endDate: $endDate
                    )
                    .onTapGesture {
                        handleDateTapped(date)
                    }
                }
            }
        }
    }
    
    private func handleDateTapped(_ date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        
        if startDate == nil || (startDate != nil && endDate != nil) {
            // Start fresh selection
            startDate = normalizedDate
            endDate = nil
        } else if let start = startDate, endDate == nil {
            let normalizedStart = calendar.startOfDay(for: start)
            if normalizedDate == normalizedStart {
                // Tapped same day again — treat as single-day trip
                endDate = normalizedStart
            } else if normalizedDate < normalizedStart {
                // Tapped earlier — swap: new start is tapped day, end is old start
                endDate = normalizedStart
                startDate = normalizedDate
            } else {
                // Valid end date after start
                endDate = normalizedDate
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func daysToDisplay() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        var days: [Date] = []
        
        // Calculate the start of the first week to display
        let firstDayOfMonth = monthInterval.start
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth) // 1 for Sunday, 7 for Saturday
        
        // Adjust for calendar's firstWeekday (e.g., Sunday=1, Monday=2)
        let daysToPrepend = (weekdayOfFirstDay - calendar.firstWeekday + daysInWeek) % daysInWeek
        
        // Get the date for the first day to display (could be from previous month)
        guard let startOfDisplay = calendar.date(byAdding: .day, value: -daysToPrepend, to: firstDayOfMonth) else { return [] }
        
        var currentDate = startOfDisplay
        // Generate 6 weeks (42 days) to ensure full calendar grid
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
}

// Separate view for the cell to handle drawing the continuous highlighting
struct DayCell: View {
    let date: Date
    let currentMonth: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    private let calendar = Calendar.current
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var isStartDate: Bool {
        guard let start = startDate else { return false }
        return calendar.isDate(date, inSameDayAs: start)
    }
    
    var isEndDate: Bool {
        guard let end = endDate else { return false }
        return calendar.isDate(date, inSameDayAs: end)
    }
    
    var isInRange: Bool {
        guard let start = startDate, let end = endDate else { return false }
        // If start and end are the same day, it's not "in range" but rather start/end
        if calendar.isDate(start, inSameDayAs: end) { return false }
        return date > start && date < end
    }
    
    var isOutsideCurrentMonth: Bool {
        !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    var body: some View {
        ZStack {
            // Range highlighting background
            if isInRange {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
            } else if isStartDate && endDate != nil && !calendar.isDate(startDate!, inSameDayAs: endDate!) {
                // Start of a multi-day range — highlight right half
                HStack(spacing: 0) {
                    Color.clear
                    Color.gray.opacity(0.15)
                }
            } else if isEndDate && startDate != nil && !calendar.isDate(startDate!, inSameDayAs: endDate!) {
                // End of a multi-day range — highlight left half
                HStack(spacing: 0) {
                    Color.gray.opacity(0.15)
                    Color.clear
                }
            }
            
            // Selection circle
            if isStartDate || isEndDate {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
            }
            
            // Text Label
            Text(dayString(from: date))
                .font(.system(size: 16, weight: (isStartDate || isEndDate) ? .bold : .regular))
                .foregroundColor(textColor)
        }
        .frame(height: 40)
    }
    
    private var textColor: Color {
        if isStartDate || isEndDate {
            return .white
        } else if isOutsideCurrentMonth {
            return Color.adaptiveText.opacity(0.3)
        } else if isToday {
            return .appPrimary
        } else {
            return .adaptiveText
        }
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

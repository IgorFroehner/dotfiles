import SwiftUI

/// The panel opened from the clock: month calendar, clock, and weather.
struct CalendarPanelView: View {
    @StateObject private var weatherController = WeatherController()

    var body: some View {
        ZStack {
            Color(Colors.panelBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                Card(
                    content: AnyView(
                        CalendarView()
                            .frame(maxWidth: .infinity)
                    ),
                    backgroundColor: Color(Colors.cardBackground),
                    padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    backgroundImage: nil
                )

                ClockView()

                WeatherView(weatherController: weatherController)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 30)
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(Colors.panelBorder), lineWidth: 1)
        )
    }
}

struct CalendarContentView: View {
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    let date: Date
    
    var body: some View {
        VStack(spacing: 12) {
            // Month and Year
            Text(date.formatted(.dateTime.month(.wide).year()))
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            
            // Week days
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12))
                        .foregroundColor(day == "S" ? Color(Colors.red) : Color.white)
                        .frame(width: 20)
                }
            }
            
            // Calendar grid
            CalendarGridView(date: date)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 15)
    }
}

// Separate grid view
struct CalendarGridView: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<6) { row in
                HStack(spacing: 8) {
                    ForEach(0..<7) { column in
                        let index = row * 7 + column
                        if index < days.count {
                            DayCell(day: days[index])
                        } else {
                            Text("")
                                .frame(width: 20)
                        }
                    }
                }
            }
        }
    }
    
    private var days: [DayItem] {
        generateDaysInMonth()
    }
    
    private func generateDaysInMonth() -> [DayItem] {
        var days: [DayItem] = []
        let calendar = Calendar.current
        
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count

        // Previous month days
        if firstWeekday > 0 {
            let startDay = max(1, daysInPreviousMonth - firstWeekday + 1)
            for day in startDay...daysInPreviousMonth {
                days.append(DayItem(number: "\(day)", isCurrentMonth: false, isToday: false))
            }
        }
        
        // Current month days
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        let currentDay = calendar.component(.day, from: date)
        
        for day in 1...daysInMonth {
            days.append(DayItem(number: "\(day)", 
                              isCurrentMonth: true, 
                              isToday: day == currentDay))
        }
        
        // Next month days
        let remainingDays = 42 - days.count
        for day in 1...remainingDays {
            days.append(DayItem(number: "\(day)", isCurrentMonth: false, isToday: false))
        }
        
        return days
    }
}

// Simplified day cell
struct DayCell: View {
    let day: DayItem
    
    var body: some View {
        Text(day.number)
            .font(.system(size: 12))
            .foregroundColor(
                day.isCurrentMonth 
                    ? (day.isToday ? .white : .white.opacity(0.7)) 
                    : .white.opacity(0.3)
            )
            .frame(width: 20)
            .fontWeight(day.isToday ? .bold : .regular)
    }
}

// Day item model
struct DayItem {
    let number: String
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct CalendarView: View {
    @State private var date: Date = Date()

    var body: some View {
        CalendarContentView(date: date)
            .onAppear(perform: fetchDate)
    }

    private func fetchDate() {
        self.date = Date()
    }
}

struct ClockView: View {
    @State private var currentTime = ""

    var body: some View {
        Card(
            content: AnyView(
                HStack {
                    // Left side - Clock icon with padding
                    Image(systemName: "clock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)

                    Spacer()

                    // Right side - Current time with padding
                    Text(currentTime)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            backgroundImage: nil
        )
        .onAppear(perform: updateTime)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTime()
        }
    }

    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
}

struct WeatherView: View {
    @ObservedObject var weatherController: WeatherController
    
    var body: some View {
        Card(
            content: AnyView(
                HStack {
                    // Left side - Weather icon
                    Image(systemName: weatherController.weatherIcon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Right side - Temperature and condition
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(weatherController.currentTemp.map { "\(Int($0))°C" } ?? "--°C")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        // Condition text
                        Text(weatherController.condition)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            backgroundImage: nil
        )
    }
}

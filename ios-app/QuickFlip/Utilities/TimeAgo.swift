import Foundation

func timeAgo(from date: Date) -> String {
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date, to: now)

    if let year = components.year, year > 0 {
        return "\(year)y ago"
    }
    if let month = components.month, month > 0 {
        return "\(month)mo ago"
    }
    if let day = components.day, day > 0 {
        return "\(day)d ago"
    }
    if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    }
    if let minute = components.minute, minute > 0 {
        return "\(minute)m ago"
    }
    if let second = components.second, second > 0 {
        return "\(second)s ago"
    }

    return "now"
}

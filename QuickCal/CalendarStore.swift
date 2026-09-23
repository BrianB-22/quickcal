import Foundation

final class CalendarStore: ObservableObject {
    @Published var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @Published var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
    @Published var rangeEnd: Date? = nil

    func resetToToday() {
        displayedMonth = Calendar.current.startOfMonth(for: Date())
        selectedDate   = Calendar.current.startOfDay(for: Date())
        rangeEnd       = nil
    }
}

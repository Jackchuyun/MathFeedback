import Foundation

extension DateFormatter {
    static let feedbackDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let feedbackMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/dd"
        return f
    }()

    static let chineseDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()
}

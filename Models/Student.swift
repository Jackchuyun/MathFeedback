import Foundation
import SwiftData

@Model
final class Student {
    var id: UUID
    var name: String
    var grade: String       // 高一 / 高二 / 高三
    var joinDate: Date
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \Feedback.student)
    var feedbacks: [Feedback] = []

    var classGroup: ClassGroup?

    init(name: String, grade: String, joinDate: Date = .now, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.joinDate = joinDate
        self.notes = notes
    }

    /// Most recent feedback, if any
    var latestFeedback: Feedback? {
        feedbacks.sorted { $0.date > $1.date }.first
    }

    /// Average overall rating across all feedbacks
    var averageRating: Double {
        guard !feedbacks.isEmpty else { return 0 }
        let total = feedbacks.reduce(0) { $0 + $1.overallRating }
        return Double(total) / Double(feedbacks.count)
    }

    /// Latest 10 feedbacks for chart display, oldest first
    var recentFeedbacks: [Feedback] {
        Array(feedbacks.sorted { $0.date < $1.date }.suffix(10))
    }

    /// Check if the student's last 2 ratings declined
    var needsAttention: Bool {
        let sorted = feedbacks.sorted { $0.date > $1.date }
        guard sorted.count >= 2 else { return false }
        return sorted[0].overallRating < sorted[1].overallRating
    }

    /// Check if the student hasn't had feedback in 30 days
    var isStale: Bool {
        guard let latest = latestFeedback else { return true }
        return Date().timeIntervalSince(latest.date) > 30 * 24 * 3600
    }

    /// Persistent weak skills (last 3 feedbacks, skill avg < 3)
    var weakSkills: [String] {
        let recent = feedbacks.sorted { $0.date > $1.date }.prefix(3)
        let allSkills = ["概念理解", "计算能力", "解题思路", "规范书写"]
        return allSkills.filter { skill in
            let scores = recent.flatMap { $0.skillScores }.filter { $0.skillName == skill }
            guard !scores.isEmpty else { return false }
            let avg = Double(scores.reduce(0) { $0 + $1.score }) / Double(scores.count)
            return avg < 3
        }
    }

    /// Trend description in natural language
    var trendDescription: String {
        let sorted = feedbacks.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return "反馈数据不足，请至少添加 2 次反馈" }
        let recent = Array(sorted.suffix(4))
        let ratings = recent.map { $0.overallRating }
        let diff = ratings.last! - ratings.first!
        if diff > 0 { return "近 \(recent.count) 次反馈总体 📈上升，表现持续进步" }
        if diff < 0 { return "近 \(recent.count) 次反馈总体 📉下降，需要更多关注" }
        return "近 \(recent.count) 次反馈总体 ➡️稳定，保持当前节奏"
    }
}

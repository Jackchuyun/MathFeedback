import SwiftData
import Foundation

/// In-memory container for SwiftUI previews, pre-loaded with sample data
@MainActor
var previewContainer: ModelContainer = {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Student.self, Feedback.self, SkillScore.self, ClassGroup.self, configurations: config)

        // Seed sample students
        let students = [
            Student(name: "李明", grade: "高二"),
            Student(name: "王小红", grade: "高一"),
            Student(name: "张伟", grade: "高三"),
        ]

        for student in students {
            container.mainContext.insert(student)

            // Generate 6 feedbacks over past 6 weeks with upward trend for Li Ming
            let isImproving = student.name == "李明"
            let isDeclining = student.name == "张伟"

            for week in 0..<6 {
                let baseRating = isImproving ? min(5, 2 + week) : (isDeclining ? max(1, 5 - week) : 3)
                let date = Calendar.current.date(byAdding: .day, value: -week * 7, to: .now)!

                let skills = [
                    SkillScore(skillName: "概念理解", score: min(5, baseRating + Int.random(in: -1...1))),
                    SkillScore(skillName: "计算能力", score: min(5, baseRating + Int.random(in: -1...1))),
                    SkillScore(skillName: "解题思路", score: min(5, baseRating + Int.random(in: -1...1))),
                    SkillScore(skillName: "规范书写", score: min(5, baseRating + Int.random(in: -1...1))),
                ]

                let topics = ["三角函数", "数列", "立体几何", "解析几何", "导数", "概率统计"]
                let feedback = Feedback(
                    date: date,
                    lessonTopic: topics[week],
                    overallRating: baseRating,
                    strengths: isDeclining ? "" : "思路清晰，计算准确",
                    weaknesses: isDeclining ? "审题粗心，概念混淆" : "规范书写可加强",
                    teacherNotes: "继续加油！",
                    homeworkCompletion: 70 + week * 5,
                    classParticipation: 75 + week * 4,
                    skillScores: skills
                )
                feedback.student = student
                container.mainContext.insert(feedback)
            }
        }

        return container
    } catch {
        fatalError("Preview container error: \(error)")
    }
}()

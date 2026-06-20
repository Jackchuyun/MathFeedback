import Foundation
import SwiftData

@Model
final class Feedback {
    var id: UUID
    var date: Date
    var lessonTopic: String          // 课时主题
    var learningContent: String      // 学习内容
    var overallRating: Int           // 综合评分 1-5
    var strengths: String            // 优点
    var weaknesses: String           // 改进点
    var teacherNotes: String         // 教师评语
    var homework: String             // 课后作业
    var homeworkCompletion: Int      // 作业完成度 0-100
    var classParticipation: Int      // 课堂参与度 0-100

    var student: Student?

    @Relationship(deleteRule: .cascade)
    var skillScores: [SkillScore] = []

    init(
        date: Date = .now,
        lessonTopic: String = "",
        learningContent: String = "",
        overallRating: Int = 3,
        strengths: String = "",
        weaknesses: String = "",
        teacherNotes: String = "",
        homework: String = "",
        homeworkCompletion: Int = 80,
        classParticipation: Int = 80,
        skillScores: [SkillScore] = SkillScore.defaultSet()
    ) {
        self.id = UUID()
        self.date = date
        self.lessonTopic = lessonTopic
        self.learningContent = learningContent
        self.overallRating = overallRating
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.teacherNotes = teacherNotes
        self.homework = homework
        self.homeworkCompletion = homeworkCompletion
        self.classParticipation = classParticipation
        self.skillScores = skillScores
    }
}

extension SkillScore {
    static func defaultSet() -> [SkillScore] {
        ["概念理解", "计算能力", "解题思路", "规范书写"].map { SkillScore(skillName: $0, score: 3) }
    }
}

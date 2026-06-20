import Foundation
import SwiftData

enum SampleDataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        do {
            let existingStudents = try context.fetch(FetchDescriptor<Student>())
            let existingClasses = try context.fetch(FetchDescriptor<ClassGroup>())
            var studentsByName: [String: Student] = [:]
            for student in existingStudents where studentsByName[student.name] == nil {
                studentsByName[student.name] = student
            }

            var classesByName: [String: ClassGroup] = [:]
            for classGroup in existingClasses where classesByName[classGroup.name] == nil {
                classesByName[classGroup.name] = classGroup
            }

            for spec in classSpecs {
                let classGroup: ClassGroup
                if let existing = classesByName[spec.className] {
                    classGroup = existing
                } else {
                    let newClass = ClassGroup(name: spec.className)
                    context.insert(newClass)
                    classesByName[spec.className] = newClass
                    classGroup = newClass
                }

                for studentName in spec.students {
                    let student: Student
                    if let existing = studentsByName[studentName] {
                        student = existing
                        student.grade = spec.grade
                        student.classGroup = classGroup
                    } else {
                        let newStudent = Student(
                            name: studentName,
                            grade: spec.grade,
                            joinDate: Calendar.current.date(byAdding: .day, value: -Int.random(in: 10...120), to: .now) ?? .now,
                            notes: "\(spec.className) 样例学生"
                        )
                        newStudent.classGroup = classGroup
                        context.insert(newStudent)
                        studentsByName[studentName] = newStudent
                        student = newStudent
                    }

                    if student.feedbacks.isEmpty {
                        context.insert(sampleFeedback(for: student))
                    }
                }
            }

            try context.save()
        } catch {
            print("Sample data seeding failed: \(error)")
        }
    }

    private static let classSpecs: [(grade: String, className: String, students: [String])] = [
        ("高一", "高一A班", ["林知夏", "周明轩"]),
        ("高一", "高一B班", ["陈若溪", "许子航"]),
        ("高二", "高二A班", ["李思远", "赵雨桐"]),
        ("高二", "高二B班", ["王嘉宁", "何星辰"]),
        ("高三", "高三A班", ["沈一诺", "黄梓涵"]),
        ("高三", "高三B班", ["刘承宇", "顾清扬"]),
    ]

    private static func sampleFeedback(for student: Student) -> Feedback {
        let topic = FeedbackGenerator.lessonTopics.randomElement() ?? "函数的概念与性质"
        let rating = Int.random(in: 3...5)
        let concept = Int.random(in: 3...5)
        let calculation = Int.random(in: 2...5)
        let reasoning = Int.random(in: 3...5)
        let writing = Int.random(in: 3...5)
        let homeworkCompletion = Int.random(in: 70...100)
        let classParticipation = Int.random(in: 70...100)
        let strength = FeedbackGenerator.strengthPhrases.randomElement() ?? "课堂专注度高，积极互动"
        let weakness = FeedbackGenerator.weaknessPhrases.randomElement() ?? "计算细节仍需加强"

        let feedback = Feedback(
            date: Calendar.current.date(byAdding: .day, value: -Int.random(in: 0...21), to: .now) ?? .now,
            lessonTopic: topic,
            learningContent: FeedbackGenerator.defaultLearningContent(for: topic),
            overallRating: rating,
            strengths: strength,
            weaknesses: weakness,
            teacherNotes: teacherNote(for: student.name, topic: topic, rating: rating),
            homework: "完成本节课错题订正，并练习 5 道同类题。",
            homeworkCompletion: homeworkCompletion,
            classParticipation: classParticipation,
            skillScores: [
                SkillScore(skillName: "概念理解", score: concept),
                SkillScore(skillName: "计算能力", score: calculation),
                SkillScore(skillName: "解题思路", score: reasoning),
                SkillScore(skillName: "规范书写", score: writing),
            ]
        )
        feedback.student = student
        return feedback
    }

    private static func teacherNote(for name: String, topic: String, rating: Int) -> String {
        if rating >= 5 {
            return "\(name) 本节 \(topic) 掌握扎实，能够主动总结关键方法，后续可增加综合题训练。"
        }
        if rating == 4 {
            return "\(name) 对 \(topic) 的主要方法掌握较好，个别计算和表达细节还可以继续打磨。"
        }
        return "\(name) 已能跟上 \(topic) 的基本思路，建议课后加强基础题巩固并及时整理错题。"
    }
}

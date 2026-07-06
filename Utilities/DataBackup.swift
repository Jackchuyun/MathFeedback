import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct DataBackup {
    /// Export all data as JSON
    static func exportAll(context: ModelContext) -> Data? {
        do {
            let students = try context.fetch(FetchDescriptor<Student>())
            let feedbacks = try context.fetch(FetchDescriptor<Feedback>())
            let classGroups = try context.fetch(FetchDescriptor<ClassGroup>())

            var json: [String: Any] = [:]
            json["schemaVersion"] = 2

            json["students"] = students.map { s in
                [
                    "id": s.id.uuidString,
                    "name": s.name, "grade": s.grade,
                    "joinDate": ISO8601DateFormatter().string(from: s.joinDate),
                    "notes": s.notes,
                    "classGroupId": s.classGroup?.id.uuidString ?? "",
                    "classGroupName": s.classGroup?.name ?? "",
                ]
            }

            json["feedbacks"] = feedbacks.map { fb in
                [
                    "id": fb.id.uuidString,
                    "studentId": fb.student?.id.uuidString ?? "",
                    "studentName": fb.student?.name ?? "",
                    "date": ISO8601DateFormatter().string(from: fb.date),
                    "lessonTopic": fb.lessonTopic,
                    "learningContent": fb.learningContent,
                    "overallRating": fb.overallRating,
                    "strengths": fb.strengths,
                    "weaknesses": fb.weaknesses,
                    "teacherNotes": fb.teacherNotes,
                    "homework": fb.homework,
                    "homeworkCompletion": fb.homeworkCompletion,
                    "classParticipation": fb.classParticipation,
                    "skills": fb.skillScores.map { ["name": $0.skillName, "score": $0.score] },
                ]
            }

            json["classGroups"] = classGroups.map { ["id": $0.id.uuidString, "name": $0.name] }

            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }

    /// Import data from JSON
    static func importAll(from data: Data, context: ModelContext) -> Bool {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            let existingClassGroups = try context.fetch(FetchDescriptor<ClassGroup>())
            let existingStudents = try context.fetch(FetchDescriptor<Student>())
            let existingFeedbacks = try context.fetch(FetchDescriptor<Feedback>())

            // Class groups first
            let classGroups = json["classGroups"] as? [[String: Any]] ?? []
            var classMap = Dictionary(uniqueKeysWithValues: existingClassGroups.map { ($0.id.uuidString, $0) })
            var classNameMap: [String: ClassGroup] = [:]
            for group in existingClassGroups where classNameMap[group.name] == nil {
                classNameMap[group.name] = group
            }
            for cg in classGroups {
                let name = cg["name"] as? String ?? ""
                if !name.isEmpty {
                    if let id = uuid(from: cg["id"]) {
                        let group = classMap[id.uuidString] ?? ClassGroup(name: name)
                        group.id = id
                        group.name = name
                        if classMap[id.uuidString] == nil {
                            context.insert(group)
                        }
                        classMap[id.uuidString] = group
                        classNameMap[name] = group
                    } else if classNameMap[name] == nil {
                        let group = ClassGroup(name: name)
                        context.insert(group)
                        classNameMap[name] = group
                    }
                }
            }

            // Students
            let students = json["students"] as? [[String: Any]] ?? []
            var studentMap = Dictionary(uniqueKeysWithValues: existingStudents.map { ($0.id.uuidString, $0) })
            var studentNameMap: [String: Student] = [:]
            for student in existingStudents where studentNameMap[student.name] == nil {
                studentNameMap[student.name] = student
            }
            let iso = ISO8601DateFormatter()
            for s in students {
                let importedId = uuid(from: s["id"])
                let name = s["name"] as? String ?? ""
                let existingStudent = importedId.flatMap { studentMap[$0.uuidString] }
                let student = existingStudent ?? Student(name: name, grade: "高一")
                let isNewStudent = existingStudent == nil
                if let id = uuid(from: s["id"]) {
                    student.id = id
                    studentMap[id.uuidString] = student
                }
                student.name = name
                student.grade = s["grade"] as? String ?? "高一"
                student.joinDate = iso.date(from: s["joinDate"] as? String ?? "") ?? .now
                student.notes = s["notes"] as? String ?? ""
                if let classId = s["classGroupId"] as? String, let cg = classMap[classId] {
                    student.classGroup = cg
                } else if let cgn = s["classGroupName"] as? String, let cg = classNameMap[cgn] {
                    student.classGroup = cg
                } else {
                    student.classGroup = nil
                }
                if isNewStudent {
                    context.insert(student)
                }
                studentNameMap[student.name] = student
            }

            // Feedbacks
            let feedbacks = json["feedbacks"] as? [[String: Any]] ?? []
            var feedbackMap = Dictionary(uniqueKeysWithValues: existingFeedbacks.map { ($0.id.uuidString, $0) })
            for fb in feedbacks {
                let student: Student?
                if let studentId = fb["studentId"] as? String {
                    student = studentMap[studentId]
                } else if let studentName = fb["studentName"] as? String {
                    student = studentNameMap[studentName]
                } else {
                    student = nil
                }
                guard let student else { continue }

                let skillsData = fb["skills"] as? [[String: Any]] ?? []
                let skills = skillsData.map { SkillScore(skillName: $0["name"] as? String ?? "", score: $0["score"] as? Int ?? 3) }

                let importedId = uuid(from: fb["id"])
                let existingFeedback = importedId.flatMap { feedbackMap[$0.uuidString] }
                let feedback = existingFeedback ?? Feedback()
                let isNewFeedback = existingFeedback == nil
                if let id = importedId {
                    feedback.id = id
                    feedbackMap[id.uuidString] = feedback
                }
                feedback.date = iso.date(from: fb["date"] as? String ?? "") ?? .now
                feedback.lessonTopic = fb["lessonTopic"] as? String ?? ""
                feedback.learningContent = fb["learningContent"] as? String ?? ""
                feedback.overallRating = fb["overallRating"] as? Int ?? 3
                feedback.strengths = fb["strengths"] as? String ?? ""
                feedback.weaknesses = fb["weaknesses"] as? String ?? ""
                feedback.teacherNotes = fb["teacherNotes"] as? String ?? ""
                feedback.homework = fb["homework"] as? String ?? ""
                feedback.homeworkCompletion = fb["homeworkCompletion"] as? Int ?? 80
                feedback.classParticipation = fb["classParticipation"] as? Int ?? 80
                for oldSkill in feedback.skillScores {
                    context.delete(oldSkill)
                }
                feedback.skillScores = skills
                if isNewFeedback {
                    context.insert(feedback)
                }
                feedback.student = student
            }

            try context.save()
            return true
        } catch {
            print("Import failed: \(error)")
            return false
        }
    }

    private static func uuid(from value: Any?) -> UUID? {
        guard let text = value as? String else { return nil }
        return UUID(uuidString: text)
    }
}

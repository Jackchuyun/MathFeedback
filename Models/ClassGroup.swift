import Foundation
import SwiftData

@Model
final class ClassGroup {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Student.classGroup)
    var students: [Student] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}

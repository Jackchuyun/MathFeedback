import Foundation
import SwiftData

@Model
final class SkillScore {
    var id: UUID
    var skillName: String   // 概念理解 / 计算能力 / 解题思路 / 规范书写
    var score: Int          // 1-5

    init(skillName: String, score: Int) {
        self.id = UUID()
        self.skillName = skillName
        self.score = score
    }
}

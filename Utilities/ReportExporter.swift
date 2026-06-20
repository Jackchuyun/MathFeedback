import SwiftUI
#if os(iOS)
import UIKit

enum ReportExporter {
    static func exportPDF(for student: Student) async -> URL? {
        let feedbacks = student.feedbacks.sorted { $0.date > $1.date }
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 56
        let contentWidth = pageWidth - margin * 2

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeFilename("\(student.name)_反馈报告.pdf"))

        let data = renderer.pdfData { ctx in
            var y: CGFloat = margin
            ctx.beginPage()

            // ── Title ──
            y += drawText("\(student.name) 学习反馈报告", x: margin, y: y, w: contentWidth, font: .boldSystemFont(ofSize: 24), color: .systemIndigo)
            y += 10
            y += drawText("年级: \(student.grade)  |  反馈次数: \(feedbacks.count)  |  平均评分: \(String(format: "%.1f", avg(for: student)))",
                          x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 12), color: .gray)
            y += 4
            y += drawText("报告生成: \(DateFormatter.feedbackDate.string(from: .now))",
                          x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 10), color: .gray)
            y += 16

            // ── Trend ──
            y += drawText("趋势总结", x: margin, y: y, w: contentWidth, font: .boldSystemFont(ofSize: 14), color: .systemIndigo)
            y += 6
            y += drawText(student.trendDescription, x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 12), color: .darkGray)
            y += 16

            // ── Skills ──
            y += drawText("技能维度一览", x: margin, y: y, w: contentWidth, font: .boldSystemFont(ofSize: 14), color: .systemIndigo)
            y += 8
            if let latest = feedbacks.first {
                for skill in latest.skillScores {
                    y += drawText("\(skill.skillName): \(skill.score)/5",
                                  x: margin + 16, y: y, w: contentWidth - 16, font: .systemFont(ofSize: 12), color: .darkGray)
                }
            }
            y += 10

            let weak = persistentWeakSkills(for: student)
            if !weak.isEmpty {
                y += drawText("持续薄弱点: \(weak.joined(separator: "、"))",
                              x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 12), color: .systemOrange)
                y += 10
            }

            // ── Feedback History ──
            ctx.beginPage()
            y = margin
            y += drawText("反馈历史记录", x: margin, y: y, w: contentWidth, font: .boldSystemFont(ofSize: 18), color: .systemIndigo)
            y += 14

            for fb in feedbacks {
                let needed: CGFloat = 80
                if y > pageHeight - margin - needed { ctx.beginPage(); y = margin }

                // Divider
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.systemIndigo.withAlphaComponent(0.2).setStroke()
                path.stroke()
                y += 10

                y += drawText("\(fb.lessonTopic)  评分: \(fb.overallRating)/5  |  作业: \(fb.homeworkCompletion)%  |  参与: \(fb.classParticipation)%",
                              x: margin, y: y, w: contentWidth, font: .boldSystemFont(ofSize: 12), color: .black)
                y += 4
                y += drawText(DateFormatter.chineseDate.string(from: fb.date),
                              x: margin + 8, y: y, w: contentWidth - 8, font: .systemFont(ofSize: 10), color: .gray)
                y += 6
                if !fb.strengths.isEmpty {
                    y += drawText("✓ \(fb.strengths)", x: margin + 8, y: y, w: contentWidth - 8, font: .systemFont(ofSize: 10), color: .darkGray)
                }
                if !fb.weaknesses.isEmpty {
                    y += drawText("△ \(fb.weaknesses)", x: margin + 8, y: y, w: contentWidth - 8, font: .systemFont(ofSize: 10), color: .darkGray)
                }
                if !fb.teacherNotes.isEmpty {
                    y += drawText("✎ \(fb.teacherNotes)", x: margin + 8, y: y, w: contentWidth - 8, font: .systemFont(ofSize: 10), color: .darkGray)
                }
                y += 6
            }

            // ── Footer ──
            ctx.beginPage()
            y = pageHeight / 2 - 20
            y += drawText("—— 报告结束 ——", x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 14), color: .gray)
            y += 6
            _ = drawText("本报告由 MathFeedback 生成  |  \(DateFormatter.feedbackDate.string(from: .now))",
                          x: margin, y: y, w: contentWidth, font: .systemFont(ofSize: 10), color: .lightGray)
        }

        try? data.write(to: url)
        return url
    }

    /// Draw text and return the height consumed (font.lineHeight + 2)
    private static func drawText(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let bounds = (text as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                                      options: options, attributes: attr, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: w, height: bounds.height), withAttributes: attr)
        return bounds.height + 2
    }

    private static func avg(for student: Student) -> Double {
        let fbs = student.feedbacks
        guard !fbs.isEmpty else { return 0 }
        return Double(fbs.reduce(0) { $0 + $1.overallRating }) / Double(fbs.count)
    }

    private static func persistentWeakSkills(for student: Student) -> [String] {
        let recent = Array(student.feedbacks.sorted { $0.date > $1.date }.prefix(3))
        return ["概念理解", "计算能力", "解题思路", "规范书写"].filter { skill in
            let scores = recent.flatMap { $0.skillScores }.filter { $0.skillName == skill }
            guard !scores.isEmpty else { return false }
            return Double(scores.reduce(0) { $0 + $1.score }) / Double(scores.count) < 3
        }
    }

    private static func safeFilename(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return raw.components(separatedBy: invalid).joined(separator: "_")
    }
}
#endif

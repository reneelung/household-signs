import Foundation

struct Sign: Codable, Identifiable {
    let id: UUID
    let boardId: UUID
    var label: String
    var emoji: String
    var stateOffLabel: String
    var stateOnLabel: String
    var active: Bool
    var lastChangedAt: Date?
    var lastChangedBy: String?
    let position: Int
    var colorIndex: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case label
        case emoji
        case stateOffLabel = "state_off_label"
        case stateOnLabel = "state_on_label"
        case active
        case lastChangedAt = "last_changed_at"
        case lastChangedBy = "last_changed_by"
        case position
        case colorIndex = "color_index"
        case createdAt = "created_at"
    }

    var currentStateLabel: String {
        active ? stateOnLabel : stateOffLabel
    }
}

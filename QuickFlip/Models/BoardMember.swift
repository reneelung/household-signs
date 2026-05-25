import Foundation

struct BoardMember: Codable, Identifiable {
    let id: UUID
    let boardId: UUID
    let userId: UUID
    let role: String // "owner" | "admin" | "member"
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

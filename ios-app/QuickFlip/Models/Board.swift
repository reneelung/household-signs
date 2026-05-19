import Foundation

struct Board: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

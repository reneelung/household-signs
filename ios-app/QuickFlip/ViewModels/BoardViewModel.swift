import Supabase
import Foundation
import Observation

private struct ProfileRow: Codable {
    let id: UUID
    let displayName: String?
    let defaultBoardId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case defaultBoardId = "default_board_id"
    }
}

private struct BoardInviteRow: Codable {
    let id: UUID
    let boardId: UUID
    let code: String
    let createdBy: UUID
    let expiresAt: Date?
    let maxUses: Int?
    let useCount: Int
    let revokedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case code
        case createdBy = "created_by"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
        case useCount = "use_count"
        case revokedAt = "revoked_at"
    }
}

struct BoardPreview: Codable {
    let boardId: UUID
    let boardName: String
    let memberCount: Int
    let signCount: Int
    let signEmojis: [String]
    let inviterName: String?

    enum CodingKeys: String, CodingKey {
        case boardId = "board_id"
        case boardName = "board_name"
        case memberCount = "member_count"
        case signCount = "sign_count"
        case signEmojis = "sign_emojis"
        case inviterName = "inviter_name"
    }
}

@Observable
class BoardViewModel {
    var boardId: UUID?
    var boardName = ""
    var boards: [Board] = []
    var boardMembers: [BoardMember] = []
    var signsByBoard: [UUID: [Sign]] = [:]
    var selectedBoard: Board?
    var showBoardModal = false
    var boardModalMode: BoardModalMode = .create
    var inputText = ""
    var setAsDefault = false
    var defaultBoardId: UUID?
    var errorMessage = ""
    var isLoading = false
    var isLoadingMembership = false

    enum BoardModalMode {
        case create
        case join
    }

    @MainActor
    func checkMembership(userId: UUID) async {
        isLoadingMembership = true
        defer { isLoadingMembership = false }

        do {
            let members: [BoardMember] = try await supabase
                .from("board_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("joined_at", ascending: false)
                .execute()
                .value

            boardMembers = members

            let boardIds = members.map { $0.boardId.uuidString }
            if !boardIds.isEmpty {
                let fetchedBoards: [Board] = try await supabase
                    .from("boards")
                    .select()
                    .in("id", values: boardIds)
                    .execute()
                    .value
                boards = fetchedBoards

                var allMembers: [BoardMember] = try await supabase
                    .from("board_members")
                    .select()
                    .in("board_id", values: boardIds)
                    .execute()
                    .value

                let userIds = Array(Set(allMembers.map { $0.userId.uuidString }))
                if !userIds.isEmpty {
                    let profiles: [ProfileRow] = try await supabase
                        .from("profiles")
                        .select()
                        .in("id", values: userIds)
                        .execute()
                        .value
                    let profilesById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
                    allMembers = allMembers.map { member in
                        var m = member
                        if let p = profilesById[member.userId] {
                            m.profile = BoardMember.Profile(displayName: p.displayName)
                        }
                        return m
                    }
                }
                boardMembers = allMembers

                let signs: [Sign] = try await supabase
                    .from("signs")
                    .select()
                    .in("board_id", values: boardIds)
                    .execute()
                    .value
                signsByBoard = Dictionary(grouping: signs, by: { $0.boardId })
            } else {
                boards = []
                signsByBoard = [:]
            }

            let ownProfile: [ProfileRow] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            defaultBoardId = ownProfile.first?.defaultBoardId
        } catch {
            errorMessage = "Failed to check board membership: \(error.localizedDescription)"
        }
    }

    func getSigns(for board: Board) -> [Sign] {
        signsByBoard[board.id] ?? []
    }

    @MainActor
    func selectBoard(_ board: Board) {
        boardId = board.id
        boardName = board.name
    }

    @MainActor
    private func loadBoardName(for id: UUID) async {
        do {
            let boards: [Board] = try await supabase
                .from("boards")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value

            if let board = boards.first {
                boardName = board.name
            }
        } catch {
            errorMessage = "Failed to load board name: \(error.localizedDescription)"
        }
    }

    @MainActor
    func createBoard() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await supabase
                .rpc("create_board", params: ["board_name": inputText])
                .execute()
                .data

            if let idString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"\n")),
               let id = UUID(uuidString: idString) {
                boardId = id
                boardName = inputText
                showBoardModal = false
                inputText = ""

                if setAsDefault {
                    do {
                        try await persistDefaultBoard(id)
                        defaultBoardId = id
                    } catch {
                        errorMessage = "Created group but could not set as default: \(error.localizedDescription)"
                    }
                }
                setAsDefault = false

                if let userId = supabase.auth.currentUser?.id {
                    await checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
                }
            } else {
                errorMessage = "Invalid response: \(String(data: data, encoding: .utf8) ?? "unknown")"
            }
        } catch {
            errorMessage = "Failed to create board: \(error.localizedDescription)"
        }
    }

    @MainActor
    func joinBoard() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await supabase
                .rpc("join_board", params: ["invite_code": inputText.uppercased()])
                .execute()
                .data

            if let idString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"\n")),
               let id = UUID(uuidString: idString) {
                boardId = id
                await loadBoardName(for: id)
                showBoardModal = false
                inputText = ""

                if let userId = supabase.auth.currentUser?.id {
                    await checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
                }
            } else {
                errorMessage = "Invalid response: \(String(data: data, encoding: .utf8) ?? "unknown")"
            }
        } catch {
            errorMessage = "Failed to join board: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteBoard(_ board: Board) async {
        errorMessage = ""

        let removedMembers = boardMembers.filter { $0.boardId == board.id }
        let removedSigns = signsByBoard[board.id]
        boards.removeAll { $0.id == board.id }
        boardMembers.removeAll { $0.boardId == board.id }
        signsByBoard[board.id] = nil
        if selectedBoard?.id == board.id { selectedBoard = nil }

        do {
            try await supabase
                .from("boards")
                .delete()
                .eq("id", value: board.id.uuidString)
                .execute()
        } catch {
            errorMessage = "Failed to delete board: \(error.localizedDescription)"
            boards.append(board)
            boardMembers.append(contentsOf: removedMembers)
            if let removedSigns { signsByBoard[board.id] = removedSigns }
        }
    }

    @MainActor
    func togglePin(_ board: Board) async {
        let newPinnedState = !board.isPinned
        if let index = boards.firstIndex(where: { $0.id == board.id }) {
            boards[index].isPinned = newPinnedState
        }

        do {
            try await supabase
                .from("boards")
                .update(["is_pinned": newPinnedState])
                .eq("id", value: board.id.uuidString)
                .execute()
        } catch {
            errorMessage = "Failed to toggle pin: \(error.localizedDescription)"
            if let index = boards.firstIndex(where: { $0.id == board.id }) {
                boards[index].isPinned = !newPinnedState
            }
        }
    }

    @MainActor
    func leave(_ board: Board) async {
        errorMessage = ""
        guard let userId = supabase.auth.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }

        let removedMembers = boardMembers.filter { $0.boardId == board.id }
        let removedSigns = signsByBoard[board.id]
        boards.removeAll { $0.id == board.id }
        boardMembers.removeAll { $0.boardId == board.id }
        signsByBoard[board.id] = nil
        if selectedBoard?.id == board.id { selectedBoard = nil }

        do {
            try await supabase
                .from("board_members")
                .delete()
                .eq("board_id", value: board.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            errorMessage = "Failed to leave board: \(error.localizedDescription)"
            boards.append(board)
            boardMembers.append(contentsOf: removedMembers)
            if let removedSigns { signsByBoard[board.id] = removedSigns }
        }
    }

    func resetModal() {
        boardModalMode = .create
        inputText = ""
        errorMessage = ""
    }

    func getUserRole(for board: Board) -> String? {
        guard let currentUserId = supabase.auth.currentUser?.id else { return nil }
        return boardMembers.first {
            $0.boardId == board.id && $0.userId == currentUserId
        }?.role
    }

    func isOwner(of board: Board) -> Bool {
        getUserRole(for: board) == "owner"
    }

    func getMembers(for board: Board) -> [BoardMember] {
        boardMembers.filter { $0.boardId == board.id }
    }

    func isDefault(_ board: Board) -> Bool {
        defaultBoardId == board.id
    }

    @MainActor
    func setDefaultBoard(_ id: UUID?) async {
        let previous = defaultBoardId
        defaultBoardId = id
        do {
            try await persistDefaultBoard(id)
        } catch {
            defaultBoardId = previous
            errorMessage = "Failed to set default group: \(error.localizedDescription)"
        }
    }

    private func persistDefaultBoard(_ id: UUID?) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        try await supabase
            .from("profiles")
            .update(["default_board_id": id?.uuidString])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Invites

    private static let inviteHost = "quickflip-app.reneelung.workers.dev"

    func inviteURL(for code: String) -> URL {
        URL(string: "https://\(Self.inviteHost)/join/\(code)")!
    }

    @MainActor
    func activeInviteCode(for board: Board) async throws -> String {
        let now = ISO8601DateFormatter().string(from: Date())
        let existing: [BoardInviteRow] = try await supabase
            .from("board_invites")
            .select()
            .eq("board_id", value: board.id.uuidString)
            .is("revoked_at", value: nil)
            .or("expires_at.is.null,expires_at.gt.\(now)")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        if let row = existing.first {
            return row.code
        }
        return try await createInviteCode(boardID: board.id)
    }

    @MainActor
    func resetInviteCode(for board: Board) async throws -> String {
        let now = ISO8601DateFormatter().string(from: Date())
        try await supabase
            .from("board_invites")
            .update(["revoked_at": now])
            .eq("board_id", value: board.id.uuidString)
            .is("revoked_at", value: nil)
            .execute()
        return try await createInviteCode(boardID: board.id)
    }

    @MainActor
    func join(inviteCode: String) async throws -> UUID {
        let data = try await supabase
            .rpc("join_board", params: ["invite_code": inviteCode])
            .execute()
            .data

        let trimmed = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"\n")) ?? ""
        guard let id = UUID(uuidString: trimmed) else {
            throw NSError(domain: "BoardViewModel", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response from join_board"
            ])
        }

        if let userId = supabase.auth.currentUser?.id {
            await checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
        }
        return id
    }

    @MainActor
    func fetchBoardPreview(inviteCode: String) async throws -> BoardPreview {
        let data = try await supabase
            .rpc("get_invite_preview", params: ["invite_code": inviteCode])
            .execute()
            .data

        let decoder = JSONDecoder()
        if let preview = try? decoder.decode(BoardPreview.self, from: data) {
            return preview
        }

        throw NSError(domain: "BoardViewModel", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "This invite link is no longer valid."
        ])
    }

    @MainActor
    private func createInviteCode(boardID: UUID) async throws -> String {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "BoardViewModel", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Not authenticated"
            ])
        }

        for _ in 0..<5 {
            let code = Self.generateInviteCode()
            do {
                try await supabase
                    .from("board_invites")
                    .insert([
                        "board_id": boardID.uuidString,
                        "code": code,
                        "created_by": userId.uuidString
                    ])
                    .execute()
                return code
            } catch {
                let message = error.localizedDescription.lowercased()
                if !message.contains("duplicate") && !message.contains("unique") {
                    throw error
                }
            }
        }
        throw NSError(domain: "BoardViewModel", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "Could not generate a unique invite code."
        ])
    }

    private static func generateInviteCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

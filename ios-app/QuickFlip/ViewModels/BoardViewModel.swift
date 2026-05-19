import Supabase
import Foundation
import Observation

@Observable
class BoardViewModel {
    var boardId: UUID?
    var boardName = ""
    var boards: [Board] = []
    var boardMembers: [BoardMember] = []
    var showBoardModal = false
    var boardModalMode: BoardModalMode = .create
    var inputText = ""
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
            } else {
                boards = []
            }
        } catch {
            errorMessage = "Failed to check board membership: \(error.localizedDescription)"
        }
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

    func resetModal() {
        boardModalMode = .create
        inputText = ""
        errorMessage = ""
    }
}

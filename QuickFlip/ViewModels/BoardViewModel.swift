import Supabase
import Foundation
import Observation

@Observable
class BoardViewModel {
    var boardId: UUID?
    var boardName = ""
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
                .limit(1)
                .execute()
                .value

            if let member = members.first {
                boardId = member.boardId
                await loadBoardName(for: member.boardId)
            }
        } catch {
            errorMessage = "Failed to check board membership: \(error.localizedDescription)"
        }
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
            let result: UUID = try await supabase
                .rpc("create_board", params: ["board_name": inputText])
                .execute()
                .value

            boardId = result
            boardName = inputText
            showBoardModal = false
            inputText = ""
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
            let result: UUID = try await supabase
                .rpc("join_board", params: ["invite_code": inputText.uppercased()])
                .execute()
                .value

            boardId = result
            await loadBoardName(for: result)
            showBoardModal = false
            inputText = ""
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

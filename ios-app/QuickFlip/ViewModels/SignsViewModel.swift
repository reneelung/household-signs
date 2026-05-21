import Supabase
import Foundation
import Observation

@Observable
class SignsViewModel {
    var signs: [Sign] = []
    var isLoading = false
    var errorMessage = ""
    var showAddModal = false
    private var realtimeChannel: RealtimeChannelV2?
    private var boardId: UUID?

    @MainActor
    func loadSigns(for boardId: UUID) async {
        self.boardId = boardId
        isLoading = true
        defer { isLoading = false }

        do {
            let response: [Sign] = try await supabase
                .from("signs")
                .select()
                .eq("board_id", value: boardId.uuidString)
                .order("position", ascending: true)
                .execute()
                .value

            signs = response
            await setupRealtimeSubscription(for: boardId)
        } catch {
            errorMessage = "Failed to load signs: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func setupRealtimeSubscription(for boardId: UUID) async {
        let channel = supabase.channel("signs-\(boardId.uuidString)")
        realtimeChannel = channel

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "signs",
            filter: "board_id=eq.\(boardId.uuidString)"
        )

        await channel.subscribe()

        Task { @MainActor in
            for await change in changes {
                await handleRealtimeChange(change)
            }
        }
    }

    @MainActor
    private func handleRealtimeChange(_ change: AnyAction) async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        switch change {
        case .insert(let action):
            if let sign = try? decoder.decode(Sign.self, from: JSONEncoder().encode(action.record)) {
                signs.append(sign)
                signs.sort { $0.position < $1.position }
            }
        case .update(let action):
            if let sign = try? decoder.decode(Sign.self, from: JSONEncoder().encode(action.record)) {
                if let index = signs.firstIndex(where: { $0.id == sign.id }) {
                    signs[index] = sign
                }
            }
        case .delete(let action):
            if let idString = action.oldRecord["id"]?.stringValue,
               let id = UUID(uuidString: idString) {
                signs.removeAll { $0.id == id }
            }
        }
    }

    @MainActor
    func toggleSign(_ sign: Sign, userNickname: String) async {
        let newState = !sign.active

        if let index = signs.firstIndex(where: { $0.id == sign.id }) {
            signs[index].active = newState
            signs[index].lastChangedBy = userNickname
            signs[index].lastChangedAt = Date()
        }

        Task {
            do {
                let formatter = ISO8601DateFormatter()
                let activeValue = newState ? "1" : "0"
                async let updateSign = supabase
                    .from("signs")
                    .update([
                        "active": activeValue,
                        "last_changed_at": formatter.string(from: Date()),
                        "last_changed_by": userNickname
                    ])
                    .eq("id", value: sign.id.uuidString)
                    .execute()

                async let logFlip = supabase
                    .from("sign_flips")
                    .insert([
                        "sign_id": sign.id.uuidString,
                        "board_id": sign.boardId.uuidString,
                        "to_state": activeValue,
                        "flipped_by": userNickname
                    ])
                    .execute()

                _ = try await (updateSign, logFlip)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to toggle sign: \(error.localizedDescription)"
                }
            }
        }
    }

    @MainActor
    func addSign(label: String, emoji: String, stateOffLabel: String, stateOnLabel: String) async {
        guard let boardId = boardId else { return }
        errorMessage = ""

        do {
            let position = (signs.map(\.position).max() ?? 0) + 1

            try await supabase
                .from("signs")
                .insert([
                    "board_id": boardId.uuidString,
                    "label": label,
                    "emoji": emoji,
                    "state_off_label": stateOffLabel,
                    "state_on_label": stateOnLabel,
                    "position": String(position)
                ])
                .execute()

            showAddModal = false
        } catch {
            errorMessage = "Failed to add sign: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteSign(_ sign: Sign) async {
        errorMessage = ""
        do {
            try await supabase
                .from("signs")
                .delete()
                .eq("id", value: sign.id.uuidString)
                .execute()
        } catch {
            errorMessage = "Failed to delete sign: \(error.localizedDescription)"
        }
    }

    func cleanup() {
        Task {
            await realtimeChannel?.unsubscribe()
        }
    }

    deinit {
        cleanup()
    }
}

import Foundation

struct OfflineOperation: Codable {
    let id: UUID
    let type: String
    let data: Data
    let createdAt: Date
}

actor OfflineOperationQueue {
    static let shared = OfflineOperationQueue()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        fileURL = caches.appendingPathComponent("com.classroomapp.offline_queue.json")
    }

    private func loadAll() -> [OfflineOperation] {
        guard let data = try? Data(contentsOf: fileURL),
              let ops = try? decoder.decode([OfflineOperation].self, from: data) else {
            return []
        }
        return ops
    }

    private func saveAll(_ ops: [OfflineOperation]) {
        guard let data = try? encoder.encode(ops) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func enqueue(type: String, data: Data) {
        let operation = OfflineOperation(id: UUID(), type: type, data: data, createdAt: Date())
        var ops = loadAll()
        ops.append(operation)
        saveAll(ops)
    }

    func dequeueAll() -> [OfflineOperation] {
        let ops = loadAll()
        saveAll([])
        return ops
    }

    var isEmpty: Bool {
        loadAll().isEmpty
    }

    var count: Int {
        loadAll().count
    }

    func clear() {
        saveAll([])
    }
}

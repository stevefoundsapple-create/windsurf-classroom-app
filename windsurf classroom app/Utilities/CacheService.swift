import Foundation

actor CacheService {
    static let shared = CacheService()

    private let cachesURL: URL
    private let metaURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cachesURL = caches.appendingPathComponent("com.classroomapp.cache", isDirectory: true)
        metaURL = cachesURL.appendingPathComponent("metadata.json")
        try? FileManager.default.createDirectory(at: cachesURL, withIntermediateDirectories: true)
    }

    private struct Metadata: Codable {
        var entries: [String: Date]
    }

    private func loadMeta() -> Metadata {
        guard let data = try? Data(contentsOf: metaURL),
              let meta = try? decoder.decode(Metadata.self, from: data) else {
            return Metadata(entries: [:])
        }
        return meta
    }

    private func saveMeta(_ meta: Metadata) {
        guard let data = try? encoder.encode(meta) else { return }
        try? data.write(to: metaURL, options: .atomic)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cachesURL.appendingPathComponent("\(safeKey).json")
    }

    func save<T: Codable>(_ value: T, for key: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
        var meta = loadMeta()
        meta.entries[key] = Date()
        saveMeta(meta)
    }

    func load<T: Codable>(_ key: String, maxAge: TimeInterval? = nil) -> T? {
        if let maxAge {
            let meta = loadMeta()
            guard let savedAt = meta.entries[key], -savedAt.timeIntervalSinceNow < maxAge else {
                return nil
            }
        }
        guard let data = try? Data(contentsOf: fileURL(for: key)),
              let value = try? decoder.decode(T.self, from: data) else {
            return nil
        }
        return value
    }

    func remove(_ key: String) {
        try? FileManager.default.removeItem(at: fileURL(for: key))
        var meta = loadMeta()
        meta.entries.removeValue(forKey: key)
        saveMeta(meta)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cachesURL)
        try? FileManager.default.createDirectory(at: cachesURL, withIntermediateDirectories: true)
    }
}

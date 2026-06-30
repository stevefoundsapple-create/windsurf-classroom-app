import Foundation
import os.log

private struct CacheContainer: Codable {
    let data: Data
    let timestamp: Date
    let ttl: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

class OfflineCacheService {
    static let shared = OfflineCacheService()

    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval = 300
    private let logger = Logger(subsystem: "ClassroomApp", category: "OfflineCache")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue: DispatchQueue

    private init() {
        self.fileManager = FileManager.default
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("supabase-cache", isDirectory: true)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.queue = DispatchQueue(label: "app.classroom.cache", qos: .utility)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cache<T: Encodable>(_ value: T, key: String, ttl: TimeInterval? = nil) {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                let data = try self.encoder.encode(value)
                let container = CacheContainer(data: data, timestamp: Date(), ttl: ttl ?? self.defaultTTL)
                let containerData = try self.encoder.encode(container)
                try containerData.write(to: self.url(for: key), options: .atomic)
                self.logger.info("Cached data for key: \(key)")
            } catch {
                self.logger.error("Failed to cache key \(key): \(error.localizedDescription)")
            }
        }
    }

    func fetch<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = self.url(for: key)
        guard let containerData = try? Data(contentsOf: url),
              let container = try? decoder.decode(CacheContainer.self, from: containerData),
              !container.isExpired,
              let value = try? decoder.decode(type, from: container.data)
        else {
            if let containerData = try? Data(contentsOf: url),
               let container = try? decoder.decode(CacheContainer.self, from: containerData),
               container.isExpired {
                try? fileManager.removeItem(at: url)
            }
            return nil
        }
        return value
    }

    func invalidate(key: String) {
        queue.async { [weak self] in
            guard let self else { return }
            let url = self.url(for: key)
            try? self.fileManager.removeItem(at: url)
            self.logger.info("Invalidated cache for key: \(key)")
        }
    }

    func invalidateAll() {
        queue.async { [weak self] in
            guard let self else { return }
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
            self.logger.info("Invalidated all cached data")
        }
    }

    private func url(for key: String) -> URL {
        let sanitized = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent("\(sanitized).cache")
    }
}

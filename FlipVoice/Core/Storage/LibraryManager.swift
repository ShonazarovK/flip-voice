import Foundation
import Combine
import AVFoundation

@MainActor
public final class LibraryManager: ObservableObject {
    public static let shared = LibraryManager()
    
    @Published public var items: [AudioItem] = []
    @Published public var searchText: String = ""
    @Published public var sortOption: SortOption = .newest
    
    public enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case name = "Name"
        case duration = "Duration"
        
        public var id: String { rawValue }
    }
    
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    private let metadataURL: URL
    
    public init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let flipVoiceDir = docs.appendingPathComponent("FlipVoiceRecordings", isDirectory: true)
        
        if !fileManager.fileExists(atPath: flipVoiceDir.path) {
            try? fileManager.createDirectory(at: flipVoiceDir, withIntermediateDirectories: true)
        }
        
        self.storageDirectory = flipVoiceDir
        self.metadataURL = flipVoiceDir.appendingPathComponent("library_metadata.json")
        
        loadMetadata()
    }
    
    public var filteredItems: [AudioItem] {
        var result = items
        
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOption {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .name:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .duration:
            result.sort { $0.duration > $1.duration }
        }
        
        return result
    }
    
    public func url(for item: AudioItem) -> URL {
        storageDirectory.appendingPathComponent(item.relativePath)
    }
    
    public func saveAudio(from sourceURL: URL, title: String, tag: AudioItem.ItemTag, isReversed: Bool = false) throws -> AudioItem {
        let ext = sourceURL.pathExtension.isEmpty ? "wav" : sourceURL.pathExtension
        let uniqueName = "\(UUID().uuidString).\(ext)"
        let destinationURL = storageDirectory.appendingPathComponent(uniqueName)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = (attributes?[.size] as? Int64) ?? 0
        
        let duration = AudioDurationHelper.getDuration(url: destinationURL)
        
        let newItem = AudioItem(
            id: UUID(),
            title: title.isEmpty ? "Voice Note \(items.count + 1)" : title,
            relativePath: uniqueName,
            duration: duration,
            createdAt: Date(),
            isReversed: isReversed,
            tag: tag,
            fileSize: fileSize
        )
        
        items.insert(newItem, at: 0)
        persistMetadata()
        return newItem
    }
    
    public func rename(item: AudioItem, newTitle: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = newTitle.trimmingCharacters(in: .whitespaces)
        persistMetadata()
    }
    
    public func delete(item: AudioItem) {
        let fileURL = url(for: item)
        try? fileManager.removeItem(at: fileURL)
        items.removeAll { $0.id == item.id }
        persistMetadata()
    }
    
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([AudioItem].self, from: data) else {
            return
        }
        // Filter out items whose underlying file has been removed
        self.items = decoded.filter { fileManager.fileExists(atPath: self.url(for: $0).path) }
    }
    
    private func persistMetadata() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: metadataURL)
    }
}

public enum AudioDurationHelper {
    public static func getDuration(url: URL) -> TimeInterval {
        if let file = try? AVFoundation.AVAudioFile(forReading: url) {
            return Double(file.length) / file.processingFormat.sampleRate
        }
        return 0.0
    }
}


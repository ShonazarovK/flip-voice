import Foundation

public struct AudioItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var relativePath: String
    public var duration: TimeInterval
    public var createdAt: Date
    public var isReversed: Bool
    public var tag: ItemTag
    public var fileSize: Int64
    
    public enum ItemTag: String, Codable, CaseIterable {
        case recording = "Recording"
        case reversed = "Reversed"
        case challenge = "Challenge"
        case imported = "Imported"
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        relativePath: String,
        duration: TimeInterval,
        createdAt: Date = Date(),
        isReversed: Bool = false,
        tag: ItemTag = .recording,
        fileSize: Int64 = 0
    ) {
        self.id = id
        self.title = title
        self.relativePath = relativePath
        self.duration = duration
        self.createdAt = createdAt
        self.isReversed = isReversed
        self.tag = tag
        self.fileSize = fileSize
    }
    
    public var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, tenths)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}


import SwiftUI

public struct LibraryView: View {
    @ObservedObject var libraryManager = LibraryManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    @ObservedObject var audioEngine: FlipVoiceAudioEngine
    
    @Binding var selectedTab: Int
    @Binding var currentActiveURL: URL?
    
    @State private var itemToRename: AudioItem?
    @State private var newTitleText: String = ""
    @State private var showRenameAlert = false
    
    @State private var itemToDelete: AudioItem?
    @State private var showDeleteConfirm = false
    
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    public init(
        audioEngine: FlipVoiceAudioEngine,
        selectedTab: Binding<Int>,
        currentActiveURL: Binding<URL?>
    ) {
        self.audioEngine = audioEngine
        self._selectedTab = selectedTab
        self._currentActiveURL = currentActiveURL
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if libraryManager.filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.secondary)
                        Text(localization.localized(.libraryEmpty))
                            .font(.title3.weight(.bold))
                        Text(localization.localized(.libraryEmptySub))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(libraryManager.filteredItems) { item in
                            AudioItemRow(
                                item: item,
                                isCurrentlyLoaded: isItemLoaded(item: item)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                loadItemIntoEditor(item: item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    showDeleteConfirm = true
                                } label: {
                                    Label(localization.localized(.delete), systemImage: "trash")
                                }
                                
                                Button {
                                    itemToRename = item
                                    newTitleText = item.title
                                    showRenameAlert = true
                                } label: {
                                    Label(localization.localized(.rename), systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    shareURL = libraryManager.url(for: item)
                                    showShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.cyan)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(localization.localized(.tabLibrary))
            .searchable(text: $libraryManager.searchText, prompt: localization.localized(.searchRecordings))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(localization.localized(.sortBy), selection: $libraryManager.sortOption) {
                            ForEach(LibraryManager.SortOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Label(localization.localized(.sortBy), systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .alert(localization.localized(.rename), isPresented: $showRenameAlert) {
                TextField("Title", text: $newTitleText)
                Button(localization.localized(.cancel), role: .cancel) {}
                Button("Save") {
                    if let item = itemToRename {
                        libraryManager.rename(item: item, newTitle: newTitleText)
                    }
                }
            }
            .alert(localization.localized(.deleteConfirm), isPresented: $showDeleteConfirm) {
                Button(localization.localized(.delete), role: .destructive) {
                    if let item = itemToDelete {
                        libraryManager.delete(item: item)
                    }
                }
                Button(localization.localized(.cancel), role: .cancel) {}
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func isItemLoaded(item: AudioItem) -> Bool {
        guard let current = currentActiveURL else { return false }
        return current.lastPathComponent == item.relativePath
    }
    
    private func loadItemIntoEditor(item: AudioItem) {
        let fileURL = libraryManager.url(for: item)
        self.currentActiveURL = fileURL
        try? audioEngine.load(url: fileURL)
        selectedTab = 1 // Switch to Editor tab
    }
}

// Subview for individual library row
public struct AudioItemRow: View {
    public let item: AudioItem
    public let isCurrentlyLoaded: Bool
    
    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(badgeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    
                    if isCurrentlyLoaded {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(item.formattedDuration)
                        .font(.caption.monospaced())
                    Text("•")
                        .font(.caption)
                    Text(item.formattedDate)
                        .font(.caption)
                }
                .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.tag.rawValue)
                    .font(.caption2.weight(.bold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(badgeColor.opacity(0.12))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
                
                Text(item.formattedFileSize)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var badgeColor: Color {
        switch item.tag {
        case .recording: return .cyan
        case .reversed: return .purple
        case .challenge: return .orange
        case .imported: return .green
        }
    }
    
    private var iconName: String {
        switch item.tag {
        case .recording: return "mic.fill"
        case .reversed: return "arrow.triangle.2.circlepath"
        case .challenge: return "gamecontroller.fill"
        case .imported: return "tray.and.arrow.down.fill"
        }
    }
}


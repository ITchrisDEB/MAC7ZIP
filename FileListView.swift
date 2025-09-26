import SwiftUI

struct FileListView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    @State private var expandedItems: Set<String> = []
    @State private var selectedItems: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Barre de recherche
            searchBar
            
            Divider()
            
            // NOUVELLE interface hiérarchique
            if archiveManager.hierarchicalItems.isEmpty {
                VStack {
                    Text("no_items_found".localized)
                        .foregroundColor(.secondary)
                    Text("Items: \(archiveManager.hierarchicalItems.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(archiveManager.hierarchicalItems, id: \.path) { item in
                            ArchiveTreeRowView(
                                item: item,
                                level: 0,
                                expandedItems: $expandedItems,
                                selectedItems: $selectedItems,
                                onItemTap: { tappedItem in
                                    handleItemTap(tappedItem)
                                }
                            )
                            .environmentObject(archiveManager)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            NSLog("🔍 FileListView.onAppear - Archive actuelle: \(archiveManager.currentArchive?.name ?? "nil")")
            NSLog("🔍 FileListView.onAppear - Nombre d'items hiérarchiques: \(archiveManager.hierarchicalItems.count)")
            archiveManager.refreshCurrentArchive()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("search_in_archive".localized, text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func handleItemTap(_ item: ArchiveTreeItem) {
        if item.isDirectory {
            // Expansion/contraction du dossier
            if expandedItems.contains(item.path) {
                NSLog("🌳 Contraction du dossier: \(item.name)")
                expandedItems.remove(item.path)
            } else {
                NSLog("🌳 Expansion du dossier: \(item.name) (enfants: \(item.children.count))")
                expandedItems.insert(item.path)
            }
        } else {
            // Sélection du fichier
            if selectedItems.contains(item.path) {
                selectedItems.remove(item.path)
            } else {
                selectedItems.insert(item.path)
            }
        }
    }
}

#Preview {
    FileListView()
        .environmentObject(ArchiveManager())
}
import SwiftUI

struct TorrentScrollView: View {
    let sortedTorrents: [Torrent]
    let manager: TorrentManager
    let store: Store
    let selecting: Bool
    @Binding var selected: [Int]
    let onDelete: (Torrent) -> Void
    let onMove: (Torrent) -> Void
    let onRename: (Torrent) -> Void

    var body: some View {
        ScrollView {
            LazyVStack {
#if os(iOS)
                if manager.isLoading {
                    ProgressView()
                }
#endif

                ForEach(sortedTorrents) { torrent in
                    TorrentRowView(
                        manager: manager,
                        store: store,
                        torrent: torrent,
                        onDelete: { onDelete(torrent) },
                        onMove: { onMove(torrent) },
                        onRename: { onRename(torrent) },
                        selecting: selecting,
                        selected: $selected,
                        torrentProgress: torrent.progress
                    )
                    .id(torrent.id)
                }
            }
            .padding(.bottom, 0)
        }
        .padding(.bottom, 0)
    }
}

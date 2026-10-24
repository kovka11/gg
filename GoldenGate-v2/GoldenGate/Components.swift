import SwiftUI

struct OfflineView: View {
    let isOnline: Bool
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isOnline ? "exclamationmark.triangle" : "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(isOnline ? "Az oldal most nem érhető el" : "Nincs internetkapcsolat")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Ellenőrizd a kapcsolatot, majd próbáld újra.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Label("Újrapróbálás", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Fekete takaró: az alkalmazásváltóban és felvétel közben ez látszik az oldal helyett.
struct PrivacyShield: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("G")
                    .font(.system(size: 72, weight: .bold, design: .serif))
                    .foregroundStyle(Gold.light)
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
    }
}

struct LockView: View {
    let unlock: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Gold.light)
                Text("GoldenGate")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Button(action: unlock) {
                    Label("Feloldás", systemImage: "faceid")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct IncognitoBadge: View {
    var body: some View {
        Label("Inkognitó", systemImage: "eye.slash")
            .font(.caption.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Gold.main, in: Capsule())
    }
}

struct FavoritesView: View {
    @ObservedObject var store: FavoritesStore
    let open: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if store.items.isEmpty {
                    Text("Még nincs kedvenc. A ⋯ menüben mentheted az aktuális oldalt.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.items) { item in
                    Button {
                        if let url = URL(string: item.url) {
                            open(url)
                            dismiss()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .foregroundColor(.primary)
                            Text(item.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .onDelete { offsets in
                    store.remove(at: offsets)
                }
            }
            .navigationTitle("Kedvencek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kész") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

/// Az aktuális oldalon talált .mp4 és .avi linkek listája.
struct VideoLinksView: View {
    let links: [URL]
    let open: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if links.isEmpty {
                    Text("Ezen az oldalon nem találtam .mp4 vagy .avi linket. Ha a videó csak lejátszáskor töltődik be, indítsd el, majd próbáld újra.")
                        .foregroundStyle(.secondary)
                }
                ForEach(links, id: \.absoluteString) { url in
                    HStack(spacing: 12) {
                        Button {
                            open(url)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName(for: url))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                Text(url.host ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderless)

                        Menu {
                            Button {
                                UIPasteboard.general.string = url.absoluteString
                            } label: {
                                Label("Link másolása", systemImage: "doc.on.doc")
                            }
                            Button {
                                UIHelper.presentShareSheet(items: [url])
                            } label: {
                                Label("Link megosztása", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle("Videó linkek (\(links.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kész") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func fileName(for url: URL) -> String {
        let name = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        return name.isEmpty ? url.absoluteString : name
    }
}

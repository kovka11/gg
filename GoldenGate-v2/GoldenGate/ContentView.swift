import SwiftUI

/// Az app által betöltött oldal. Ha változik a cím, csak ezt kell átírni.
let startURL = URL(string: "https://goldengate.hu")!

struct ContentView: View {
    @EnvironmentObject private var appLock: AppLock
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var web = WebState()
    @StateObject private var network = NetworkMonitor()
    @StateObject private var capture = CaptureMonitor()
    @StateObject private var favorites = FavoritesStore()
    @State private var showFavorites = false
    @State private var confirmClear = false
    @State private var showVideos = false
    @State private var videoLinks: [URL] = []

    var body: some View {
        ZStack {
            // Az állapotsor mögötti szín az oldal témaszínét követi
            (web.themeColor ?? Color(.systemBackground))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    if web.blockerReady {
                        WebView(state: web)
                            .id(web.incognito) // inkognitó váltáskor új, tiszta webnézet
                    }

                    if web.progress < 1 && !web.loadFailed {
                        ProgressView(value: web.progress)
                            .progressViewStyle(.linear)
                            .allowsHitTesting(false)
                    }

                    if web.loadFailed {
                        OfflineView(isOnline: network.isOnline) {
                            web.reload()
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if web.incognito {
                        IncognitoBadge()
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }

                BottomBar(
                    web: web,
                    onShare: shareCurrentPage,
                    onAddFavorite: addFavorite,
                    onShowFavorites: { showFavorites = true },
                    onVideos: scanVideos,
                    onClear: { confirmClear = true }
                )
            }
            .sheet(isPresented: $showVideos) {
                VideoLinksView(links: videoLinks) { url in
                    web.open(url)
                }
            }

            if capture.isCaptured {
                PrivacyShield(message: "Képernyőfelvétel közben a tartalom el van rejtve.")
            }

            if appLock.isLocked {
                LockView {
                    appLock.unlock()
                }
            } else if scenePhase != .active {
                PrivacyShield()
            }
        }
        .tint(Gold.main)
        .onChange(of: web.incognito) { _ in
            web.loadFailed = false
            web.progress = 0
        }
        .onChange(of: web.adBlockEnabled) { _ in
            web.applyAdBlock()
        }
        .onChange(of: network.isOnline) { online in
            if online && web.loadFailed {
                web.reload()
            }
        }
        .confirmationDialog(
            "Törlöd a böngészési adatokat, és kijelentkezel?",
            isPresented: $confirmClear,
            titleVisibility: .visible
        ) {
            Button("Törlés", role: .destructive) {
                web.clearAllData()
            }
            Button("Mégse", role: .cancel) {}
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(store: favorites) { url in
                web.open(url)
            }
        }
    }

    private func shareCurrentPage() {
        guard let url = web.currentURL else { return }
        UIHelper.presentShareSheet(items: [url])
    }

    private func addFavorite() {
        guard let url = web.currentURL else { return }
        let title = web.pageTitle.isEmpty ? (url.host ?? "Oldal") : web.pageTitle
        favorites.add(title: title, url: url)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func scanVideos() {
        web.findVideoLinks { links in
            videoLinks = links
            showVideos = true
        }
    }
}

struct BottomBar: View {
    @ObservedObject var web: WebState
    let onShare: () -> Void
    let onAddFavorite: () -> Void
    let onShowFavorites: () -> Void
    let onVideos: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            barButton("chevron.left", disabled: !web.canGoBack) {
                web.webView?.goBack()
            }
            barButton("chevron.right", disabled: !web.canGoForward) {
                web.webView?.goForward()
            }
            barButton("house") {
                web.goHome()
            }
            barButton("arrow.clockwise") {
                web.reload()
            }
            barButton("film", action: onVideos)
            barButton("square.and.arrow.up", disabled: web.currentURL == nil, action: onShare)

            Menu {
                Toggle(isOn: $web.incognito) {
                    Label("Inkognitó mód", systemImage: "eye.slash")
                }
                Toggle(isOn: $web.adBlockEnabled) {
                    Label("Reklámblokkoló", systemImage: "shield.lefthalf.filled")
                }
                Toggle(isOn: $web.landscapeVideo) {
                    Label("Videó fekvő nézetben", systemImage: "rotate.right")
                }
                Divider()
                Button(action: onAddFavorite) {
                    Label("Oldal mentése kedvencnek", systemImage: "star")
                }
                Button(action: onShowFavorites) {
                    Label("Kedvencek", systemImage: "list.star")
                }
                Divider()
                Button(role: .destructive, action: onClear) {
                    Label("Adatok törlése", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 19))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)
    }

    private func barButton(_ icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .disabled(disabled)
    }
}

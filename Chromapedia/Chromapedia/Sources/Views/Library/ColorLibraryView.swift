// Chromapedia
// Views/Library/ColorLibraryView.swift — v6

import SwiftUI

// MARK: - Time-based greeting
private func timeGreeting() -> (text: String, icon: String, tagline: String) {
    let h = Calendar.current.component(.hour, from: Date())
    switch h {
    case 5..<12:  return ("Good Morning", "sun.max.fill", "Start your day with color.")
    case 12..<17: return ("Good Afternoon", "paintpalette.fill", "Every shade has a story.")
    case 17..<21: return ("Good Evening", "sunset.fill", "Explore the spectrum.")
    default:      return ("Good Night", "moon.stars.fill", "Colors that inspire dreams.")
    }
}

// MARK: - Color Library View
struct ColorLibraryView: View {
    @EnvironmentObject var favorites: FavoritesManager
    @State private var selectedCategory: ColorCategory? = nil
    @State private var selectedColor: ColorItem?        = nil
    @State private var searchText                       = ""
    @State private var bgShift                          = false
    @State private var greetingAppeared                 = false
    @State private var showFavorites                    = false
    @State private var pendingFavoriteItem: ColorItem?   = nil
    @State private var favoriteNote                      = ""
    @State private var showInfo                          = false

    private let greet = timeGreeting()

    private var trendingColors: [ColorItem] {
        let base = ColorData.trending
        guard !searchText.isEmpty else { return base }
        return base.filter { matches($0) }
    }

    private var gridColors: [ColorItem] {
        var items = ColorData.all.filter { $0.category != .trending }
        if let cat = selectedCategory { items = items.filter { $0.category == cat } }
        guard !searchText.isEmpty else { return items }
        return items.filter { matches($0) }
    }

    private func matches(_ item: ColorItem) -> Bool {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        let hexClean = q.replacingOccurrences(of: "#", with: "")
        return item.name.localizedCaseInsensitiveContains(q)
            || item.hex.localizedCaseInsensitiveContains(q)
            || item.hex.replacingOccurrences(of: "#", with: "")
                       .localizedCaseInsensitiveContains(hexClean)
            || item.keywords.contains { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView(shift: bgShift).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Greeting header with favorites button ────────
                        HStack(alignment: .top, spacing: 10) {
                            // Left: icon + text
                            Image(systemName: greet.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 28, height: 28)
                                .scaleEffect(greetingAppeared ? 1.0 : 0.3)
                                .opacity(greetingAppeared ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: greetingAppeared)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(greet.text)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(greetingAppeared ? 1 : 0)
                                    .offset(x: greetingAppeared ? 0 : -12)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: greetingAppeared)

                                Text(greet.tagline)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(greetingAppeared ? 1 : 0)
                                    .offset(y: greetingAppeared ? 0 : 6)
                                    .animation(.easeOut(duration: 0.5).delay(0.3), value: greetingAppeared)
                            }


                            Spacer()

                            // Right: favorites button
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showFavorites = true
                            } label: {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF3B6B")],
                                            startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(width: 36, height: 36)
                                    .background(Color(hex: "#FF6B6B").opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            // Info button
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.secondarySystemFill))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 10)

                        // ── Search bar ────────────────────
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("Search by name or #HEX…", text: $searchText)
                                .font(.system(size: 16))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                        VStack(spacing: 24) {

                            // ── Trending — ALWAYS at top ──────────────────
                            if !trendingColors.isEmpty {
                                TrendingSectionView(colors: trendingColors,
                                onSelect: { item in
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedColor = item
                                },
                                onFavorite: { item in
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if favorites.isFavorite(item.hex) {
                                        favorites.toggle(item.hex)
                                    } else {
                                        favoriteNote = ""
                                        pendingFavoriteItem = item
                                    }
                                })
                            }

                            // ── Category filter pills ─────────────────────
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    AllPill(isSelected: selectedCategory == nil) {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                                            selectedCategory = nil
                                        }
                                    }
                                    ForEach(ColorCategory.allCases.filter { $0 != .trending }) { cat in
                                        CategoryPill2(category: cat, isSelected: selectedCategory == cat) {
                                            withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                                                selectedCategory = selectedCategory == cat ? nil : cat
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // ── Active-category label ─────────────────────
                            if let cat = selectedCategory {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.icon).font(.caption.bold())
                                    Text(cat.rawValue).font(.headline.bold())
                                    Text("· \(gridColors.count)")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, -8)
                                .transition(.opacity)
                            }

                            // ── Grid — 2 columns, roomier cards ──────────
                            if gridColors.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass.circle")
                                        .font(.system(size: 46)).foregroundStyle(.tertiary)
                                    Text("No results for \"\(searchText)\"")
                                        .font(.headline).foregroundStyle(.secondary)
                                    Text("Try a name, #HEX, or keyword")
                                        .font(.caption).foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity).padding(60)
                            } else {
                                LazyVGrid(
                                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                                    spacing: 18
                                ) {
                                    ForEach(gridColors) { item in
                                        ModernColorCard(item: item, isFavorite: favorites.isFavorite(item.hex),
                                                        onTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            selectedColor = item
                                        },
                                                        onFavorite: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            if favorites.isFavorite(item.hex) {
                                                favorites.toggle(item.hex)
                                            } else {
                                                favoriteNote = ""
                                                pendingFavoriteItem = item
                                            }
                                        })
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.bottom, 36)
                            }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedColor) { item in
                ColorDetailView(item: item)
                    .environmentObject(favorites)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesSheetView()
                    .environmentObject(favorites)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showInfo) {
                AppInfoView()
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    bgShift = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    greetingAppeared = true
                }
            }
            .alert("Add to Favorites", isPresented: Binding(
                get: { pendingFavoriteItem != nil },
                set: { if !$0 { pendingFavoriteItem = nil } }
            )) {
                TextField("Short note (optional)", text: $favoriteNote)
                Button("Save") {
                    if let item = pendingFavoriteItem {
                        favorites.toggle(item.hex)
                        favorites.setDescription(item.hex, favoriteNote)
                    }
                    pendingFavoriteItem = nil
                    favoriteNote = ""
                }
                Button("Cancel", role: .cancel) {
                    pendingFavoriteItem = nil
                    favoriteNote = ""
                }
            } message: {
                if let item = pendingFavoriteItem {
                    Text("Add a short description for \(item.name) so you remember why you saved it.")
                }
            }
        }
    }
}

// MARK: - Favorites Sheet
struct FavoritesSheetView: View {
    @EnvironmentObject var favorites: FavoritesManager
    @State private var selectedColor: ColorItem? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if favorites.favoriteItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 52)).foregroundStyle(.tertiary)
                        Text("No Favorites Yet")
                            .font(.title3.bold()).foregroundStyle(.secondary)
                        Text("Tap the ❤️ on any color card to save it here.")
                            .font(.subheadline).foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                            spacing: 18,
                            pinnedViews: []
                        ) {
                            ForEach(favorites.favoriteItems) { item in
                                FavoriteCardCell(
                                    item: item,
                                    description: favorites.description(for: item.hex),
                                    onTap: { selectedColor = item },
                                    onFavorite: { favorites.toggle(item.hex) }
                                )
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
            .sheet(item: $selectedColor) { item in
                ColorDetailView(item: item)
                    .environmentObject(favorites)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
        }
    }
}

// MARK: - App Info View
struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.linearGradient(
                                colors: [Color(hex: "#FF6B6B"), Color(hex: "#9B5FE0")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("Welcome to Chromapedia")
                            .font(.title2.bold())
                        Text("Your interactive color theory companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    infoSection(icon: "square.grid.2x2.fill", title: "Explore",
                                desc: "Browse colors by category — Trending, Primary, Pastel, Neon, and more. Search by name or HEX code to find any color instantly.")

                    infoSection(icon: "hand.tap.fill", title: "Color Details",
                                desc: "Tap any color card to see its HEX, RGB, and HSL values. Explore tones, shades, and complementary colors.")

                    infoSection(icon: "heart.fill", title: "Favorites",
                                desc: "Save colors you love with the heart button. Add a short note to remember why you saved each one.")

                    infoSection(icon: "drop.fill", title: "Mix Lab",
                                desc: "Blend two colors together and see the result in real time. Try classic mixtures or create your own.")

                    infoSection(icon: "camera.fill", title: "Identify",
                                desc: "Point your camera at any surface to detect and identify colors in the real world.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    @ViewBuilder
    private func infoSection(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackgroundView: View {
    let shift: Bool
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF0F5"), Color(hex: "#F0F4FF"), Color(hex: "#FFF8F0")],
                startPoint: shift ? .topLeading : .bottomTrailing,
                endPoint:   shift ? .bottomTrailing : .topLeading
            )
            Circle().fill(Color(hex: "#FFB3C6").opacity(0.3)).frame(width: 320).blur(radius: 80)
                .offset(x: shift ? -80 : 80, y: -200)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: shift)
            Circle().fill(Color(hex: "#B3D4FF").opacity(0.26)).frame(width: 280).blur(radius: 70)
                .offset(x: shift ? 100 : -60, y: 110)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: shift)
            Circle().fill(Color(hex: "#FFE4B3").opacity(0.26)).frame(width: 240).blur(radius: 60)
                .offset(x: shift ? 40 : -40, y: shift ? 300 : 210)
                .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: shift)
        }
    }
}

// MARK: - All Pill
struct AllPill: View {
    let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 11, weight: .semibold))
                Text("All").font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(isSelected ? Color.black : Color.white.opacity(0.82))
            .foregroundStyle(isSelected ? .white : .black)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Pill v2
struct CategoryPill2: View {
    let category: ColorCategory; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: category.icon).font(.system(size: 11, weight: .semibold))
                Text(category.rawValue).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(
                isSelected
                    ? LinearGradient(colors: category.gradient, startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.white.opacity(0.82), .white.opacity(0.82)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(isSelected ? .white : .black)
            .clipShape(Capsule())
            .shadow(color: isSelected ? category.gradient.first!.opacity(0.32) : .black.opacity(0.07),
                    radius: isSelected ? 8 : 4, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Trending Section  (always pinned at top)
struct TrendingSectionView: View {
    let colors: [ColorItem]
    let onSelect: (ColorItem) -> Void
    let onFavorite: (ColorItem) -> Void
    @EnvironmentObject var favorites: FavoritesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Trending", systemImage: "flame.fill")
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#FFAA33")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
                Text("2025–26").font(.caption.weight(.bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: "#FF6B6B").opacity(0.12))
                    .foregroundStyle(Color(hex: "#FF6B6B"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(colors) { item in
                        TrendingCard(item: item, isFavorite: favorites.isFavorite(item.hex),
                                     onTap: { onSelect(item) },
                                     onFavorite: { onFavorite(item) })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Trending Card
struct TrendingCard: View {
    let item: ColorItem
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    @State private var shimmer = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(item.color)
                    .frame(width: 155, height: 190)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.22), .white.opacity(0)],
                        startPoint: shimmer ? .topLeading : .bottomTrailing,
                        endPoint:   shimmer ? .bottomTrailing : .topLeading))
                    .frame(width: 155, height: 190)
                LinearGradient(colors: [.black.opacity(0.6), .clear],
                               startPoint: .bottom, endPoint: .init(x: 0.5, y: 0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .frame(width: 155, height: 190)

                // ❤️ Heart button — top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onFavorite()
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isFavorite ? Color(hex: "#FF3B6B") : .white.opacity(0.85))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
                .frame(width: 155, height: 190)

                VStack(alignment: .leading, spacing: 4) {
                    if !item.trendDescription.isEmpty {
                        Text(item.trendDescription.uppercased())
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(0.9)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(item.hex)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 155, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: item.color.opacity(0.44), radius: 14, y: 7)
        }
        .buttonStyle(SpringyButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}

// MARK: - Modern Color Card (grid) — with favorite heart
struct ModernColorCard: View {
    let item: ColorItem
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    @State private var shimmer = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(item.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.2), .white.opacity(0)],
                        startPoint: shimmer ? .topLeading : .bottomTrailing,
                        endPoint:   shimmer ? .bottomTrailing : .topLeading))
                LinearGradient(colors: [.black.opacity(0.44), .clear], startPoint: .bottom, endPoint: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // ❤️ Heart — top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onFavorite()
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isFavorite ? Color(hex: "#FF3B6B") : .white.opacity(0.8))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(isFavorite ? 0.3 : 0.18))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                    Text(item.hex)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(12)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: item.color.opacity(0.32), radius: 10, y: 5)
        }
        .buttonStyle(SpringyButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}

// MARK: - Favorite Card Cell (uniform height for grid alignment)
struct FavoriteCardCell: View {
    let item: ColorItem
    let description: String?
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ModernColorCard(item: item, isFavorite: true,
                            onTap: onTap,
                            onFavorite: onFavorite)

            // Description area — fixed height container so all cells match
            VStack(alignment: .leading) {
                if let desc = description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 30, alignment: .topLeading)
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
    }
}

// MARK: - Color Detail View
struct ColorDetailView: View {
    let item: ColorItem
    @EnvironmentObject var favorites: FavoritesManager
    @Environment(\.dismiss) private var dismiss
    @State private var appear        = false
    @State private var copiedField: String? = nil
    @State private var shadeDetail: ColorItem? = nil
    @State private var showFavPrompt = false
    @State private var favNote       = ""

    // Tones & shades: 7 steps from dark → light
    private var tonesShades: [(Color, String)] {
        let ui = UIColor(item.color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return stride(from: CGFloat(0.15), through: CGFloat(0.95), by: CGFloat(0.115)).map { bv in
            let c = Color(hue: Double(h), saturation: Double(s * 0.92), brightness: Double(bv))
            return (c, ColorMath.colorToHex(c))
        }
    }

    private var complementaryPair: [(Color, String, String)] {
        let comp = ColorMath.complementaryColor(from: item.color)
        return [
            (item.color, item.hex, "Base"),
            (comp, ColorMath.colorToHex(comp), "Complement")
        ]
    }

    var body: some View {
        ZStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                item.color.opacity(0.10).ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: item.color)
                RadialGradient(
                    colors: [item.color.opacity(0.22), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Capsule().fill(.secondary.opacity(0.28)).frame(width: 36, height: 4).padding(.top, 10)

                    // Category + Favorite button
                    HStack {
                        Label(item.category.rawValue, systemImage: item.category.icon)
                            .font(.caption.weight(.bold)).tracking(1)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(.ultraThinMaterial).clipShape(Capsule())

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    ZStack {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(item.color.opacity(0.28)).frame(width: 198, height: 198).blur(radius: 22)
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(item.color).frame(width: 170, height: 170)
                            .shadow(color: item.color.opacity(0.42), radius: 22, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
                                    .frame(width: 170, height: 170)
                            )
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.44), .clear],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                            .frame(width: 164, height: 164)
                    }
                    .scaleEffect(appear ? 1 : 0.72).opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.68).delay(0.05), value: appear)

                    VStack(spacing: 6) {
                        Text(item.name).font(.largeTitle.bold())
                        Text(item.emotion).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        if !item.trendDescription.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color(hex: "#FF6B6B"))
                                Text(item.trendDescription)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(hex: "#FF6B6B"))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(hex: "#FF6B6B").opacity(0.1))
                            .clipShape(Capsule())
                        }
                        Text(item.description).font(.callout).multilineTextAlignment(.center)
                            .foregroundStyle(.secondary).padding(.horizontal, 22).padding(.top, 2)
                    }
                    .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appear)

                    VStack(spacing: 0) {
                        valueRow(icon: "number",                label: "HEX",        value: item.hex)
                        Divider().padding(.leading, 54)
                        valueRow(icon: "slider.horizontal.3",   label: "RGB",        value: item.rgb.displayString)
                        Divider().padding(.leading, 54)
                        valueRow(icon: "circle.lefthalf.filled",label: "HSL",        value: item.hsl.displayString)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.22), value: appear)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tones & Shades")
                            .font(.headline.bold()).padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(tonesShades, id: \.1) { (c, hex) in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        shadeDetail = ColorItem(
                                            name: hex, hex: hex,
                                            category: item.category,
                                            description: "A tone derived from \(item.name).",
                                            emotion: item.emotion,
                                            keywords: item.keywords
                                        )
                                    } label: {
                                        VStack(spacing: 5) {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(c).frame(width: 48, height: 60)
                                                .shadow(color: c.opacity(0.32), radius: 6, y: 2)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                                                )
                                            Text(hex).font(.system(size: 8, weight: .medium, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4).delay(0.28), value: appear)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Complementary")
                            .font(.headline.bold()).padding(.horizontal, 20)

                        HStack(spacing: 10) {
                            ForEach(complementaryPair, id: \.1) { (c, hex, label) in
                                relatedTile(color: c, hex: hex, label: label)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(appear ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4).delay(0.34), value: appear)

                    // ── Save / Favorite button ──────────────────
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if favorites.isFavorite(item.hex) {
                            favorites.toggle(item.hex)
                        } else {
                            favNote = ""
                            showFavPrompt = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: favorites.isFavorite(item.hex) ? "heart.fill" : "heart")
                            Text(favorites.isFavorite(item.hex) ? "Saved" : "Save to Favorites")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(favorites.isFavorite(item.hex) ? Color(hex: "#FF3B6B") : .accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4).delay(0.40), value: appear)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(item: $shadeDetail) { shade in
            ColorDetailView(item: shade)
                .environmentObject(favorites)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { appear = true }
        }
        .alert("Add to Favorites", isPresented: $showFavPrompt) {
            TextField("Short note (optional)", text: $favNote)
            Button("Save") {
                favorites.toggle(item.hex)
                favorites.setDescription(item.hex, favNote)
                favNote = ""
            }
            Button("Cancel", role: .cancel) { favNote = "" }
        } message: {
            Text("Add a short description for \(item.name) so you remember why you saved it.")
        }
    }

    @ViewBuilder
    private func valueRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary).frame(width: 28)
            Text(label)
                .font(.caption.weight(.bold)).foregroundStyle(.secondary).frame(width: 76, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                UIPasteboard.general.string = value
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring()) { copiedField = label }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { if copiedField == label { copiedField = nil } }
                }
            } label: {
                Image(systemName: copiedField == label ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 15))
                    .foregroundStyle(copiedField == label ? Color.green : .secondary)
                    .animation(.spring(response: 0.25), value: copiedField)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    @ViewBuilder
    private func relatedTile(color: Color, hex: String, label: String) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color).frame(height: 84)
                .shadow(color: color.opacity(0.38), radius: 8, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            Text(hex).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

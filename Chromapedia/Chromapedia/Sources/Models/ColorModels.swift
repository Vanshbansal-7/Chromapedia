// Chromapedia — Color Theory App
// Swift Student Challenge 2026
// Models/ColorModels.swift

import SwiftUI

// MARK: - Favorites Manager (persists via @AppStorage)
final class FavoritesManager: ObservableObject {
    @Published private(set) var favoriteHexes: Set<String> = []
    @Published private(set) var favoriteDescriptions: [String: String] = [:]

    private let storageKey = "chromapedia_favorites"
    private let descKey    = "chromapedia_fav_descriptions"

    init() { load() }

    func toggle(_ hex: String) {
        let normalized = hex.uppercased()
        if favoriteHexes.contains(normalized) {
            favoriteHexes.remove(normalized)
            favoriteDescriptions.removeValue(forKey: normalized)
        } else {
            favoriteHexes.insert(normalized)
        }
        save()
    }

    func isFavorite(_ hex: String) -> Bool {
        favoriteHexes.contains(hex.uppercased())
    }

    func setDescription(_ hex: String, _ desc: String) {
        let normalized = hex.uppercased()
        if desc.trimmingCharacters(in: .whitespaces).isEmpty {
            favoriteDescriptions.removeValue(forKey: normalized)
        } else {
            favoriteDescriptions[normalized] = desc
        }
        save()
    }

    func description(for hex: String) -> String? {
        favoriteDescriptions[hex.uppercased()]
    }

    var favoriteItems: [ColorItem] {
        let all = ColorData.all
        return favoriteHexes.compactMap { hex in
            all.first { $0.hex.uppercased() == hex }
        }
    }

    private func save() {
        let joined = favoriteHexes.joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: storageKey)
        if let data = try? JSONEncoder().encode(favoriteDescriptions) {
            UserDefaults.standard.set(data, forKey: descKey)
        }
    }

    private func load() {
        if let raw = UserDefaults.standard.string(forKey: storageKey) {
            favoriteHexes = Set(raw.split(separator: ",").map { String($0) })
        }
        if let data = UserDefaults.standard.data(forKey: descKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            favoriteDescriptions = dict
        }
    }
}

// MARK: - Color Category
enum ColorCategory: String, CaseIterable, Identifiable {
    case trending    = "Trending"
    case basics      = "Basics"
    case primary     = "Primary"
    case secondary   = "Secondary"
    case tertiary    = "Tertiary"
    case pastel      = "Pastel"
    case neon        = "Neon"
    case earth       = "Earth"
    case warm        = "Warm"
    case cool        = "Cool"
    case uiModern    = "UI Modern"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trending:     return "flame.fill"
        case .basics:       return "paintbrush.fill"
        case .primary:      return "circle.fill"
        case .secondary:    return "circle.hexagongrid.fill"
        case .tertiary:     return "triangle.fill"
        case .pastel:       return "cloud.fill"
        case .neon:         return "bolt.fill"
        case .earth:        return "leaf.fill"
        case .warm:         return "sun.max.fill"
        case .cool:         return "snowflake"
        case .uiModern:     return "macwindow"
        }
    }

    var gradient: [Color] {
        switch self {
        case .trending:     return [Color(hex: "#FF6B6B"), Color(hex: "#FFE66D")]
        case .basics:       return [Color(hex: "#333333"), Color(hex: "#FFFFFF")]
        case .primary:      return [Color(hex: "#FF3D00"), Color(hex: "#1A4DFF")]
        case .secondary:    return [Color(hex: "#FF8000"), Color(hex: "#8C1AE6")]
        case .tertiary:     return [Color(hex: "#FF4000"), Color(hex: "#00B3A6")]
        case .pastel:       return [Color(hex: "#FFB3C6"), Color(hex: "#C9B8FF")]
        case .neon:         return [Color(hex: "#39FF14"), Color(hex: "#FF073A")]
        case .earth:        return [Color(hex: "#8B5E3C"), Color(hex: "#6B8E23")]
        case .warm:         return [Color(hex: "#FF4500"), Color(hex: "#FFD700")]
        case .cool:         return [Color(hex: "#00BFFF"), Color(hex: "#8A2BE2")]
        case .uiModern:     return [Color(hex: "#007AFF"), Color(hex: "#34C759")]
        }
    }
}

// MARK: - Color Item
struct ColorItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let hex: String
    let category: ColorCategory
    let description: String
    let emotion: String
    let keywords: [String]
    var isTrending: Bool = false
    var trendDescription: String = ""

    var color: Color { Color(hex: hex) }

    var rgb: RGBValues {
        let (r, g, b) = hex.toRGB()
        return RGBValues(r: r, g: g, b: b)
    }

    var hsl: HSLValues {
        let r = rgb.r, g = rgb.g, b = rgb.b
        return ColorMath.rgbToHSL(r: r, g: g, b: b)
    }

    var brightness: Int { hsl.l }
    var saturation: Int { hsl.s }

    static func == (lhs: ColorItem, rhs: ColorItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Value Types
struct RGBValues {
    let r: Int; let g: Int; let b: Int
    var displayString: String { "R \(r)  G \(g)  B \(b)" }
}

struct HSLValues {
    let h: Int; let s: Int; let l: Int
    var displayString: String { "H \(h)°  S \(s)%  L \(l)%" }
}

// MARK: - Classic Mixture
struct ClassicMixture: Identifiable {
    let id = UUID()
    let name: String
    let color1Hex: String
    let color2Hex: String
    let resultHex: String
    let description: String
}

// MARK: - All Color Data
struct ColorData {
    static let all: [ColorItem] = trending + basics + primary + secondary + tertiary + pastels + neons + earths + warm + cool + uiModern + greys + skinTones + metallics

    // ━━━━━━━━━━━━━━━━━━ BASICS (daily-use essentials) ━━━━━━━━━━━━━━━━━━
    static let basics: [ColorItem] = [
        ColorItem(name: "White",         hex: "#FFFFFF", category: .basics, description: "Pure white — the foundation of light.", emotion: "Purity · Clean · Open", keywords: ["white", "pure", "clean", "basic", "light"]),
        ColorItem(name: "Cream",         hex: "#FFFDD0", category: .basics, description: "Warm off-white — soft and inviting.", emotion: "Warm · Soft · Classic", keywords: ["cream", "white", "warm", "basic"]),
        ColorItem(name: "Off White",     hex: "#FAF9F6", category: .basics, description: "Subtle warm white — elegant and understated.", emotion: "Elegant · Subtle · Clean", keywords: ["off-white", "white", "neutral", "basic"]),
        ColorItem(name: "Black",         hex: "#000000", category: .basics, description: "Absolute darkness — power and elegance.", emotion: "Power · Elegance · Mystery", keywords: ["black", "dark", "basic", "void"]),
        ColorItem(name: "Grey",          hex: "#808080", category: .basics, description: "True neutral grey — balanced and versatile.", emotion: "Neutral · Balance · Calm", keywords: ["grey", "gray", "neutral", "basic"]),
        ColorItem(name: "Red",           hex: "#FF0000", category: .basics, description: "Pure red — bold, vivid, unmistakable.", emotion: "Passion · Power · Urgency", keywords: ["red", "pure", "basic", "bold"]),
        ColorItem(name: "Blue",          hex: "#0000FF", category: .basics, description: "Pure blue — depth, trust, infinity.", emotion: "Trust · Calm · Depth", keywords: ["blue", "pure", "basic", "deep"]),
        ColorItem(name: "Yellow",        hex: "#FFFF00", category: .basics, description: "Pure yellow — energy, joy, sunlight.", emotion: "Joy · Energy · Clarity", keywords: ["yellow", "pure", "basic", "bright"]),
        ColorItem(name: "Green",         hex: "#00FF00", category: .basics, description: "Pure green — nature, growth, harmony.", emotion: "Growth · Harmony · Nature", keywords: ["green", "pure", "basic", "nature"]),
        ColorItem(name: "Orange",        hex: "#FF8000", category: .basics, description: "Vibrant orange — warm and energetic.", emotion: "Energy · Warmth · Creativity", keywords: ["orange", "warm", "basic", "citrus"]),
        ColorItem(name: "Pink",          hex: "#FFC0CB", category: .basics, description: "Classic pink — sweet and gentle.", emotion: "Sweet · Gentle · Tender", keywords: ["pink", "soft", "basic", "gentle"]),
        ColorItem(name: "Purple",        hex: "#800080", category: .basics, description: "Classic purple — royalty and imagination.", emotion: "Mystery · Luxury · Wisdom", keywords: ["purple", "basic", "royal", "classic"]),
        ColorItem(name: "Brown",         hex: "#964B00", category: .basics, description: "Warm brown — earthy and reliable.", emotion: "Earthy · Reliable · Warm", keywords: ["brown", "earth", "basic", "warm"]),
        ColorItem(name: "Cyan",          hex: "#00FFFF", category: .basics, description: "Pure cyan — crisp and digital.", emotion: "Digital · Crisp · Fresh", keywords: ["cyan", "basic", "aqua", "digital"]),
        ColorItem(name: "Maroon",        hex: "#800000", category: .basics, description: "Deep dark red — rich and commanding.", emotion: "Prestige · Depth · Rich", keywords: ["maroon", "red", "dark", "basic"]),
        ColorItem(name: "Navy",          hex: "#000080", category: .basics, description: "Deep blue — authoritative and classic.", emotion: "Authority · Classic · Deep", keywords: ["navy", "blue", "dark", "basic"]),
        ColorItem(name: "Olive",         hex: "#808000", category: .basics, description: "Muted yellow-green — natural and grounded.", emotion: "Natural · Grounded · Calm", keywords: ["olive", "green", "basic", "muted"]),
        ColorItem(name: "Teal",          hex: "#008080", category: .basics, description: "Blue-green balance — elegant and calm.", emotion: "Balanced · Elegant · Calm", keywords: ["teal", "basic", "blue-green", "calm"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ TRENDING ━━━━━━━━━━━━━━━━━━
    static let trending: [ColorItem] = [
        // iPhone 17 — position 1
        ColorItem(name: "iPhone 17 Green",   hex: "#C3D6B8", category: .trending, description: "The rumored hero color for iPhone 17 — a soft, natural sage green.", emotion: "Natural · Fresh · Modern", keywords: ["iphone", "17", "apple", "green", "sage", "2025"], isTrending: true, trendDescription: "iPhone 17 Hero Color"),
        ColorItem(name: "iPhone 17 Titanium", hex: "#B8B3AA", category: .trending, description: "iPhone 17 Pro titanium finish — sleek, understated luxury.", emotion: "Luxury · Minimal · Premium", keywords: ["iphone", "17", "pro", "titanium", "apple"], isTrending: true, trendDescription: "iPhone 17 Pro Titanium"),
        ColorItem(name: "Peach Fuzz",    hex: "#FFBE98", category: .trending, description: "Pantone Color of the Year 2024 — soft, nurturing warmth.", emotion: "Comfort · Care · Warmth", keywords: ["pantone", "2024", "peach", "warm"], isTrending: true, trendDescription: "Pantone Color of 2024"),
        ColorItem(name: "Mocha Mousse",  hex: "#A07850", category: .trending, description: "Pantone Color of the Year 2025 — rich, grounding luxury.", emotion: "Sophistication · Earth · Balance", keywords: ["pantone", "2025", "brown", "coffee"], isTrending: true, trendDescription: "Pantone Color of 2025"),
        ColorItem(name: "Digital Aqua",  hex: "#00D4FF", category: .trending, description: "Dominant in 2026 UI design systems across major tech brands.", emotion: "Innovation · Clarity · Future", keywords: ["ui", "2026", "tech", "aqua"], isTrending: true, trendDescription: "Popular in 2026 UI design"),
        ColorItem(name: "Aurora Violet", hex: "#9B5FE0", category: .trending, description: "Inspired by northern lights — mystical and modern.", emotion: "Magic · Creativity · Dream", keywords: ["aurora", "violet", "gradient", "2026"], isTrending: true, trendDescription: "Rising in modern branding"),
        ColorItem(name: "Solar Coral",   hex: "#FF6B6B", category: .trending, description: "Energetic and approachable — the new red for digital brands.", emotion: "Energy · Friendliness · Bold", keywords: ["coral", "brand", "digital", "warm"], isTrending: true, trendDescription: "Trending in digital branding"),
    ]

    // ━━━━━━━━━━━━━━━━━━ PRIMARY (true: Red, Blue, Yellow) ━━━━━━━━━━━━━━━━━━
    static let primary: [ColorItem] = [
        ColorItem(name: "Pure Red",      hex: "#FF0000", category: .primary, description: "The fundamental warm primary — bold, vivid, unmistakable.", emotion: "Passion · Power · Urgency", keywords: ["red", "primary", "pure", "bold"]),
        ColorItem(name: "Pure Blue",     hex: "#0000FF", category: .primary, description: "The fundamental cool primary — depth, trust, infinity.", emotion: "Trust · Calm · Depth", keywords: ["blue", "primary", "pure", "deep"]),
        ColorItem(name: "Pure Yellow",   hex: "#FFFF00", category: .primary, description: "The fundamental light primary — energy, joy, sunlight.", emotion: "Joy · Energy · Clarity", keywords: ["yellow", "primary", "pure", "bright"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ SECONDARY (true: Orange, Green, Purple) ━━━━━━━━━━━━━━━━━━
    static let secondary: [ColorItem] = [
        ColorItem(name: "Pure Orange",   hex: "#FF8000", category: .secondary, description: "Red + Yellow — vibrant warmth and creative energy.", emotion: "Enthusiasm · Creativity · Warmth", keywords: ["orange", "secondary", "warm", "citrus"]),
        ColorItem(name: "Pure Green",    hex: "#00FF00", category: .secondary, description: "Blue + Yellow — nature, growth, harmony.", emotion: "Growth · Harmony · Nature", keywords: ["green", "secondary", "nature", "fresh"]),
        ColorItem(name: "Pure Purple",   hex: "#8000FF", category: .secondary, description: "Red + Blue — royalty, mystery, imagination.", emotion: "Mystery · Luxury · Wisdom", keywords: ["purple", "secondary", "royal", "magic"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ TERTIARY (6 primary+secondary mixes) ━━━━━━━━━━━━━━━━━━
    static let tertiary: [ColorItem] = [
        ColorItem(name: "Red-Orange",    hex: "#FF4500", category: .tertiary, description: "Red + Orange — volcanic heat and fiery warmth.", emotion: "Intensity · Fire · Boldness", keywords: ["red-orange", "tertiary", "fire", "heat"]),
        ColorItem(name: "Yellow-Orange", hex: "#FFAE00", category: .tertiary, description: "Yellow + Orange — golden amber sunshine.", emotion: "Optimism · Vitality · Warmth", keywords: ["amber", "yellow-orange", "tertiary", "golden"]),
        ColorItem(name: "Yellow-Green",  hex: "#AAFF00", category: .tertiary, description: "Yellow + Green — chartreuse spring energy.", emotion: "Freshness · Youth · Energy", keywords: ["chartreuse", "yellow-green", "tertiary", "spring"]),
        ColorItem(name: "Blue-Green",    hex: "#00CED1", category: .tertiary, description: "Blue + Green — teal ocean depths.", emotion: "Serenity · Clarity · Peace", keywords: ["teal", "blue-green", "tertiary", "ocean"]),
        ColorItem(name: "Blue-Violet",   hex: "#6A0DAD", category: .tertiary, description: "Blue + Purple — cosmic depth and mystery.", emotion: "Depth · Intrigue · Cosmos", keywords: ["violet", "blue-violet", "tertiary", "cosmic"]),
        ColorItem(name: "Red-Violet",    hex: "#C71585", category: .tertiary, description: "Red + Purple — bold magenta romance.", emotion: "Romance · Drama · Passion", keywords: ["magenta", "red-violet", "tertiary", "bold"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ PASTELS ━━━━━━━━━━━━━━━━━━
    static let pastels: [ColorItem] = [
        ColorItem(name: "Cotton Candy",  hex: "#FFB3DE", category: .pastel, description: "Soft and sweet — gentle pink joy.", emotion: "Sweet · Gentle · Playful", keywords: ["pink", "soft", "sweet", "kawaii"]),
        ColorItem(name: "Baby Blue",     hex: "#AED6F1", category: .pastel, description: "Morning sky — delicate, hopeful clarity.", emotion: "Hope · Gentleness · Calm", keywords: ["blue", "soft", "morning", "sky"]),
        ColorItem(name: "Mint Cream",    hex: "#A8E6CF", category: .pastel, description: "Refreshing coolness — spring rain made visible.", emotion: "Freshness · Renewal · Calm", keywords: ["mint", "green", "fresh"]),
        ColorItem(name: "Pale Peach",    hex: "#FFDAB9", category: .pastel, description: "Warm soft glow — comfort personified.", emotion: "Comfort · Warmth · Tender", keywords: ["peach", "warm", "tender"]),
        ColorItem(name: "Lilac Dream",   hex: "#C9B8FF", category: .pastel, description: "Dreamy violet whisper — creative and serene.", emotion: "Dreamy · Creative · Serene", keywords: ["purple", "lavender", "dream"]),
        ColorItem(name: "Butter Cream",  hex: "#FFF4CC", category: .pastel, description: "Warm neutral glow — light and airy.", emotion: "Light · Airy · Gentle", keywords: ["yellow", "cream", "soft", "light"]),
        ColorItem(name: "Powder Rose",   hex: "#F8C8D4", category: .pastel, description: "Blushing softness — romantic and delicate.", emotion: "Romance · Softness · Blush", keywords: ["rose", "pink", "delicate"]),
        ColorItem(name: "Sky Mist",      hex: "#D4EEFF", category: .pastel, description: "Ethereal blue — between fog and sky.", emotion: "Ethereal · Peace · Open", keywords: ["sky", "mist", "blue"]),
        ColorItem(name: "Lavender",      hex: "#E6E6FA", category: .pastel, description: "Soft purple-grey — calming herbal fields.", emotion: "Calm · Herbal · Soothing", keywords: ["lavender", "purple", "soft", "calm"]),
        ColorItem(name: "Blush",         hex: "#DE5D83", category: .pastel, description: "Warm mid-pink — a natural flush of color.", emotion: "Natural · Warm · Rosy", keywords: ["pink", "blush", "rosy"]),
        ColorItem(name: "Seafoam",       hex: "#93E9BE", category: .pastel, description: "Pale ocean green — coastal serenity.", emotion: "Serene · Coastal · Fresh", keywords: ["green", "seafoam", "ocean"]),
        ColorItem(name: "Cornflower",    hex: "#6495ED", category: .pastel, description: "Gentle blue — like wildflowers in a meadow.", emotion: "Gentle · Wild · Free", keywords: ["blue", "cornflower", "meadow"]),
        ColorItem(name: "Peach Pink",    hex: "#FF9A8B", category: .pastel, description: "Warm soft gradient — sunset on petals.", emotion: "Gentle · Warm · Sunset", keywords: ["pink", "peach", "sunset"]),
        ColorItem(name: "Thistle",       hex: "#D8BFD8", category: .pastel, description: "Muted purple — gentle and understated.", emotion: "Gentle · Understated · Quiet", keywords: ["purple", "thistle", "muted"]),
        // — daily-use additions —
        ColorItem(name: "Light Pink",    hex: "#FFB6C1", category: .pastel, description: "Classic light pink — sweet and innocent.", emotion: "Sweet · Innocent · Gentle", keywords: ["pink", "light", "soft", "classic"]),
        ColorItem(name: "Misty Rose",    hex: "#FFE4E1", category: .pastel, description: "Barely-there pink — delicate and dreamy.", emotion: "Delicate · Dreamy · Soft", keywords: ["pink", "misty", "rose", "soft"]),
        ColorItem(name: "Lemon Chiffon", hex: "#FFFACD", category: .pastel, description: "Soft lemony cream — warm and uplifting.", emotion: "Warm · Uplifting · Cheerful", keywords: ["yellow", "lemon", "cream", "soft"]),
        ColorItem(name: "Honeydew",      hex: "#F0FFF0", category: .pastel, description: "Faintest green — fresh and airy.", emotion: "Fresh · Airy · Clean", keywords: ["green", "honeydew", "light", "fresh"]),
        ColorItem(name: "Alice Blue",    hex: "#F0F8FF", category: .pastel, description: "Ethereal blue-white — like morning frost.", emotion: "Ethereal · Cool · Fresh", keywords: ["blue", "alice", "frost", "light"]),
        ColorItem(name: "Pale Turquoise",hex: "#AFEEEE", category: .pastel, description: "Soft aqua tint — calm tropical water.", emotion: "Calm · Tropical · Gentle", keywords: ["turquoise", "aqua", "pale", "soft"]),
        ColorItem(name: "Pale Violet",   hex: "#DB7093", category: .pastel, description: "Muted rose-violet — romantic and refined.", emotion: "Romantic · Refined · Warm", keywords: ["violet", "pale", "rose", "romantic"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ NEONS ━━━━━━━━━━━━━━━━━━
    static let neons: [ColorItem] = [
        ColorItem(name: "Electric Lime",    hex: "#39FF14", category: .neon, description: "Maximum luminosity — night-mode energy.", emotion: "Energy · Electric · Youth", keywords: ["neon", "green", "electric", "rave"]),
        ColorItem(name: "Hot Magenta",      hex: "#FF073A", category: .neon, description: "Screaming pink — cyberpunk attitude.", emotion: "Bold · Cyber · Fierce", keywords: ["neon", "pink", "cyberpunk", "hot"]),
        ColorItem(name: "Laser Blue",       hex: "#00FFFF", category: .neon, description: "Pure cyan beam — digital and crisp.", emotion: "Digital · Crisp · Tech", keywords: ["cyan", "neon", "laser", "tech"]),
        ColorItem(name: "Plasma Purple",    hex: "#BF00FF", category: .neon, description: "Ultra-violet glow — cosmic energy.", emotion: "Cosmic · Power · Mysterious", keywords: ["purple", "neon", "plasma", "ultra"]),
        ColorItem(name: "Solar Flare",      hex: "#FF6600", category: .neon, description: "Blazing intensity — like staring at the sun.", emotion: "Intense · Hot · Blazing", keywords: ["orange", "neon", "solar", "fire"]),
        ColorItem(name: "Acid Yellow",      hex: "#FFFF00", category: .neon, description: "Maximum brightness — pure visual energy.", emotion: "Bright · Alert · Maximum", keywords: ["yellow", "neon", "acid", "bright"]),
        ColorItem(name: "Neon Pink",        hex: "#FF6EC7", category: .neon, description: "Retro-futuristic pink — 80s meets tomorrow.", emotion: "Retro · Fun · Glow", keywords: ["neon", "pink", "80s", "retro"]),
        ColorItem(name: "Electric Blue",    hex: "#7DF9FF", category: .neon, description: "Ice-cold electric — frozen lightning.", emotion: "Electric · Cool · Sharp", keywords: ["blue", "electric", "ice", "neon"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ EARTH ━━━━━━━━━━━━━━━━━━
    static let earths: [ColorItem] = [
        ColorItem(name: "Terracotta",    hex: "#C66B3D", category: .earth, description: "Fired clay warmth — ancient Mediterranean soul.", emotion: "Warmth · Heritage · Earth", keywords: ["clay", "earth", "terracotta", "warm"]),
        ColorItem(name: "Forest Moss",   hex: "#5C7A2E", category: .earth, description: "Deep woodland — ancient, grounded, alive.", emotion: "Grounded · Ancient · Life", keywords: ["forest", "moss", "green", "nature"]),
        ColorItem(name: "Desert Sand",   hex: "#C2956E", category: .earth, description: "Sahara dunes — timeless, warm neutrality.", emotion: "Timeless · Calm · Neutral", keywords: ["sand", "desert", "beige", "warm"]),
        ColorItem(name: "Slate Stone",   hex: "#7D8C8C", category: .earth, description: "Cool granite — solid and dependable.", emotion: "Solid · Dependable · Calm", keywords: ["stone", "slate", "gray", "rock"]),
        ColorItem(name: "Mahogany",      hex: "#6B2737", category: .earth, description: "Rich hardwood — deep, dignified warmth.", emotion: "Dignity · Rich · Warmth", keywords: ["wood", "brown", "red", "mahogany"]),
        ColorItem(name: "Sage Brush",    hex: "#8FAA7A", category: .earth, description: "Dusty sage — serene muted nature.", emotion: "Serene · Natural · Muted", keywords: ["sage", "herb", "muted", "green"]),
        ColorItem(name: "Sienna",        hex: "#A0522D", category: .earth, description: "Classic earth pigment — warm, rich brown.", emotion: "Classic · Natural · Warm", keywords: ["sienna", "brown", "pigment", "earth"]),
        ColorItem(name: "Olive Drab",    hex: "#6B8E23", category: .earth, description: "Military olive — functional and grounded.", emotion: "Functional · Grounded · Natural", keywords: ["olive", "green", "military", "earth"]),
        ColorItem(name: "Umber",         hex: "#635147", category: .earth, description: "Dark rich earth — deep and primal.", emotion: "Primal · Deep · Earth", keywords: ["brown", "umber", "dark", "earth"]),
        ColorItem(name: "Khaki",         hex: "#C3B091", category: .earth, description: "Sandy neutral — versatile and classic.", emotion: "Versatile · Classic · Neutral", keywords: ["khaki", "sand", "neutral", "tan"]),
        ColorItem(name: "Taupe",         hex: "#8B8589", category: .earth, description: "Grey-brown hybrid — sophisticated neutrality.", emotion: "Sophisticated · Neutral · Refined", keywords: ["taupe", "grey", "brown", "neutral"]),
        ColorItem(name: "Chocolate",     hex: "#7B3F00", category: .earth, description: "Deep, rich brown — warmth and indulgence.", emotion: "Indulgence · Warmth · Rich", keywords: ["brown", "chocolate", "dark", "warm"]),
        // —  relocated from old secondary —
        ColorItem(name: "Hunter Green",  hex: "#355E3B", category: .earth, description: "Deep forest green — sophisticated and natural.", emotion: "Sophistication · Nature · Deep", keywords: ["green", "hunter", "forest", "dark"]),
        // — daily-use additions —
        ColorItem(name: "Saddle Brown",  hex: "#8B4513", category: .earth, description: "Rich leather brown — rugged and natural.", emotion: "Rugged · Natural · Rich", keywords: ["brown", "saddle", "leather", "dark"]),
        ColorItem(name: "Peru",          hex: "#CD853F", category: .earth, description: "Warm golden brown — sandy and inviting.", emotion: "Sandy · Inviting · Warm", keywords: ["brown", "peru", "golden", "warm"]),
        ColorItem(name: "Tan",           hex: "#D2B48C", category: .earth, description: "Classic neutral tan — versatile and calm.", emotion: "Versatile · Calm · Classic", keywords: ["tan", "beige", "neutral", "classic"]),
        ColorItem(name: "Wheat",         hex: "#F5DEB3", category: .earth, description: "Warm golden wheat — harvest and comfort.", emotion: "Harvest · Comfort · Golden", keywords: ["wheat", "golden", "warm", "soft"]),
        ColorItem(name: "Beige",         hex: "#F5F5DC", category: .earth, description: "Warm off-white — understated elegance.", emotion: "Understated · Elegant · Neutral", keywords: ["beige", "cream", "neutral", "soft"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ WARM (includes relocated reds, oranges, yellows) ━━━━━━━━━━━━━━━━━━
    static let warm: [ColorItem] = [
        ColorItem(name: "Crimson",       hex: "#C0392B", category: .warm, description: "Deep commanding red — velvet and cherries.", emotion: "Desire · Depth · Prestige", keywords: ["red", "wine", "velvet"]),
        ColorItem(name: "Sunset Coral",  hex: "#FF6B4A", category: .warm, description: "Tropical warmth — effortless coastal beauty.", emotion: "Warmth · Joy · Tropical", keywords: ["coral", "sunset", "beach"]),
        ColorItem(name: "Marigold",      hex: "#FFA500", category: .warm, description: "Festival gold — celebration distilled.", emotion: "Celebration · Joy · Festive", keywords: ["gold", "marigold", "warm", "bright"]),
        ColorItem(name: "Raspberry",     hex: "#C0144C", category: .warm, description: "Bold berry richness — summer luxury.", emotion: "Luxury · Rich · Bold", keywords: ["berry", "raspberry", "pink", "deep"]),
        ColorItem(name: "Salmon",        hex: "#FA8072", category: .warm, description: "Soft pink-orange — gentle and inviting.", emotion: "Gentle · Inviting · Soft", keywords: ["salmon", "pink", "orange", "soft"]),
        ColorItem(name: "Apricot",       hex: "#FBCEB1", category: .warm, description: "Pale orange — warm and delicate.", emotion: "Delicate · Warm · Gentle", keywords: ["apricot", "orange", "peach", "soft"]),
        ColorItem(name: "Rust",          hex: "#B7410E", category: .warm, description: "Oxidized warmth — industrial and organic.", emotion: "Industrial · Organic · Aged", keywords: ["rust", "orange", "brown", "iron"]),
        ColorItem(name: "Tomato Red",    hex: "#FF6347", category: .warm, description: "Bright, fresh red — lively and appetizing.", emotion: "Fresh · Lively · Bold", keywords: ["red", "tomato", "fresh", "vibrant"]),
        ColorItem(name: "Papaya",        hex: "#FFEFD5", category: .warm, description: "Softest warm yellow — barely there glow.", emotion: "Subtle · Warm · Soft", keywords: ["papaya", "yellow", "cream", "warm"]),
        ColorItem(name: "Cinnamon",      hex: "#D2691E", category: .warm, description: "Spiced warmth — aromatic and comforting.", emotion: "Comfort · Spice · Warmth", keywords: ["cinnamon", "brown", "spice", "warm"]),
        // — relocated from old primary —
        ColorItem(name: "Vermilion",     hex: "#E8341A", category: .warm, description: "A grounded, powerful red — bold without being harsh.", emotion: "Passion · Power · Urgency", keywords: ["red", "fire", "love", "danger"]),
        ColorItem(name: "Scarlet",       hex: "#FF2400", category: .warm, description: "Bright, fiery red — pure and intense.", emotion: "Intensity · Urgency · Fire", keywords: ["red", "scarlet", "vibrant", "bold"]),
        ColorItem(name: "Burgundy",      hex: "#800020", category: .warm, description: "Deep wine red — refined and commanding.", emotion: "Prestige · Depth · Elegance", keywords: ["red", "wine", "dark", "burgundy"]),
        ColorItem(name: "Carmine",       hex: "#960018", category: .warm, description: "Rich pigment red — used in classical painting.", emotion: "Art · Tradition · Rich", keywords: ["red", "carmine", "classic", "pigment"]),
        ColorItem(name: "Solar Yellow",  hex: "#F5C800", category: .warm, description: "Warm and inviting — sunlight captured in pigment.", emotion: "Joy · Energy · Clarity", keywords: ["yellow", "sun", "happiness", "light"]),
        ColorItem(name: "Canary Yellow", hex: "#FFEF00", category: .warm, description: "Bright, pure yellow — cheerful and attention-grabbing.", emotion: "Cheer · Attention · Bright", keywords: ["yellow", "canary", "bright", "cheerful"]),
        ColorItem(name: "Lemon",         hex: "#FFF44F", category: .warm, description: "Citrus-fresh yellow — energizing and clean.", emotion: "Fresh · Energizing · Clean", keywords: ["yellow", "lemon", "citrus"]),
        ColorItem(name: "Goldenrod",     hex: "#DAA520", category: .warm, description: "Warm, autumnal gold — harvest and abundance.", emotion: "Warmth · Harvest · Abundance", keywords: ["gold", "yellow", "autumn", "harvest"]),
        // — relocated from old secondary —
        ColorItem(name: "Tangerine",     hex: "#FF7A22", category: .warm, description: "Born from passion and warmth — autumn leaves and citrus.", emotion: "Enthusiasm · Creativity · Warmth", keywords: ["orange", "citrus", "autumn"]),
        ColorItem(name: "Pumpkin",       hex: "#FF7518", category: .warm, description: "Warm autumn harvest — festive and inviting.", emotion: "Festive · Warm · Harvest", keywords: ["orange", "pumpkin", "autumn", "halloween"]),
        ColorItem(name: "Burnt Orange",  hex: "#CC5500", category: .warm, description: "Deep, warm orange — earthy and rustic.", emotion: "Rustic · Warm · Earthy", keywords: ["orange", "burnt", "rustic", "deep"]),
        // — relocated from old tertiary —
        ColorItem(name: "Flame",         hex: "#E84118", category: .warm, description: "Volcanic intensity — urgent and impossible to ignore.", emotion: "Intensity · Fire · Boldness", keywords: ["fire", "intensity", "heat"]),
        ColorItem(name: "Amber",         hex: "#F39C12", category: .warm, description: "Golden hour — the warmth of late afternoon sun.", emotion: "Optimism · Vitality · Warmth", keywords: ["golden", "sunshine", "amber"]),
        ColorItem(name: "Fuchsia Rose",  hex: "#CC0066", category: .warm, description: "Bold drama of romance — fearless expression.", emotion: "Romance · Drama · Passion", keywords: ["romance", "pink", "bold"]),
        ColorItem(name: "Vermillion",    hex: "#E34234", category: .warm, description: "Classic red-orange pigment — used through the ages.", emotion: "Classic · Warm · Pigment", keywords: ["red", "orange", "pigment"]),
        ColorItem(name: "Magenta",       hex: "#FF00FF", category: .warm, description: "Pure secondary light — vibrant and eye-catching.", emotion: "Vibrant · Boldness · Daring", keywords: ["pink", "magenta", "vibrant"]),
        // — daily-use additions —
        ColorItem(name: "Indian Red",    hex: "#CD5C5C", category: .warm, description: "Earthy mid-red — warm and approachable.", emotion: "Warm · Earthy · Friendly", keywords: ["red", "indian", "earthy", "warm"]),
        ColorItem(name: "Light Coral",   hex: "#F08080", category: .warm, description: "Soft coral — playful and inviting.", emotion: "Playful · Inviting · Soft", keywords: ["coral", "pink", "light", "soft"]),
        ColorItem(name: "Hot Pink",      hex: "#FF69B4", category: .warm, description: "Bold, energetic pink — fun and fearless.", emotion: "Fun · Fearless · Bold", keywords: ["pink", "hot", "bold", "fun"]),
        ColorItem(name: "Deep Pink",     hex: "#FF1493", category: .warm, description: "Intense vivid pink — passionate and daring.", emotion: "Passionate · Daring · Vivid", keywords: ["pink", "deep", "vivid", "intense"]),
        ColorItem(name: "Orange Red",    hex: "#FF4500", category: .warm, description: "Fierce orange-red — impossible to ignore.", emotion: "Fierce · Urgent · Fiery", keywords: ["orange", "red", "fire", "bold"]),
        ColorItem(name: "Dark Orange",   hex: "#FF8C00", category: .warm, description: "Rich warm orange — autumn harvest glow.", emotion: "Harvest · Rich · Warm", keywords: ["orange", "dark", "autumn", "warm"]),
        ColorItem(name: "Coral",         hex: "#FF7F50", category: .warm, description: "Classic coral — tropical warmth.", emotion: "Tropical · Classic · Warm", keywords: ["coral", "orange", "tropical", "classic"]),
        ColorItem(name: "Peach",         hex: "#FFCBA4", category: .warm, description: "Gentle warm peach — delicate and soothing.", emotion: "Delicate · Soothing · Warm", keywords: ["peach", "soft", "warm", "gentle"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ COOL (includes relocated blues, greens, purples) ━━━━━━━━━━━━━━━━━━
    static let cool: [ColorItem] = [
        ColorItem(name: "Arctic Blue",   hex: "#00BFFF", category: .cool, description: "Crystal clarity — sharp and refreshing.", emotion: "Clarity · Refresh · Sharp", keywords: ["arctic", "blue", "ice", "cold"]),
        ColorItem(name: "Slate Teal",    hex: "#2E8B8B", category: .cool, description: "Balanced cool — sophisticated composure.", emotion: "Balance · Sophist. · Cool", keywords: ["teal", "slate", "balanced"]),
        ColorItem(name: "Twilight",      hex: "#5C35AA", category: .cool, description: "Deep purple dusk — intuition and knowing.", emotion: "Intuition · Wisdom · Depth", keywords: ["twilight", "purple", "dusk"]),
        ColorItem(name: "Ice Lavender",  hex: "#B8A9D9", category: .cool, description: "Gentle violet mist — graceful serenity.", emotion: "Grace · Serene · Gentle", keywords: ["lavender", "violet", "gentle"]),
        ColorItem(name: "Steel Blue",    hex: "#4682B4", category: .cool, description: "Industrial blue — strong and dependable.", emotion: "Strong · Dependable · Modern", keywords: ["steel", "blue", "industrial"]),
        ColorItem(name: "Periwinkle",    hex: "#CCCCFF", category: .cool, description: "Soft blue-violet — tranquil and dreamy.", emotion: "Tranquil · Dreamy · Soft", keywords: ["periwinkle", "blue", "violet", "soft"]),
        ColorItem(name: "Cerulean",      hex: "#007BA7", category: .cool, description: "Classic sky blue — clarity and openness.", emotion: "Clarity · Open · Sky", keywords: ["cerulean", "blue", "sky", "classic"]),
        ColorItem(name: "Turquoise",     hex: "#40E0D0", category: .cool, description: "Blue-green gem — tropical water and jewelry.", emotion: "Tropical · Precious · Vivid", keywords: ["turquoise", "blue", "green", "gem"]),
        ColorItem(name: "Powder Blue",   hex: "#B0E0E6", category: .cool, description: "Soft, pale blue — like a cloudless winter morning.", emotion: "Soft · Winter · Calm", keywords: ["blue", "powder", "pale", "gentle"]),
        // — basic missing — 
        ColorItem(name: "Black",         hex: "#000000", category: .cool, description: "Absolute absence of light — power and elegance.", emotion: "Power · Elegance · Mystery", keywords: ["black", "dark", "void", "basic"]),
        // — relocated from old primary —
        ColorItem(name: "Cobalt Blue",   hex: "#2255DD", category: .cool, description: "Deep and trustworthy — the backbone of modern UI.", emotion: "Trust · Calm · Depth", keywords: ["blue", "cobalt", "ocean", "peace"]),
        ColorItem(name: "Navy Blue",     hex: "#001F3F", category: .cool, description: "Deepest authoritative blue — serious and respectable.", emotion: "Authority · Trust · Serious", keywords: ["navy", "blue", "dark", "sea"]),
        ColorItem(name: "Ultramarine",   hex: "#3F00FF", category: .cool, description: "Vivid, luminous blue — once more valuable than gold.", emotion: "Priceless · Vivid · Historic", keywords: ["blue", "ultramarine", "vivid", "historic"]),
        ColorItem(name: "Royal Blue",    hex: "#4169E1", category: .cool, description: "Classic rich blue — bright and regal.", emotion: "Regal · Bright · Classic", keywords: ["blue", "royal", "classic"]),
        // — relocated from old secondary —
        ColorItem(name: "Emerald",       hex: "#0EB87A", category: .cool, description: "Nature's signature — growth, balance, life.", emotion: "Growth · Harmony · Nature", keywords: ["green", "nature", "growth", "money"]),
        ColorItem(name: "Kelly Green",   hex: "#4CBB17", category: .cool, description: "Bright, vivid green — Irish meadows in spring.", emotion: "Vivid · Lively · Fresh", keywords: ["green", "kelly", "vivid", "spring"]),
        ColorItem(name: "Jade",          hex: "#00A86B", category: .cool, description: "Precious stone green — elegant and balanced.", emotion: "Elegance · Balance · Precious", keywords: ["green", "jade", "stone", "precious"]),
        ColorItem(name: "Amethyst",      hex: "#7B2FBE", category: .cool, description: "Royal mystery converged — imagination made visible.", emotion: "Mystery · Luxury · Wisdom", keywords: ["purple", "royalty", "magic"]),
        ColorItem(name: "Plum",          hex: "#8E4585", category: .cool, description: "Rich purple-red — like ripe autumn fruit.", emotion: "Rich · Ripe · Mature", keywords: ["purple", "plum", "fruit", "rich"]),
        ColorItem(name: "Indigo",        hex: "#4B0082", category: .cool, description: "Deep blue-violet — between night and dream.", emotion: "Depth · Night · Intuition", keywords: ["indigo", "violet", "deep", "nightsky"]),
        // — relocated from old tertiary —
        ColorItem(name: "Teal Ocean",    hex: "#00A896", category: .cool, description: "Tropical waters at their clearest.", emotion: "Serenity · Clarity · Peace", keywords: ["ocean", "teal", "tropical"]),
        ColorItem(name: "Deep Violet",   hex: "#5B2C8D", category: .cool, description: "Cosmic depth — beyond visible spectrum.", emotion: "Depth · Intrigue · Cosmos", keywords: ["space", "mystery", "violet"]),
        ColorItem(name: "Chartreuse",    hex: "#7FFF00", category: .cool, description: "Yellow-green brilliance — nature at full vibrancy.", emotion: "Vibrancy · Nature · Bold", keywords: ["green", "yellow", "chartreuse"]),
        ColorItem(name: "Aquamarine",    hex: "#7FFFD4", category: .cool, description: "Pale blue-green — tropical sea near a coral reef.", emotion: "Tropical · Refreshing · Clear", keywords: ["aqua", "blue", "green", "sea"]),
        ColorItem(name: "Lime Burst",    hex: "#A8D800", category: .cool, description: "Spring energy — fresh shoots after winter.", emotion: "Freshness · Youth · Energy", keywords: ["spring", "fresh", "lime"]),
        // — daily-use additions —
        ColorItem(name: "Medium Blue",   hex: "#0000CD", category: .cool, description: "Classic medium blue — strong and clear.", emotion: "Strong · Clear · Classic", keywords: ["blue", "medium", "classic", "strong"]),
        ColorItem(name: "Dark Cyan",     hex: "#008B8B", category: .cool, description: "Deep teal — mysterious ocean depths.", emotion: "Mysterious · Deep · Ocean", keywords: ["cyan", "dark", "teal", "ocean"]),
        ColorItem(name: "Teal",          hex: "#008080", category: .cool, description: "Perfect blue-green — balanced and elegant.", emotion: "Balanced · Elegant · Calm", keywords: ["teal", "blue", "green", "classic"]),
        ColorItem(name: "Slate Blue",    hex: "#6A5ACD", category: .cool, description: "Blue with purple undertone — sophisticated and creative.", emotion: "Sophisticated · Creative · Calm", keywords: ["blue", "slate", "purple", "creative"]),
        ColorItem(name: "Medium Aquamarine", hex: "#66CDAA", category: .cool, description: "Soft sea green — refreshing and tranquil.", emotion: "Refreshing · Tranquil · Sea", keywords: ["aquamarine", "green", "sea", "soft"]),
        ColorItem(name: "Sea Green",     hex: "#2E8B57", category: .cool, description: "Deep ocean green — natural and calming.", emotion: "Natural · Calming · Deep", keywords: ["green", "sea", "ocean", "natural"]),
        ColorItem(name: "Mint Green",    hex: "#98FF98", category: .cool, description: "Fresh, light green — breezy and uplifting.", emotion: "Fresh · Uplifting · Breezy", keywords: ["mint", "green", "fresh", "light"]),
        ColorItem(name: "Sky Blue",      hex: "#87CEEB", category: .cool, description: "Classic daytime sky — open and peaceful.", emotion: "Open · Peaceful · Sky", keywords: ["sky", "blue", "light", "peaceful"]),
        ColorItem(name: "Dodger Blue",   hex: "#1E90FF", category: .cool, description: "Bright vivid blue — energetic and modern.", emotion: "Energetic · Modern · Vivid", keywords: ["blue", "dodger", "vivid", "bright"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ UI MODERN ━━━━━━━━━━━━━━━━━━
    static let uiModern: [ColorItem] = [
        ColorItem(name: "iOS Blue",      hex: "#007AFF", category: .uiModern, description: "Apple's signature interactive blue — trusted and clear.", emotion: "Trust · Clear · Interactive", keywords: ["ios", "apple", "blue", "ui"], isTrending: true, trendDescription: "Apple iOS system blue"),
        ColorItem(name: "Android Green", hex: "#34A853", category: .uiModern, description: "Google Material green — fresh and accessible.", emotion: "Fresh · Accessible · Modern", keywords: ["android", "google", "green", "material"]),
        ColorItem(name: "Figma Purple",  hex: "#A259FF", category: .uiModern, description: "Figma's brand purple — creative and professional.", emotion: "Creative · Professional · Design", keywords: ["figma", "design", "purple", "tool"]),
        ColorItem(name: "Notion Black",  hex: "#2F2F2F", category: .uiModern, description: "Deep charcoal — modern productivity aesthetic.", emotion: "Focus · Minimal · Clean", keywords: ["notion", "dark", "minimal", "productive"]),
        ColorItem(name: "Vercel White",  hex: "#F5F5F5", category: .uiModern, description: "Pure functional white — clarity at its finest.", emotion: "Pure · Clear · Functional", keywords: ["white", "clean", "minimal", "pure"]),
        ColorItem(name: "Slack Purple",  hex: "#4A154B", category: .uiModern, description: "Slack's deep plum — bold workspace identity.", emotion: "Bold · Workspace · Identity", keywords: ["slack", "purple", "workspace", "brand"]),
        ColorItem(name: "Spotify Green", hex: "#1DB954", category: .uiModern, description: "Spotify's vibrant green — music and energy.", emotion: "Energy · Music · Vibrant", keywords: ["spotify", "green", "music", "brand"]),
        ColorItem(name: "YouTube Red",   hex: "#FF0000", category: .uiModern, description: "YouTube's iconic red — content and creativity.", emotion: "Creative · Bold · Iconic", keywords: ["youtube", "red", "video", "brand"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ GREYS & NEUTRALS ━━━━━━━━━━━━━━━━━━
    static let greys: [ColorItem] = [
        ColorItem(name: "Pure White",    hex: "#FFFFFF", category: .cool, description: "Absolute zero darkness — pure light.", emotion: "Purity · Clean · Open", keywords: ["white", "pure", "clean", "light"]),
        ColorItem(name: "Snow",          hex: "#FFFAFA", category: .cool, description: "Barely warm white — fresh snowfall.", emotion: "Fresh · Clean · Winter", keywords: ["white", "snow", "warm"]),
        ColorItem(name: "Ivory",         hex: "#FFFFF0", category: .warm, description: "Warm off-white — elegant and classic.", emotion: "Elegant · Classic · Warm", keywords: ["ivory", "cream", "off-white"]),
        ColorItem(name: "Ghost White",   hex: "#F8F8FF", category: .cool, description: "Cool-toned white — digital clarity.", emotion: "Digital · Clarity · Cool", keywords: ["white", "ghost", "cool"]),
        ColorItem(name: "Light Grey",    hex: "#D3D3D3", category: .cool, description: "Soft neutral — unobtrusive and versatile.", emotion: "Neutral · Soft · Versatile", keywords: ["grey", "gray", "light", "neutral"]),
        ColorItem(name: "Silver",        hex: "#C0C0C0", category: .cool, description: "Cool metallic — modern and polished.", emotion: "Modern · Polished · Cool", keywords: ["silver", "grey", "metallic"]),
        ColorItem(name: "Medium Grey",   hex: "#808080", category: .cool, description: "True neutral — centerpoint of value.", emotion: "Neutral · Balance · Center", keywords: ["grey", "gray", "medium", "neutral"]),
        ColorItem(name: "Dim Grey",      hex: "#696969", category: .cool, description: "Darker neutral — subtle and grounding.", emotion: "Grounding · Subtle · Calm", keywords: ["grey", "gray", "dim", "dark"]),
        ColorItem(name: "Charcoal",      hex: "#36454F", category: .cool, description: "Near-black with blue — sophisticated darkness.", emotion: "Sophisticated · Deep · Modern", keywords: ["charcoal", "dark", "nearly-black"]),
        ColorItem(name: "Onyx",          hex: "#353839", category: .cool, description: "Deep stone black — gem-like darkness.", emotion: "Premium · Deep · Gem", keywords: ["black", "onyx", "dark", "stone"]),
        ColorItem(name: "Jet Black",     hex: "#0A0A0A", category: .cool, description: "Deepest black — maximum darkness.", emotion: "Maximum · Dark · Void", keywords: ["black", "jet", "dark", "deep"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ SKIN TONES ━━━━━━━━━━━━━━━━━━
    static let skinTones: [ColorItem] = [
        ColorItem(name: "Porcelain",     hex: "#FDEEF4", category: .warm, description: "Lightest fair skin — delicate and luminous.", emotion: "Delicate · Luminous · Fair", keywords: ["skin", "fair", "porcelain", "light"]),
        ColorItem(name: "Fair Ivory",    hex: "#FFE0BD", category: .warm, description: "Light warm skin — subtle golden undertone.", emotion: "Warm · Subtle · Golden", keywords: ["skin", "fair", "ivory", "light"]),
        ColorItem(name: "Light Beige",   hex: "#F1C27D", category: .warm, description: "Light-medium skin — warm and sandy.", emotion: "Warm · Sandy · Natural", keywords: ["skin", "beige", "light"]),
        ColorItem(name: "Warm Sand",     hex: "#E0AC69", category: .warm, description: "Medium skin — honey and warmth.", emotion: "Warm · Honey · Natural", keywords: ["skin", "medium", "sand", "honey"]),
        ColorItem(name: "Golden Brown",  hex: "#C68642", category: .warm, description: "Medium-dark skin — rich golden warmth.", emotion: "Rich · Golden · Warm", keywords: ["skin", "brown", "golden", "medium"]),
        ColorItem(name: "Cacao",         hex: "#8D5524", category: .warm, description: "Dark skin — deep, warm richness.", emotion: "Deep · Rich · Warm", keywords: ["skin", "dark", "brown", "cacao"]),
        ColorItem(name: "Espresso",      hex: "#5C3317", category: .warm, description: "Deep dark skin — beautiful depth.", emotion: "Depth · Beauty · Strength", keywords: ["skin", "deep", "espresso", "dark"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ METALLICS ━━━━━━━━━━━━━━━━━━
    static let metallics: [ColorItem] = [
        ColorItem(name: "Gold",          hex: "#FFD700", category: .warm, description: "Pure metallic gold — luxury and achievement.", emotion: "Luxury · Achievement · Prestige", keywords: ["gold", "metallic", "luxury", "precious"]),
        ColorItem(name: "Rose Gold",     hex: "#B76E79", category: .warm, description: "Pink-tinted gold — modern, feminine luxury.", emotion: "Modern · Feminine · Elegant", keywords: ["rose", "gold", "pink", "metallic"]),
        ColorItem(name: "Bronze",        hex: "#CD7F32", category: .warm, description: "Warm metallic — ancient and enduring.", emotion: "Ancient · Enduring · Warm", keywords: ["bronze", "metallic", "brown", "warm"]),
        ColorItem(name: "Copper",        hex: "#B87333", category: .warm, description: "Red-gold metal — industrial warmth.", emotion: "Industrial · Warm · Rich", keywords: ["copper", "metallic", "orange", "warm"]),
        ColorItem(name: "Platinum",      hex: "#E5E4E2", category: .cool, description: "Cool silver-white — the ultimate premium.", emotion: "Premium · Cool · Exclusive", keywords: ["platinum", "silver", "white", "premium"]),
    ]

    // ━━━━━━━━━━━━━━━━━━ CLASSIC MIXTURES ━━━━━━━━━━━━━━━━━━
    static let classicMixtures: [ClassicMixture] = [
        // ── Fundamental primary pairs ──
        ClassicMixture(name: "Red + Blue",    color1Hex: "#E8341A", color2Hex: "#2255DD", resultHex: "#76446B", description: "Classic purple — passion meets depth."),
        ClassicMixture(name: "Red + Yellow",  color1Hex: "#E8341A", color2Hex: "#F5C800", resultHex: "#EE760C", description: "Vibrant orange — fire meets sunshine."),
        ClassicMixture(name: "Blue + Yellow", color1Hex: "#2255DD", color2Hex: "#F5C800", resultHex: "#7B8A55", description: "Fresh green — logic meets warmth."),
        // ── Tints with white ──
        ClassicMixture(name: "Red + White",   color1Hex: "#E8341A", color2Hex: "#FFFFFF", resultHex: "#F38C78", description: "Soft pink — passion diluted to delicacy."),
        ClassicMixture(name: "Blue + White",  color1Hex: "#2255DD", color2Hex: "#FFFFFF", resultHex: "#7FA2EE", description: "Periwinkle — trust lightened to serenity."),
        ClassicMixture(name: "Black + White", color1Hex: "#2F2F2F", color2Hex: "#FFFFFF", resultHex: "#888888", description: "Mid gray — equilibrium of extremes."),
        // ── Popular daily-use mixes ──
        ClassicMixture(name: "Red + Green",     color1Hex: "#E8341A", color2Hex: "#00FF00", resultHex: "#598C0C", description: "Earthy olive — complementary neutralization."),
        ClassicMixture(name: "Orange + Blue",   color1Hex: "#FF8000", color2Hex: "#2255DD", resultHex: "#7F6A55", description: "Warm brown — classic complementary neutral."),
        ClassicMixture(name: "Purple + Yellow", color1Hex: "#8000FF", color2Hex: "#F5C800", resultHex: "#B74E61", description: "Muted mauve — subdued warmth."),
        ClassicMixture(name: "Yellow + Green",  color1Hex: "#F5C800", color2Hex: "#00FF00", resultHex: "#5EE303", description: "Lime green — fresh spring energy."),
        ClassicMixture(name: "Red + Black",     color1Hex: "#E8341A", color2Hex: "#1A1A1A", resultHex: "#70261A", description: "Dark maroon — deep and dramatic."),
        ClassicMixture(name: "Blue + Black",    color1Hex: "#2255DD", color2Hex: "#1A1A1A", resultHex: "#1E356B", description: "Dark navy — midnight depth."),
        ClassicMixture(name: "Yellow + White",  color1Hex: "#F5C800", color2Hex: "#FFFFFF", resultHex: "#FAE361", description: "Cream — warm and subtle."),
        ClassicMixture(name: "Orange + White",  color1Hex: "#FF8000", color2Hex: "#FFFFFF", resultHex: "#FFBB61", description: "Light peach — soft warmth."),
        ClassicMixture(name: "Green + Blue",    color1Hex: "#00FF00", color2Hex: "#2255DD", resultHex: "#10A255", description: "Teal — balanced blue-green."),
        ClassicMixture(name: "Pink + Blue",     color1Hex: "#FF69B4", color2Hex: "#2255DD", resultHex: "#7F5FC8", description: "Soft violet — playful and creative."),
        ClassicMixture(name: "Orange + Red",    color1Hex: "#FF8000", color2Hex: "#E8341A", resultHex: "#F3570C", description: "Vermillion — fiery intensity."),
        ClassicMixture(name: "Green + White",   color1Hex: "#00FF00", color2Hex: "#FFFFFF", resultHex: "#61FF61", description: "Mint — fresh and airy."),
    ]
}

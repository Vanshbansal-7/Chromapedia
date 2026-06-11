# 🎨 Chromapedia

A beautifully crafted iOS color encyclopedia built with SwiftUI. Explore, mix, and identify colors — all in one app.

<p align="center">
  <img src="ss1.jpeg" width="250" />
  <img src="ss2.jpeg" width="250" />
  <img src="ss3.jpeg" width="250" />
</p>

## ✨ Features

### 🔍 Explore — Color Library
- Browse a curated collection of **300+ named colors** with rich metadata
- View color details including **HEX, RGB, and HSL** values with copy-to-clipboard
- Explore **Tones & Shades** for every color
- Discover **Trending** and **Classic** color palettes
- Save favorites for quick access

### 🧪 Mix Lab — Color Mixing
- Mix **2 or 3 colors** using realistic spectral blending
- Input colors via **HEX code** or **color picker**
- See real-time blend results with named color approximation
- Try **Classic Mixtures** presets with one tap

### 📷 Identify — Camera Color Detection
- **Live camera viewfinder** with crosshair targeting
- Real-time **HEX, RGB** readout of any surface
- **AI-powered color name matching** (e.g., ~Mocha Mousse)
- Copy HEX codes instantly or save the color

## 🛠 Tech Stack

| Technology | Details |
|---|---|
| **Language** | Swift 5 |
| **Framework** | SwiftUI |
| **Platform** | iOS 17.0+ |
| **Architecture** | MVVM |
| **Camera** | AVFoundation |
| **Project Type** | Swift Playgrounds / Xcode |

## 📁 Project Structure

```
Chromapedia.swiftpm/
├── Package.swift
└── Sources/
    ├── ChromaLearnApp.swift          # App entry point & tab navigation
    ├── Models/
    │   └── ColorModels.swift         # Color data models & favorites manager
    ├── Utilities/
    │   ├── ColorMath.swift           # Color space conversions & calculations
    │   ├── CustomShapes.swift        # Custom SwiftUI shapes
    │   └── SpectralMixer.swift       # Realistic spectral color mixing engine
    └── Views/
        ├── Camera/
        │   ├── CameraColorView.swift # Live camera color identification UI
        │   └── CameraModel.swift     # AVFoundation camera management
        ├── Components/
        │   └── SharedComponents.swift # Reusable UI components
        ├── Library/
        │   └── ColorLibraryView.swift # Color exploration & detail views
        └── MixLab/
            └── MixingLabView.swift   # Color mixing laboratory UI
```

## 📋 Requirements

- **Xcode 16.0+** or **Swift Playgrounds 4.5+**
- **iOS 17.0+**
- Physical device recommended (for camera features)

## 🚀 Getting Started

### Option 1: Open in Xcode
1. Clone this repository
   ```bash
   git clone https://github.com/YOUR_USERNAME/Chromapedia.git
   ```
2. Open `Chromapedia.swiftpm` in Xcode
3. Select your target device (iPhone recommended)
4. Press **⌘ + R** to build and run

### Option 2: Open in Swift Playgrounds
1. Clone or download this repository
2. Open `Chromapedia.swiftpm` directly in **Swift Playgrounds** on iPad or Mac
3. Tap **Run**

> **Note:** Camera features require a physical device. The Simulator does not support camera access.

## 🎯 Permissions

| Permission | Purpose |
|---|---|
| **Camera** | Detect and identify colors in the real world |

## 📄 License

This project is available under the [MIT License](LICENSE).

## 🙌 Acknowledgments

- Built with ❤️ using SwiftUI
- Color science powered by spectral mixing algorithms
- Designed for color enthusiasts, designers, and artists

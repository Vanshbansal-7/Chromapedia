// Chromapedia
// Views/MixLab/MixingLabView.swift — v4

import SwiftUI

// MARK: - Mix Lab
struct MixingLabView: View {
    @State private var color1: Color = Color(hex: "#E8341A")
    @State private var color2: Color = Color(hex: "#2255DD")
    @State private var color3: Color = Color(hex: "#F5C800")
    @State private var useThreeColors = false
    @State private var mixComplete = false
    @State private var resultScale: CGFloat = 1.0
    @State private var showCopied = false
    @State private var showDetail = false
    @State private var showMixInfo = false
    @State private var hexInput1 = ""; @State private var hexInput2 = ""; @State private var hexInput3 = ""
    @State private var showHexEntry1 = false; @State private var showHexEntry2 = false; @State private var showHexEntry3 = false

    // Blob merge animation
    @State private var blob1Offset: CGSize = CGSize(width: -68, height: 0)
    @State private var blob2Offset: CGSize = CGSize(width: 68, height: 0)
    @State private var blob3Offset: CGSize = CGSize(width: 0, height: 68)
    @State private var blobsVisible = true
    @State private var resultVisible = false

    // Use Kubelka-Munk subtractive mixing for paint-like accuracy
    var mixed: Color {
        useThreeColors
            ? ColorMath.mixSubtractive(color1, color2, color3)
            : ColorMath.mixSubtractive(color1, color2)
    }
    var mixedHex: String { ColorMath.colorToHex(mixed) }
    var mixedRGB: RGBValues { let (r,g,b) = ColorMath.colorToRGB(mixed); return RGBValues(r:r,g:g,b:b) }
    var mixedHSL: HSLValues { ColorMath.rgbToHSL(r: mixedRGB.r, g: mixedRGB.g, b: mixedRGB.b) }
    var mixedAsColorItem: ColorItem {
        let m = ColorMath.findClosestColor(r: mixedRGB.r, g: mixedRGB.g, b: mixedRGB.b)
        return ColorItem(name: "Mixed Result", hex: mixedHex, category: m.category,
                         description: "Subtractive paint blend — color-accurate. Closest match: \(m.name).",
                         emotion: m.emotion, keywords: m.keywords)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Reactive tonal background
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    mixed.opacity(0.07).ignoresSafeArea().animation(.easeInOut(duration: 0.5), value: mixed)
                    Circle().fill(mixed.opacity(0.11)).frame(width: 320).blur(radius: 90).offset(y: -220)
                        .animation(.easeInOut(duration: 0.5), value: mixed)
                }

                ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        // Model badge
                        HStack {
                            Spacer()
                            Label("Subtractive Paint Blend", systemImage: "paintpalette.fill")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(.ultraThinMaterial).foregroundStyle(.secondary)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.top, 8)

                        // Mixing arena
                        ZStack {
                            // Anchor for scroll-to
                            // Background glow
                            Circle().fill(mixed).frame(width: 160).blur(radius: 50).opacity(0.3)
                                .animation(.easeInOut(duration: 0.5), value: mixed)

                            if blobsVisible {
                                BlobView(color: color1).frame(width: 104, height: 104)
                                    .offset(blob1Offset)
                                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: blob1Offset)
                                BlobView(color: color2).frame(width: 104, height: 104)
                                    .offset(blob2Offset).opacity(0.88)
                                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: blob2Offset)
                                if useThreeColors {
                                    BlobView(color: color3).frame(width: 92, height: 92)
                                        .offset(blob3Offset).opacity(0.85)
                                        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: blob3Offset)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }

                            if resultVisible {
                                Circle().fill(mixed).frame(width: 108)
                                    .shadow(color: mixed.opacity(0.55), radius: 22)
                                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1.5))
                                    .scaleEffect(resultScale)
                                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                                    .animation(.spring(response: 0.45, dampingFraction: 0.62), value: resultScale)
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showDetail = true
                                    }
                                    .overlay(
                                        Text("Tap")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(mixed.isLight ? .black.opacity(0.5) : .white.opacity(0.6))
                                    )
                            }
                        }
                        .frame(height: 230)
                        .id("mixArena")

                        // Mix button
                        Button { animateMix() } label: {
                            Label(mixComplete ? "Blended ✓" : "Mix Colors",
                                  systemImage: mixComplete ? "checkmark.circle.fill" : "drop.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(mixComplete ? mixed : Color.primary)
                                .foregroundStyle(mixComplete ? (mixed.isLight ? .black.opacity(0.85) : .white) : Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: (mixComplete ? mixed : .primary).opacity(0.28), radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .animation(.spring(), value: mixComplete)

                        // Result card
                        if mixComplete {
                            MixResultCard(
                                mixed: mixed, hex: mixedHex, rgb: mixedRGB, hsl: mixedHSL,
                                showCopied: $showCopied,
                                onDetail: { showDetail = true },
                                onCopy: {
                                    UIPasteboard.general.string = mixedHex
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation { showCopied = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now()+1.5) { withAnimation { showCopied = false } }
                                }
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Color selectors with HEX input option
                        VStack(spacing: 14) {
                            ColorInputRow(label: "Color A", color: $color1, number: 1,
                                         showHex: $showHexEntry1, hexText: $hexInput1,
                                         onChange: resetMix)
                            ColorInputRow(label: "Color B", color: $color2, number: 2,
                                         showHex: $showHexEntry2, hexText: $hexInput2,
                                         onChange: resetMix)
                            if useThreeColors {
                                ColorInputRow(label: "Color C", color: $color3, number: 3,
                                             showHex: $showHexEntry3, hexText: $hexInput3,
                                             onChange: resetMix)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: useThreeColors)

                        // Three-color toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Three-Color Blend").font(.subheadline.weight(.semibold))
                                Text("Mix three colors simultaneously").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $useThreeColors.animation(.spring()))
                        }
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 20)
                        .onChange(of: useThreeColors) { _, _ in resetMix() }

                        // Classic Mixtures — results computed dynamically
                        ClassicMixturesSection { c1hex, c2hex in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                color1 = Color(hex: c1hex)
                                color2 = Color(hex: c2hex)
                                useThreeColors = false
                                resetMix()
                            }
                            // Scroll to top to show mix result
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("mixArena", anchor: .top)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { animateMix() }
                        }
                        .padding(.bottom, 36)
                    }
                    .padding(.top, 8)
                }
                } // end ScrollViewReader
            }
            .navigationTitle("Mix Lab")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showMixInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showDetail) {
                ColorDetailView(item: mixedAsColorItem)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showMixInfo) {
                MixLabHowToView()
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func animateMix() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            blob1Offset = .zero; blob2Offset = .zero; blob3Offset = .zero
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4)) {
                blobsVisible = false; resultVisible = true
                mixComplete = true; resultScale = 1.22
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring()) { resultScale = 1.0 }
            }
        }
    }

    private func resetMix() {
        withAnimation(.spring(response: 0.35)) {
            blobsVisible = true; resultVisible = false; mixComplete = false
        }
        withAnimation(.spring(response: 0.45).delay(0.08)) {
            blob1Offset = CGSize(width: -68, height: 0)
            blob2Offset = CGSize(width: 68, height: 0)
            blob3Offset = CGSize(width: 0, height: 68)
        }
    }
}

// MARK: - Color Input Row (picker + manual HEX entry) — redesigned
struct ColorInputRow: View {
    let label: String
    @Binding var color: Color
    let number: Int
    @Binding var showHex: Bool
    @Binding var hexText: String
    let onChange: () -> Void

    var displayHex: String { ColorMath.colorToHex(color) }
    private var closestName: String {
        let (r, g, b) = ColorMath.colorToRGB(color)
        return ColorMath.findClosestColor(r: r, g: g, b: b).name
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Color swatch — larger rounded rect
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
                    .frame(width: 52, height: 52)
                    .shadow(color: color.opacity(0.45), radius: 8, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(0.6), lineWidth: 2)
                    )
                    .overlay(
                        Text("\(number)").font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(color.isLight ? .black.opacity(0.7) : .white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.subheadline.weight(.bold))
                    Text(displayHex)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\u{2248} \(closestName)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Toggle HEX input
                Button {
                    withAnimation(.spring(response: 0.3)) { showHex.toggle() }
                    if showHex { hexText = displayHex }
                } label: {
                    Image(systemName: showHex ? "keyboard.chevron.compact.down" : "keyboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Color wheel picker
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden().frame(width: 36)
                    .onChange(of: color) { _, _ in onChange() }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            // Manual HEX input
            if showHex {
                HStack(spacing: 10) {
                    TextField("#RRGGBB", text: $hexText)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button("Apply") {
                        let h = hexText.hasPrefix("#") ? hexText : "#\(hexText)"
                        if h.count == 7 {
                            withAnimation(.spring()) {
                                color = Color(hex: h)
                                onChange()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(color)
                    .foregroundStyle(color.isLight ? .black.opacity(0.8) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(.horizontal, 16).padding(.bottom, 14)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.15), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Blob View
struct BlobView: View {
    let color: Color
    @State private var morph: CGFloat = 0
    var body: some View {
        BlobShape(animationProgress: morph).fill(color)
            .shadow(color: color.opacity(0.35), radius: 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { morph = 1 }
            }
    }
}

// MARK: - Mix Result Card
struct MixResultCard: View {
    let mixed: Color; let hex: String; let rgb: RGBValues; let hsl: HSLValues
    @Binding var showCopied: Bool
    let onDetail: () -> Void; let onCopy: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(mixed).frame(height: 76)
                    .shadow(color: mixed.opacity(0.45), radius: 12, y: 5)
                    .animation(.easeInOut(duration: 0.4), value: mixed)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(hex).font(.system(.title2, design: .monospaced, weight: .bold))
                            .foregroundStyle(mixed.isLight ? .black.opacity(0.88) : .white)
                            .contentTransition(.numericText()).animation(.spring(), value: hex)
                        Text(rgb.displayString).font(.system(.caption, design: .monospaced))
                            .foregroundStyle(mixed.isLight ? .black.opacity(0.6) : .white.opacity(0.72))
                    }
                    Spacer()
                    Button(action: onDetail) {
                        Label("Details", systemImage: "info.circle.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(.black.opacity(0.18))
                            .foregroundStyle(mixed.isLight ? .black.opacity(0.7) : .white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                Button(action: onCopy) {
                    Label(showCopied ? "Copied!" : "Copy HEX",
                          systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain).animation(.spring(), value: showCopied)

                VStack(spacing: 1) {
                    Text(hsl.displayString)
                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    Text("HSL Values").font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Classic Mixtures Section (results computed via Kubelka-Munk)
struct ClassicMixturesSection: View {
    let onSelect: (String, String) -> Void
    @State private var showAll = false

    private var visibleMixtures: [ClassicMixture] {
        showAll ? ColorData.classicMixtures : Array(ColorData.classicMixtures.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Classic Mixtures").font(.title3.bold())
                Spacer()
                Text("Tap to apply").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(visibleMixtures) { mix in
                    ClassicMixtureRow(mixture: mix) {
                        onSelect(mix.color1Hex, mix.color2Hex)
                    }
                }
            }
            .padding(.horizontal, 20)

            // See More / Show Less toggle
            if ColorData.classicMixtures.count > 6 {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showAll.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(showAll ? "Show Less" : "See More")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Classic Mixture Row (result computed dynamically)
struct ClassicMixtureRow: View {
    let mixture: ClassicMixture; let onTap: () -> Void

    // Compute the actual result using Kubelka-Munk at display time
    private var computedResultColor: Color {
        ColorMath.mixSubtractive(Color(hex: mixture.color1Hex), Color(hex: mixture.color2Hex))
    }
    private var computedResultHex: String {
        ColorMath.colorToHex(computedResultColor)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Input colors
                HStack(spacing: -10) {
                    Circle().fill(Color(hex: mixture.color1Hex)).frame(width: 34, height: 34)
                        .shadow(color: Color(hex: mixture.color1Hex).opacity(0.4), radius: 4)
                    Circle().fill(Color(hex: mixture.color2Hex)).frame(width: 34, height: 34)
                        .shadow(color: Color(hex: mixture.color2Hex).opacity(0.4), radius: 4)
                }

                Image(systemName: "equal").font(.caption.bold()).foregroundStyle(.tertiary)

                // Result — dynamically computed
                ZStack {
                    Circle().fill(computedResultColor).frame(width: 34, height: 34)
                        .shadow(color: computedResultColor.opacity(0.45), radius: 6)
                    Text(computedResultHex).font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(computedResultColor.isLight ? .black.opacity(0.65) : .white)
                        .shadow(radius: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(mixture.name).font(.subheadline.weight(.semibold))
                    Text(mixture.description).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()

                Image(systemName: "chevron.right").font(.caption2.bold()).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(SpringyButtonStyle())
    }
}

// MARK: - Mix Lab How-To
struct MixLabHowToView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.linearGradient(
                                colors: [Color(hex: "#9B5FE0"), Color(hex: "#FF6B6B")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("How to Mix")
                            .font(.title2.bold())
                        Text("Create new colors by blending")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    mixStepRow(number: 1, icon: "paintpalette.fill",
                               title: "Choose Colors",
                               desc: "Use the color pickers or type a HEX code to set Color A and Color B.")

                    mixStepRow(number: 2, icon: "slider.horizontal.3",
                               title: "Three-Color Blend",
                               desc: "Toggle on to add a third color for more complex mixtures.")

                    mixStepRow(number: 3, icon: "drop.fill",
                               title: "Mix Colors",
                               desc: "Tap the Mix button to blend your colors using realistic paint mixing.")

                    mixStepRow(number: 4, icon: "hand.tap.fill",
                               title: "Explore Result",
                               desc: "Tap the result circle to see full color details, HEX, RGB, and HSL values.")

                    mixStepRow(number: 5, icon: "doc.on.doc",
                               title: "Copy & Use",
                               desc: "Copy the resulting HEX code or browse Classic Mixtures for inspiration.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("How to Mix")
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
    private func mixStepRow(number: Int, icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#9B5FE0").opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "#9B5FE0"))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Step \(number)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#9B5FE0"))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                }
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

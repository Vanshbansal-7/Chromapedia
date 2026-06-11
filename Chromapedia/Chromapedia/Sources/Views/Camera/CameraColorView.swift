// Chromapedia
// Views/Camera/CameraColorView.swift — v3

import SwiftUI
import AVFoundation

struct CameraColorView: View {
    @StateObject private var camera = CameraModel()
    @State private var crosshairPulse = false
    @State private var freezeMode = false
    @State private var frozenInfo: DetectedColorInfo? = nil
    @State private var showCopied = false
    @State private var showDetail = false
    @State private var showIdentifyInfo = false
    @AppStorage("hasSeenIdentifyHowTo") private var hasSeenIdentifyHowTo = false

    private var displayed: DetectedColorInfo { frozenInfo ?? camera.detected }

    private var displayedAsColorItem: ColorItem {
        let m = displayed.closestMatch
        return ColorItem(
            name: "Identified — \(m.name)", hex: displayed.hex,
            category: m.category,
            description: "Scanned from a real-world surface via the camera sensor.",
            emotion: m.emotion, keywords: m.keywords
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if camera.permission == .denied {
                    PermissionDeniedView()
                } else {
                    // Camera feed
                    CameraPreviewView(session: camera.session).ignoresSafeArea()
                        .opacity(freezeMode ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: freezeMode)

                    // Freeze frost overlay
                    if freezeMode {
                        Color.black.opacity(0.25).ignoresSafeArea()
                            .transition(.opacity)
                    }

                    // Crosshair
                    CrosshairView(detectedColor: displayed.color, pulsing: crosshairPulse)

                    // HEX chip top-right
                    VStack {
                        HStack {
                            Spacer()
                            Text(displayed.hex)
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(.ultraThinMaterial).clipShape(Capsule())
                                .padding(.top, 16).padding(.trailing, 16)
                        }
                        if freezeMode {
                            HStack {
                                Capsule().fill(.white.opacity(0.7)).frame(width: 8, height: 8)
                                Text("PAUSED").font(.system(.caption2, design: .monospaced, weight: .heavy))
                                    .tracking(2).foregroundStyle(.white)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Color.black.opacity(0.5)).clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                        }
                        Spacer()
                    }
                    .animation(.spring(), value: freezeMode)

                    // Bottom panel
                    VStack {
                        Spacer()
                        IdentifyResultPanel(
                            info: displayed,
                            freezeMode: $freezeMode,
                            showCopied: $showCopied,
                            onToggleFreeze: {
                                withAnimation(.spring(response: 0.35)) {
                                    freezeMode.toggle()
                                    frozenInfo = freezeMode ? camera.detected : nil
                                }
                            },
                            onCopy: {
                                UIPasteboard.general.string = displayed.hex
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation { showCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now()+1.5) { withAnimation { showCopied = false } }
                            },
                            onObtain: {
                                // "Obtain Color" — open detail page
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showDetail = true
                            }
                        )
                    }
                }
            }
            .navigationTitle("Identify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showIdentifyInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onAppear {
                camera.start(); crosshairPulse = true
                if !hasSeenIdentifyHowTo {
                    showIdentifyInfo = true
                    hasSeenIdentifyHowTo = true
                }
            }
            .onDisappear { camera.stop() }
            .sheet(isPresented: $showDetail) {
                ColorDetailView(item: displayedAsColorItem)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showIdentifyInfo) {
                IdentifyHowToView()
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Identify Result Panel
struct IdentifyResultPanel: View {
    let info: DetectedColorInfo
    @Binding var freezeMode: Bool
    @Binding var showCopied: Bool
    let onToggleFreeze: () -> Void
    let onCopy: () -> Void
    let onObtain: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(.secondary.opacity(0.38)).frame(width: 36, height: 4).padding(.top, 10)

            // Detected color row
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(info.color).frame(width: 66, height: 66)
                    .shadow(color: info.color.opacity(0.5), radius: 12)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.28), value: info.hex)

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.hex)
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .contentTransition(.numericText())
                        .animation(.spring(), value: info.hex)
                    Text(info.rgb.displayString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: info.hex)
                    Label("~\(info.closestMatch.name)", systemImage: "sparkles")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().padding(.horizontal, 20)

            // Action buttons
            HStack(spacing: 10) {
                // Copy HEX
                Button(action: onCopy) {
                    Label(showCopied ? "Copied!" : "Copy HEX",
                          systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(info.color)
                        .foregroundStyle(info.color.isLight ? .black.opacity(0.85) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain).animation(.spring(), value: showCopied)

                // Play/Pause — precise freeze
                Button(action: onToggleFreeze) {
                    Image(systemName: freezeMode ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .background(freezeMode ? Color.white.opacity(0.9) : Color(.secondarySystemFill))
                        .foregroundStyle(freezeMode ? .black : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .animation(.spring(), value: freezeMode)

                // Obtain Color → detail page
                Button(action: onObtain) {
                    Label("Obtain Color", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .padding(.bottom, 14)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12).padding(.bottom, 12)
        .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
    }
}

// MARK: - Crosshair
struct CrosshairView: View {
    let detectedColor: Color; let pulsing: Bool
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.38), lineWidth: 1.5).frame(width: 88, height: 88)
            Circle().stroke(.white, lineWidth: 2).frame(width: 62, height: 62)
            ForEach(0..<4) { i in ReticleCorner().rotationEffect(.degrees(Double(i)*90)) }
            Circle().fill(detectedColor).frame(width: 20, height: 20)
                .shadow(color: detectedColor.opacity(0.7), radius: 8)
                .animation(.easeInOut(duration: 0.25), value: detectedColor)
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            Group {
                Rectangle().fill(.white.opacity(0.55)).frame(width: 1, height: 14).offset(y: -42)
                Rectangle().fill(.white.opacity(0.55)).frame(width: 1, height: 14).offset(y: 42)
                Rectangle().fill(.white.opacity(0.55)).frame(width: 14, height: 1).offset(x: -42)
                Rectangle().fill(.white.opacity(0.55)).frame(width: 14, height: 1).offset(x: 42)
            }
        }
    }
}

struct ReticleCorner: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 11)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: 11, y: 0))
        }
        .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .frame(width: 48, height: 48, alignment: .topLeading)
        .offset(x: 24, y: -24)
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewUIView {
        let v = PreviewUIView(); v.session = session; return v
    }
    func updateUIView(_ v: PreviewUIView, context: Context) { v.session = session }

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var session: AVCaptureSession? {
            didSet { previewLayer.session = session; previewLayer.videoGravity = .resizeAspectFill }
        }
    }
}

// MARK: - Permission Denied
struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "camera.fill").font(.system(size: 52)).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text("Camera Access Required").font(.title2.bold())
                Text("Chromapedia needs camera access to identify real-world colors.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Identify How-To Popup

struct IdentifyHowToView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 44))
                            .foregroundStyle(.linearGradient(
                                colors: [Color(hex: "#9B5FE0"), Color(hex: "#FF6B6B")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("How to Identify")
                            .font(.title2.bold())
                        Text("Detect colors from real-world surfaces")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    identifyStepRow(number: 1, icon: "camera.fill",
                            title: "Point Your Camera",
                            desc: "Aim the camera at any surface or object whose color you want to identify.")

                    identifyStepRow(number: 2, icon: "viewfinder",
                            title: "Align the Crosshair",
                            desc: "Position the crosshair over the exact spot to detect its color in real time.")

                    identifyStepRow(number: 3, icon: "pause.fill",
                            title: "Pause to Lock",
                            desc: "Tap the pause button to freeze the detected color for closer inspection.")

                    identifyStepRow(number: 4, icon: "doc.on.doc",
                            title: "Copy the HEX",
                            desc: "Copy the detected HEX code to your clipboard with a single tap.")

                    identifyStepRow(number: 5, icon: "arrow.right.circle.fill",
                            title: "Obtain Color",
                            desc: "Tap 'Obtain Color' to open the full color detail page with shades, psychology, and more.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("How to Identify")
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
    private func identifyStepRow(number: Int, icon: String, title: String, desc: String) -> some View {
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

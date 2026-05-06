import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = false
    @State private var showProductPicker = false
    @State private var flashOn = false

    var onCapture: (Product) -> Void

    var body: some View {
        ZStack {
            // Camera background
            CameraPreviewRepresentable()
                .ignoresSafeArea()

            // Overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                guideFrame
                Spacer()
                bottomControls
            }

            if isAnalyzing {
                analyzingOverlay
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProductPicker) {
            DemoProductPickerView { product in
                showProductPicker = false
                analyze(product: product)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            Text("라벨 촬영")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                flashOn.toggle()
            } label: {
                Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(flashOn ? Color.yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var guideFrame: some View {
        VStack(spacing: 16) {
            ZStack {
                // Dim overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 300, height: 200)

                // Corner markers
                CornerBrackets()
                    .frame(width: 300, height: 200)

                // Guide text inside frame
                VStack(spacing: 6) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("제품 라벨을 프레임 안에\n맞춰주세요")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }

            Text("라벨 전체가 보이도록 충분히 거리를 두세요")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                Spacer()

                // Demo product picker
                Button {
                    showProductPicker = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                        Text("앨범")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: 60)
                }

                Spacer()

                // Shutter button
                Button {
                    capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color.brandNavy)
                            .frame(width: 60, height: 60)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                // Demo: select product manually
                Button {
                    showProductPicker = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                        Text("데모")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: 60)
                }

                Spacer()
            }
        }
        .padding(.bottom, 48)
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnalyzing)
                }

                VStack(spacing: 8) {
                    Text("라벨 분석 중...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("화학물질 데이터베이스와 비교하고 있어요")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func capturePhoto() {
        // 1단계: 더미 제품으로 처리
        showProductPicker = true
    }

    private func analyze(product: Product) {
        isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAnalyzing = false
            onCapture(product)
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return view }

        let session = AVCaptureSession()
        if session.canAddInput(input) { session.addInput(input) }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Corner Brackets

struct CornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 24
            let t: CGFloat = 3

            ZStack {
                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: len))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: len, y: 0))
                }.stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))

                // Top-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: 0))
                    p.addLine(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: w, y: len))
                }.stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))

                // Bottom-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - len))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: len, y: h))
                }.stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))

                // Bottom-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: w, y: h - len))
                }.stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))
            }
        }
    }
}

// MARK: - Demo Product Picker

struct DemoProductPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (Product) -> Void

    var body: some View {
        NavigationStack {
            List(DummyDataLoader.shared.products) { product in
                Button {
                    onSelect(product)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(product.riskLevel.backgroundColor)
                                .frame(width: 40, height: 40)
                            Image(systemName: product.imageSystemName)
                                .foregroundStyle(product.riskLevel.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Text(product.brand)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        RiskBadge(level: product.riskLevel, size: .small)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("데모 제품 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CameraView(onCapture: { _ in })
}

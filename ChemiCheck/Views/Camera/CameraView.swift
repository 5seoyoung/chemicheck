import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss

    var onCapture: (UIImage) -> Void
    var onDemoSelect: (Product) -> Void

    @State private var isCapturing = false
    @State private var flashOn = false
    @State private var showDemoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var cameraCoordinator = CameraCoordinator()
    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            CameraPreviewRepresentable(coordinator: cameraCoordinator)
                .ignoresSafeArea()

            // 어두운 마스크 (가이드 프레임 외곽)
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .mask(
                    Rectangle()
                        .fill(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .frame(width: 300, height: 200)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                )

            VStack(spacing: 0) {
                topBar
                Spacer()
                guideFrame
                Spacer()
                bottomControls
            }

            if isCapturing {
                analyzingOverlay
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            requestCameraPermission()
        }
        .onDisappear {
            cameraCoordinator.stopSession()
        }
        .alert("카메라 접근 권한 필요", isPresented: $showPermissionAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("갤러리에서 선택") {
                showPermissionAlert = false
            }
            Button("취소", role: .cancel) { dismiss() }
        } message: {
            Text("라벨 촬영을 위해 카메라 접근을 허용해주세요.\n설정 > 케미체크 > 카메라")
        }
        .sheet(isPresented: $showDemoPicker) {
            DemoProductPickerView(onSelect: { product in
                showDemoPicker = false
                onDemoSelect(product)
            })
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { isCapturing = true }
                    onCapture(image)
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
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

            Button { flashOn.toggle(); cameraCoordinator.toggleFlash(flashOn) } label: {
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

    // MARK: - Guide Frame

    private var guideFrame: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    .frame(width: 300, height: 200)

                CornerBrackets()
                    .frame(width: 300, height: 200)

                VStack(spacing: 6) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("제품 라벨을 프레임 안에\n맞춰주세요")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }

            Text("성분표가 보이도록 충분히 거리를 두세요")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))

            // 시뮬레이터 안내
            #if targetEnvironment(simulator)
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text("시뮬레이터에서는 카메라가 지원되지 않아요. 갤러리 또는 데모 버튼을 사용하세요.")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color.yellow.opacity(0.9))
            .padding(.horizontal, 24)
            #endif
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 0) {
            // 갤러리 (PhotosPicker)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                    Text("갤러리")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(width: 70)
            }

            Spacer()

            // 셔터
            Button { capturePhoto() } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 72, height: 72)
                    Circle().fill(Color.brandNavy).frame(width: 60, height: 60)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            // 데모 모드
            Button { showDemoPicker = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                    Text("데모")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(width: 70)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
    }

    // MARK: - Analyzing Overlay

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
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
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isCapturing)
                }
                Text("라벨 전달 중...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - 카메라 권한

    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                    if !granted { showPermissionAlert = true }
                }
            }
        case .denied, .restricted:
            cameraPermission = .denied
            showPermissionAlert = true
        @unknown default:
            break
        }
    }

    // MARK: - 셔터 캡처

    private func capturePhoto() {
        guard cameraPermission == .authorized else {
            showPermissionAlert = true
            return
        }
        isCapturing = true
        cameraCoordinator.capturePhoto { image in
            DispatchQueue.main.async {
                if let img = image {
                    onCapture(img)
                } else {
                    isCapturing = false
                    showDemoPicker = true
                }
            }
        }
    }
}

// MARK: - Camera Coordinator (실기기 캡처 관리)

@Observable
final class CameraCoordinator: NSObject {
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureCompletion: ((UIImage?) -> Void)?

    func setup(for view: UIView) {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        self.session = session
        self.photoOutput = output

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let output = photoOutput else {
            completion(nil)
            return
        }
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.stopRunning()
            self?.session = nil
            self?.photoOutput = nil
        }
    }

    func toggleFlash(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

extension CameraCoordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let image: UIImage?
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        } else {
            image = nil
        }
        captureCompletion?(image)
        captureCompletion = nil
    }
}

// MARK: - Camera Preview (UIKit 래핑)

struct CameraPreviewRepresentable: UIViewRepresentable {
    let coordinator: CameraCoordinator

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        coordinator.setup(for: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Corner Brackets

struct CornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let len: CGFloat = 22, t: CGFloat = 3

            ZStack {
                Path { p in p.move(to: .init(x:0,y:len)); p.addLine(to: .init(x:0,y:0)); p.addLine(to: .init(x:len,y:0)) }
                    .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))
                Path { p in p.move(to: .init(x:w-len,y:0)); p.addLine(to: .init(x:w,y:0)); p.addLine(to: .init(x:w,y:len)) }
                    .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))
                Path { p in p.move(to: .init(x:0,y:h-len)); p.addLine(to: .init(x:0,y:h)); p.addLine(to: .init(x:len,y:h)) }
                    .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))
                Path { p in p.move(to: .init(x:w-len,y:h)); p.addLine(to: .init(x:w,y:h)); p.addLine(to: .init(x:w,y:h-len)) }
                    .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: t, lineCap: .round))
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
                    dismiss()
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
    CameraView(onCapture: { _ in }, onDemoSelect: { _ in })
}

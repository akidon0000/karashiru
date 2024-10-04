//
//  CameraView.swift
//  karashiru
//
//  Created by akidon0000 on 2024/09/29.
//

import AVFoundation
import CoreImage
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
    }
}

final class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let context = CIContext()
    private var imageView: UIImageView!
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    private var filter: CIFilter = CIFilter(name: "CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 1, y: 0, z: 0),
        "inputGVector": CIVector(x: 0, y: 1, z: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 1),
        "inputBiasVector": CIVector(x: 0, y: 0, z: 0)
    ])!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureDeviceSetup()
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }
    
    // フレームの処理
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        calculateFrameRate()
        guard let filteredImage = processImage(from: sampleBuffer) else { return }
        displayImage(filteredImage)
    }
    
    // フレームレートを出力
    private func calculateFrameRate() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - lastFrameTime
        
        if elapsedTime >= 1.0 {
            let fps = Double(frameCount) / elapsedTime
            print("Current FPS: \(fps)")
            frameCount = 0
            lastFrameTime = currentTime
        }
    }
    
    // カメラセッションのセットアップ
    private func captureDeviceSetup() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String: Any]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    // カメラセッションの停止
    private func stopCaptureSession() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    // 画像処理
    private func processImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let filteredImage = applyFilter(to: CIImage(cvPixelBuffer: pixelBuffer)),
              let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage).rotatedBy(degree: 90)
    }
    
    // フィルタ適用
    private func applyFilter(to ciImage: CIImage) -> CIImage? {
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        return filter.outputImage
    }
    
    // 画像表示
    private func displayImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    // UIセットアップ
    private func setupUI() {
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

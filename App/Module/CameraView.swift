//
//  CameraView.swift
//  karashiru
//
//  Created by akidon0000 on 2024/09/29.
//

import SwiftUI
import AVFoundation
import CoreImage
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

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let context = CIContext()
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラセッションの初期化
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        captureSession.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        // 画像表示用のUIImageViewをセットアップ
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        
        captureSession.startRunning()
    }
    
    // フレームの処理
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // モノクロフィルター（CIPhotoEffectNoir）を適用
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = filter?.outputImage,
              let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else { return }
        
        DispatchQueue.main.async {
            let uiImage = UIImage(cgImage: cgImage)
            self.imageView.image = uiImage  // UIImageViewにフィルター後の画像を表示
        }
    }
}

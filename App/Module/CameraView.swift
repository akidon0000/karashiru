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

final class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let context = CIContext()
    private var imageView: UIImageView!
    private var num = 0
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    private var filter = CIFilter(name: "CIPhotoEffectNoir")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureDeviceSetup()
        setupUI()
        loadFilters()
        //        listAllCIFilters()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let captureSession = captureSession else { return }
        captureSession.stopRunning()
        self.captureSession = nil
    }
    
    // CIFilterの一覧を取得して出力する関数
    private func listAllCIFilters() {
        // カテゴリーに依存せず、すべてのフィルターを取得
        let allFilters = CIFilter.filterNames(inCategories: nil)
        
        print("===== CIFilter 一覧 =====")
        print(allFilters.count)
        for filterName in allFilters {
            // フィルターの詳細情報を取得
            if let filter = CIFilter(name: filterName) {
                print("フィルター名: \(filterName)")
                print("属性: \(filter.attributes)")
                print("----------------------------")
            }
        }
    }
    
    // フレームの処理
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        calculateFrameRate()
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = filter?.outputImage,
              let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else { return }
        
        DispatchQueue.main.async {
            let uiImage = UIImage(cgImage: cgImage)
            self.imageView.image = uiImage.rotatedBy(degree: 90)  // UIImageViewにフィルター後の画像を表示
        }
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
    
    private func captureDeviceSetup() {
        // カメラセッションの初期化
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.sessionPreset = .photo
        
        // Input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)
        
        // Output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    private let tableView = UITableView()
    private var originalImage: UIImage?
    private var allFilters: [String] = []
    
    // UIのセットアップ
    private func setupUI() {
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // TableViewの設定
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Auto Layoutの設定
        NSLayoutConstraint.activate([
            // 画像を上部に表示
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),  // 水平方向に中央揃え
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),  // 幅を画面幅の50%に
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),  // 高さを50%に設定
            
            // TableViewを下部に配置
            tableView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // フィルターをロード
    private func loadFilters() {
        allFilters = CIFilter.filterNames(inCategories: nil)
        tableView.reloadData()
    }
    
    // TableViewのデリゲートとデータソースメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allFilters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = allFilters[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFilterName = allFilters[indexPath.row]
        filter = CIFilter(name: selectedFilterName)
    }
}

extension UIImage {
    func rotatedBy(degree: CGFloat) -> UIImage {
        let w = self.size.width
        let h = self.size.height
        
        //写し先を準備
        let s = CGSize(width: h, height: w)
        UIGraphicsBeginImageContext(s)
        let context = UIGraphicsGetCurrentContext()!
        //中心点
        context.translateBy(x: h / 2, y: w / 2)
        context.scaleBy(x: -1.0, y: 1.0)  // X軸方向に反転
        //Y軸を反転させる
        context.scaleBy(x: 1.0, y: -1.0)
        
        //回転させる
        let radian = -degree * CGFloat.pi / 180
        context.rotate(by: radian)
        
        //書き込み
        let rect = CGRect(x: -(h / 2), y: -(w / 2), width: h, height: w)
        context.draw(self.cgImage!, in: rect)
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}

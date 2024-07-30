//
//  UltraSlowFrameByFrame.swift
//  CaptureSampleApp
//
//  Created by AK on 7/29/24.
//

import Foundation
import AVFoundation
import UIKit
import Photos


class UltraSlowFrameByFrameController: UIViewController {
    private var ultraSlowMoCapture: UltraSlowMoCaptureFrameByFrame!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ultraSlowMoCapture = UltraSlowMoCaptureFrameByFrame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ultraSlowMoCapture.attachPreview(to: self.view)
        ultraSlowMoCapture.startCapture()
        startButton.setTitle("Start", for: .normal)
        self.view.bringSubviewToFront(startButton)
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ultraSlowMoCapture.stopCapture()
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        
        ultraSlowMoCapture.startSaving = !ultraSlowMoCapture.startSaving
        
//        if ultraSlowMoCapture.startSaving {
//            ultraSlowMoCapture.startCapture()
//            
//        }
//        else {
//            ultraSlowMoCapture.stopCapture()
//        }
        
        startButton.setTitle(ultraSlowMoCapture.startSaving ? "Stop" : "Start", for: .normal)
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        ultraSlowMoCapture.stopCapture()
    }
}


class UltraSlowMoCaptureFrameByFrame: NSObject {
    var startSaving: Bool = false
     var session: AVCaptureSession!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice!
    private var dataOutputSynchronizer: AVCaptureDataOutputSynchronizer!
    
    override init() {
        super.init()
        setupCaptureSession()
        requestPhotoLibraryAccess()
    }
    
    private func setupCaptureSession() {
        session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        videoDevice = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            dataOutputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoOutput])
            dataOutputSynchronizer.setDelegate(self, queue: DispatchQueue(label: "syncQueue"))
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            try camera.lockForConfiguration()
            
            for vFormat in camera.formats {
                
                // 2
                var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
                var frameRates = ranges[0]
                
                // 3
                if frameRates.maxFrameRate == 240 {
                    
                    // 4
                    try! camera.lockForConfiguration()
                    camera.activeFormat = vFormat
                    camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 240)
                    //backCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                    camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 240)
                    camera.unlockForConfiguration()
                    
                    self.videoDevice = camera
                    
                }
            }
            
            
            if let supportedFrameRateRange = camera.activeFormat.videoSupportedFrameRateRanges.first(where: { $0.maxFrameRate >= 240 }) {
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(supportedFrameRateRange.maxFrameRate))
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(supportedFrameRateRange.maxFrameRate))
                print("Set frame rate to \(supportedFrameRateRange.maxFrameRate) fps")
            } else {
                print("240 fps not supported, using default frame rate")
            }
            
            camera.unlockForConfiguration()
            
        } catch {
            print("Error configuring camera: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    func attachPreview(to view: UIView) {
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    func startCapture() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
        
    }
    
    func stopCapture() {
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Photo Library access granted")
            case .denied, .restricted, .notDetermined:
                print("Photo Library access denied")
            @unknown default:
                print("Unknown Photo Library access status")
            }
        }
    }
    
    private func saveFrameToPhotos(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(saveError), nil)
    }
    
    @objc private func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error)")
        } else {
            print("Successfully saved image to Photos")
        }
    }
}

extension UltraSlowMoCaptureFrameByFrame: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Save the pixelBuffer to Photos
        if startSaving {
            saveFrameToPhotos(pixelBuffer: pixelBuffer)}
        print("Captured frame at \(Date())")
    }
}

extension UltraSlowMoCaptureFrameByFrame: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        guard let videoData = synchronizedDataCollection.synchronizedData(for: videoOutput) as? AVCaptureSynchronizedSampleBufferData,
              !videoData.sampleBufferWasDropped else { return }
        
        captureOutput(videoOutput, didOutput: videoData.sampleBuffer, from: videoOutput.connection(with: .video)!)
    }
}

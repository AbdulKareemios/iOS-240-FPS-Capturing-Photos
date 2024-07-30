//
//  MetalViewController.swift
//  CaptureSampleApp
//
//  Created by AK on 7/28/24.
//

import Foundation
import AVFoundation
import Metal
import MetalKit
import UIKit
import Photos

class MetalViewController: UIViewController {
    
    
    
    private var highFPSCapture: HighFPSCapture!

        override func viewDidLoad() {
            super.viewDidLoad()
            highFPSCapture = HighFPSCapture()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            highFPSCapture.attachPreview(to: self.view)
            highFPSCapture.startCapture()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            highFPSCapture.stopCapture()
        }
}

class HighFPSCapture: NSObject {
    private var session: AVCaptureSession!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        
        let devices = AVCaptureDevice.devices()
        for device in devices {
            // 2
            if (device.hasMediaType(.video)) {
                // 3
                if(device.position == .back) {
                    // 4
                    captureDevice = device
                    // 5
                    if captureDevice != nil {
                        setupCaptureSession()
                        requestPhotoLibraryAccess()
                    }
                }
            }
        }
        
        setupCaptureSession()
        requestPhotoLibraryAccess()
    }

    private func setupCaptureSession() {
        session = AVCaptureSession()
        session.beginConfiguration()

        //guard let camera = AVCaptureDevice.default(for: .video) else { return }
        if let camera = captureDevice {
            
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
                
                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.videoGravity = .resizeAspectFill
                
                
                
                
                
                for vFormat in camera.formats {
                    
                    // 2
                    var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
                    var frameRates = ranges[0]
                    
                    // 3
                    if frameRates.maxFrameRate == 240 {
                    
                    // 4
//                    try! camera.lockForConfiguration()
//                    camera.activeFormat = vFormat
//                    camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 240)
//                    camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 240)
//                    
//                    camera.unlockForConfiguration()
                    
                    
                    //let maxFrameRate = min(supportedFrameRateRange.maxFrameRate, 240)
                    try camera.lockForConfiguration()
                    //camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(1))
                    camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(240))
                    camera.unlockForConfiguration()
                    print("Set frame rate to \(camera.activeVideoMaxFrameDuration) fps")
                    break
                    }
                }
                
//                try camera.lockForConfiguration()
//                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 240)
//                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 240)
//                camera.unlockForConfiguration()
                
            } catch {
                print("Error configuring camera: \(error)")
            }
            
            session.commitConfiguration()
        }
    }

    func attachPreview(to view: UIView) {
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    func startCapture() {
        session.startRunning()
    }

    func stopCapture() {
        session.stopRunning()
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

extension HighFPSCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Save the pixelBuffer to Photos
        //saveFrameToPhotos(pixelBuffer: pixelBuffer)
        print("Captured frame at \(Date())")
    }
}


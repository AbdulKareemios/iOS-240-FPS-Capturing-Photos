//
//  UltraSlowMoCapture.swift
//  CaptureSampleApp
//
//  Created by AK on 7/29/24.
//

import Foundation
import AVFoundation
import UIKit
import Photos

class UltraSlowMoViewController: UIViewController {
    private var ultraSlowMoCapture: UltraSlowMoCapture!
    
    @IBOutlet weak var startButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        ultraSlowMoCapture = UltraSlowMoCapture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ultraSlowMoCapture.attachPreview(to: self.view)
        ultraSlowMoCapture.startCapture()
        self.view.bringSubviewToFront(startButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ultraSlowMoCapture.stopCapture()
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        if ultraSlowMoCapture.movieOutput.isRecording {
            ultraSlowMoCapture.stopRecording()
        }
        else {
            ultraSlowMoCapture.startRecording()
        }
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        ultraSlowMoCapture.stopRecording()
    }
}

class UltraSlowMoCapture: NSObject {
    
    private var session: AVCaptureSession!
     var movieOutput: AVCaptureMovieFileOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice!
    
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
            
            movieOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            try camera.lockForConfiguration()
            
            
            //for device in camera.formats {
                
                //if let formats = device.formats {
                    
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
                //}
            //}
            
            
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
        session.startRunning()
    }
    
    func stopCapture() {
        session.stopRunning()
    }
    
    func startRecording() {
        let outputFilePath = NSTemporaryDirectory().appending("tempMovie12321321.mov")
        let outputURL = URL(fileURLWithPath: outputFilePath)
        
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
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
    
    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            if let error = error {
                print("Error saving video: \(error)")
            } else {
                print("Successfully saved video to Photos")
            }
        }
    }
}

extension UltraSlowMoCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error)")
        } else {
            saveVideoToPhotos(url: outputFileURL)
        }
    }
}

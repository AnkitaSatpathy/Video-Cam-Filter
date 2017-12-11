//
//  ViewController.swift
//  MyCameraFilters
//
//  Created by Ankita Satpathy on 25/11/17.
//  Copyright © 2017 Ankita Satpathy. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices


let NoirEffect = "Noir Effect"
let NoirEffectFilter = CIFilter(name: "CIPhotoEffectNoir")

let SepiaTone = "SepiaTone"
let SepiaToneFilter = CIFilter(name: "CISepiaTone")

let Edges = "Edges"
let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 1])

let HexagonalPixellate = "Hex Pixellate"
let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 1])

let Pointillize = "Pointillize"
let PointillizeFilter = CIFilter(name: "CIPointillize", withInputParameters: ["inputRadius" : 1])

let Filters = [
    NoirEffect: NoirEffectFilter,
    SepiaTone: SepiaToneFilter,
    Edges: EdgesEffectFilter,
    HexagonalPixellate: HexagonalPixellateFilter,
    Pointillize: PointillizeFilter]

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var cImageView: UIImageView!
    @IBOutlet weak var camButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioInput: AVCaptureDeviceInput?
    var dataOutput:AVCaptureVideoDataOutput?
    var movieOutput: AVCaptureMovieFileOutput?
    var isBackCamera = true
    let FilterNames = [String](Filters.keys).sorted()
    var index = 0
    var videoURL:URL?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         loadCamera()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecogniser()
    }

    
    func addGestureRecogniser() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = .right
        self.topView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = .left
        self.topView.addGestureRecognizer(swipeLeft)
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
                if pageControl.currentPage != 0{
                   pageControl.currentPage -= 1
                    index = pageControl.currentPage
                    print(index)
                }
            case UISwipeGestureRecognizerDirection.left:
                if pageControl.currentPage != 4{
                   print("Swiped left")
                  pageControl.currentPage += 1
                  index = pageControl.currentPage
                    print(index)
                }
            default:
                break
            }
        }
    }
    
    func loadCamera() {
        captureSession?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        
        var captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
       
        if isBackCamera {
            if let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] {
                for device in videoDevices {
                    if device.position == AVCaptureDevice.Position.back {
                        captureDevice = device
                        break
                    }
                }
            }
        }
        
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSession.Preset.high
            captureSession?.beginConfiguration()
            captureSession?.addInput(input)
    
            audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            movieOutput = AVCaptureMovieFileOutput()
            captureSession?.addInput(audioInput!)
            dataOutput = AVCaptureVideoDataOutput()
            dataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))

            dataOutput?.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            dataOutput?.alwaysDiscardsLateVideoFrames = true
            
            captureSession?.addOutput(dataOutput!)
            //captureSession?.addOutput(movieOutput!)
            captureSession?.commitConfiguration()
            let connection = dataOutput?.connection(with: AVMediaType.video)
            connection?.videoOrientation = .portrait
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            //videoPreviewLayer?.frame = cImageView.layer.bounds
            videoPreviewLayer?.frame = view.layer.bounds
//            cImageView.layer.addSublayer(videoPreviewLayer!)
            captureSession?.startRunning()
        } catch  {
            print(error)
        }
        
    }
    

    @IBAction func camButtonTapped(_ sender: Any) {
        guard let  recordOutput = movieOutput else{
            print("Capture session is null")
            return
        }

        if recordOutput.isRecording {
            movieOutput?.stopRecording()
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths.first?.appendingPathComponent("output.mov")

            try? FileManager.default.removeItem(at: fileUrl!)
            recordOutput.startRecording(to: fileUrl!, recordingDelegate: self)
        }
    }
    
    @IBAction func saveBtnTapped(_ sender: Any) {
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let filter = Filters[FilterNames[index]] else
        {
            return
        }
      
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)

        filter!.setValue(cameraImage, forKey: kCIInputImageKey)
       // effect?.setValue(1, forKey: kCIInputIntensityKey)
        if let filteredImage = filter!.value(forKey: kCIOutputImageKey) as? CIImage{
            let output = context.createCGImage(filteredImage, from: filteredImage.extent)
            DispatchQueue.main.async {
                self.cImageView.image = UIImage(cgImage: output!)
            
            }
            
        }
    }
    
    
}

extension ViewController :AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("RECORDING STARTED")
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("RECORDING STOPPED")
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
}

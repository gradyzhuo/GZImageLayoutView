//
//  GZCameraView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/28/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation

enum GZCameraViewDevicePosition:String, Hashable{
    
    case Unspecified = "Unspecified"
    case Back = "Back"
    case Front = "Front"
    
    var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    init(position:AVCaptureDevicePosition){
        
        switch position {
            
        case .Back:
            self = .Back
        case .Front:
            self = .Front
        case .Unspecified:
            self = .Unspecified
            
        }
        
    }
    
}

enum GZCameraLayerVideoGravity{
    
    case Resize
    case Aspect
    case AspectFill
    
    func AVLayerVideoGravity()->String!{
        
        switch self{
            
        case .Resize:
            return AVLayerVideoGravityResize
        case .Aspect:
            return AVLayerVideoGravityResizeAspect
        case .AspectFill:
            return AVLayerVideoGravityResizeAspectFill
        }
        
    }
    
}

class GZCameraView: UIView {
    
    var sessionPreset : String! {
        
        set{
            self.captureSession.sessionPreset = sessionPreset
        }
        
        get{
            return self.captureSession.sessionPreset
        }
    }
    
    private lazy var captureSession:AVCaptureSession = {
        var session = AVCaptureSession()
        
        session.addOutput(self.stillImageOutput)
        
        
        return session
    }()
    
    private var input:AVCaptureDeviceInput!{
        didSet{
            
            self.captureSession.removeInput(oldValue)
            self.captureSession.addInput(input)
            
        }
    }
    
    private var stillImageOutput:AVCaptureStillImageOutput = AVCaptureStillImageOutput(){
        didSet{
            self.captureSession.removeOutput(oldValue)
            self.captureSession.addOutput(stillImageOutput)
        }
    }
    
    private var currentCaptureDevice:AVCaptureDevice!
    
    private lazy var captureLayer:AVCaptureVideoPreviewLayer = {
        
        var layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = self.videoGravity.AVLayerVideoGravity()
        self.layer.addSublayer(layer)
        
        return layer
    }()
    
    var videoGravity:GZCameraLayerVideoGravity = .AspectFill {
        didSet{
            self.captureLayer.videoGravity = videoGravity.AVLayerVideoGravity()
        }
    }
    
    var isCurrentCaptureDeviceAvailable:Bool{
        return self.currentCaptureDevice != nil
    }
    
    var opened:Bool = true{
        didSet{
            if opened {
                self.captureSession.startRunning()
                self.hidden = false
                
            }else{
                self.captureSession.stopRunning()
                self.hidden = true
            }
        }
    }
    
    
    var devicePosition:GZCameraViewDevicePosition {
        get{
            if self.currentCaptureDevice == nil {
                return GZCameraViewDevicePosition.Unspecified
            }
            return GZCameraViewDevicePosition(position:  self.currentCaptureDevice.position)
            
        }
    }
    
    lazy var availableCameraDevice:[GZCameraViewDevicePosition:AVCaptureDevice] = {
        
        var deviceList:[GZCameraViewDevicePosition:AVCaptureDevice] = [:]
        var videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as [AVCaptureDevice]
        
        videoDevices.map({ (device:AVCaptureDevice) -> Void in
            
            if device.position == .Back {
                deviceList[GZCameraViewDevicePosition.Back] = device
            }
            if device.position == .Front {
                deviceList[GZCameraViewDevicePosition.Front] = device
            }
            
        })
        
        return deviceList
        }()
    
    
    var flashMode:AVCaptureFlashMode = AVCaptureFlashMode.Auto {
        didSet{
            
            
            
            if let currentCaptureDevice = self.currentCaptureDevice {
                
                if self.flashAvailable {
                    
                    var error:NSError?
                    
                    currentCaptureDevice.lockForConfiguration(&error)
                    currentCaptureDevice.flashMode = flashMode
                    currentCaptureDevice.unlockForConfiguration()
                    
                    if error != nil {
                        
                        println("set flashMode error:\(error?.localizedDescription)")
                        
                    }
                    
                }
                
            }
            
        }
    }
    
    var flashAvailable:Bool {
        get{
            
            if let currentCaptureDevice = self.currentCaptureDevice {
                return currentCaptureDevice.flashAvailable
            }
            
            return false
        }
    }
    
    var focusMode:AVCaptureFocusMode = AVCaptureFocusMode.AutoFocus {
        
        didSet{
            
            if let currentCaptureDevice = self.currentCaptureDevice {
                
                var error:NSError?
                
                currentCaptureDevice.lockForConfiguration(&error)
                currentCaptureDevice.focusMode = focusMode
                
                currentCaptureDevice.unlockForConfiguration()
                
                if error != nil {
                    
                    println("set focusMode error:\(error?.localizedDescription)")
                    
                }
                
            }
            
        }
        
        
    }
    
    override init() {
        super.init()
        
        self.configure()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.captureLayer.frame = self.layer.bounds
        
    }
    
    func configure(){
        
        self.changeDevicePosition()
//        self.openCamera()
        
    }
    
    func isDeviceAvailable(position:GZCameraViewDevicePosition)->Bool {
        var device = self.availableCameraDevice[position]
        return device != nil
    }
    
    func changeDevicePosition(position:GZCameraViewDevicePosition = .Back){
        
        self.captureSession.inputs.map { self.captureSession.removeInput($0 as AVCaptureInput) }
        
        self.currentCaptureDevice = self.availableCameraDevice[position]
        
        var error:NSError?
        var input = AVCaptureDeviceInput(device: self.currentCaptureDevice, error: &error)
        
        if error != nil {
            println("error:\(error?.localizedDescription)")
        }else{
            
            self.captureSession.addInput(input)
        }
        
    }
    
    
    func takePhoto(completionHandler:(image:UIImage?, metaData:[NSObject:AnyObject]!, error:NSError!)->Void){
        
        self.stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        var connection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (sampleBuffer:CMSampleBuffer!, error:NSError!) -> Void in
            
            if let sampleBuffer = sampleBuffer {
                
                var data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                
//                completionHandler(image: UIImage(data: data))
//                completionHandler(originalData: data, image: UIImage(data: data), metaData: [:])
                completionHandler(image: UIImage(data: data), metaData: [:], error: error)
            }
            
        })
        
        
        
    }
    
    func takePhoto(completionHandler:(imageData:NSData, metaData:[NSObject:AnyObject]!, error:NSError!)->Void){
        
        
        
        if self.isCurrentCaptureDeviceAvailable {
            
            self.stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            
            var connection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (sampleBuffer:CMSampleBuffer!, error:NSError!) -> Void in
                
                if let sampleBuffer = sampleBuffer {
                    
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    completionHandler(imageData: imageData, metaData: [:], error: error)
                    //                completionHandler(originalData: data, image: UIImage(data: data), metaData: [:])
                    
                }
                
            })
            
        }
        
        
        
        
        
    }
    
    
    func openCamera(force:Bool = false){
        
        if force {
            self.captureSession.stopRunning()
        }
        
        self.opened = true
        
    }
    
    func closeCamera(){
        self.opened = false
    }
    
    
}

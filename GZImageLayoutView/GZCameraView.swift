//
//  GZCameraView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/28/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation

public enum GZCameraViewDevicePosition:String, Hashable{
    
    case Unspecified = "Unspecified"
    case Back = "Back"
    case Front = "Front"
    
    public var hashValue: Int {
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

public enum GZCameraLayerVideoGravity{
    
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

public class GZCameraView: UIView {
    
    var sessionPreset : String! {
        
        set{
            self.captureSession.sessionPreset = sessionPreset
        }
        
        get{
            return self.captureSession.sessionPreset
        }
    }
    
    internal lazy var captureSession:AVCaptureSession = {
        var session = AVCaptureSession()
        
        session.addOutput(self.stillImageOutput)
        
        
        return session
    }()
    
    internal var input:AVCaptureDeviceInput!{
        didSet{
            
            self.captureSession.removeInput(oldValue)
            self.captureSession.addInput(input)
            
        }
    }
    
    internal var stillImageOutput:AVCaptureStillImageOutput = AVCaptureStillImageOutput(){
        didSet{
            self.captureSession.removeOutput(oldValue)
            self.captureSession.addOutput(stillImageOutput)
        }
    }
    
    internal var currentCaptureDevice:AVCaptureDevice!
    
    internal lazy var captureLayer:AVCaptureVideoPreviewLayer = {
        
        var layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = self.videoGravity.AVLayerVideoGravity()
        self.layer.addSublayer(layer)
        
        return layer
    }()
    
    public var videoGravity:GZCameraLayerVideoGravity = .AspectFill {
        didSet{
            self.captureLayer.videoGravity = videoGravity.AVLayerVideoGravity()
        }
    }
    
    public var isCurrentCaptureDeviceAvailable:Bool{
        return self.currentCaptureDevice != nil
    }
    
    public var opened:Bool = true{
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
    
    
    public var devicePosition:GZCameraViewDevicePosition {
        get{
            if self.currentCaptureDevice == nil {
                return GZCameraViewDevicePosition.Unspecified
            }
            return GZCameraViewDevicePosition(position:  self.currentCaptureDevice.position)
            
        }
    }
    
    public lazy var availableCameraDevice:[GZCameraViewDevicePosition:AVCaptureDevice] = {
        
        var deviceList:[GZCameraViewDevicePosition:AVCaptureDevice] = [:]
        var videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
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
    
    
    public var flashMode:AVCaptureFlashMode = AVCaptureFlashMode.Auto {
        didSet{
            
            if let currentCaptureDevice = self.currentCaptureDevice {
                
                if self.flashAvailable {
                    
                    var error:NSError?
                    
                    currentCaptureDevice.lockForConfiguration(&error)
                    
                    if error != nil {
                        
                        println("set flashMode error:\(error?.localizedDescription)")
                        
                    }
                    
                    currentCaptureDevice.flashMode = flashMode
                    currentCaptureDevice.unlockForConfiguration()
                    
                }
                
            }
            
        }
    }
    
    public var flashAvailable:Bool {
        get{
            
            if let currentCaptureDevice = self.currentCaptureDevice {
                return currentCaptureDevice.flashAvailable
            }
            
            return false
        }
    }
    
    public var focusMode:AVCaptureFocusMode = AVCaptureFocusMode.AutoFocus {
        
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
    
    public init() {
        super.init(frame : CGRect.zeroRect)
        self.configure()
        
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configure()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure()
    }
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.captureLayer.frame = self.layer.bounds
        
    }
    
    internal func configure(){
        
        self.changeDevicePosition()
//        self.openCamera()
        self.flashMode = AVCaptureFlashMode.Auto
        
    }
    
    public func isDeviceAvailable(position:GZCameraViewDevicePosition)->Bool {
        var device = self.availableCameraDevice[position]
        return device != nil
    }
    
    public func changeDevicePosition(position:GZCameraViewDevicePosition = .Back){
        
        self.captureSession.inputs.map { self.captureSession.removeInput($0 as! AVCaptureInput) }
        
        self.currentCaptureDevice = self.availableCameraDevice[position]
        
        var error:NSError?
        var input = AVCaptureDeviceInput(device: self.currentCaptureDevice, error: &error)
        
        if error != nil {
            println("error:\(error?.localizedDescription)")
        }else{
            
            self.captureSession.addInput(input)
        }
        
    }
    
    
    public func takePhoto(completionHandler:(image:UIImage?, metaData:[NSObject:AnyObject]!, error:NSError!)->Void){
        
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
    
    public func takePhotoImageData(completionHandler:(imageData:NSData?, metaData:[NSObject:AnyObject]!, error:NSError!)->Void){
        
        
        
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
    
    
    public func openCamera(force:Bool = false){
        
        if force {
            self.captureSession.stopRunning()
        }
        
        self.opened = true
        
    }
    
    public func closeCamera(){
        self.opened = false
    }
    
    
}

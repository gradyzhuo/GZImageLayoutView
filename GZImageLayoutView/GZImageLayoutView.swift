//
//  GZImageLayoutView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/22/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation

public class GZImageLayoutView: UIView {
    
    internal var privateObjectInfo:ObjectInfo
    
    public var imageMetaDataContent:[String:UIImage] = [:]
    
    public var delegate:GZImageLayoutViewDelegate?
    
    public var metaData:GZLayoutViewMetaData?{
        
        get{
            return GZLayoutViewMetaData(layoutView: self)
        }
        
        set{
            
            if let newMetaData = newValue {
                
                var layout:GZLayout = newMetaData.layout
                
                self.imageMetaDataContent = newMetaData.imagesMetaData.content
                
                self.relayout(layout)
                
                for positionMetaData in newMetaData.imagesMetaData.positionMetaDatas {
                    
                    var positionView:GZImageEditorPositionView = self.positionView(forIdentifier: positionMetaData.identifier) as GZImageEditorPositionView
                    positionView.metaData = positionMetaData
                    
                }
                
//                for (position, image) in self.privateObjectInfo.imageMetaData {
//                    
//                    self.setImage(image, forPosition: position)
//                    
//                }
            }
            
        }
        
    }
    
    public var layout:GZLayout{
        get{
            return self.privateObjectInfo.layout
        }
    }
    
    public var positionViews:[String:GZImageEditorPositionView] = [:]
    public var positionViewDelegate:GZImageEditorPositionViewDelegate?{
        didSet{
            for (identifier, positionView) in self.positionViews{
                positionView.delegate = positionViewDelegate
            }
        }
    }
    
    
    
    public var cameraView:GZCameraView{
        return self.highlighView.cameraView
    }
    
    public var positionIdentifiers:[String] {
        return self.layout.positions.map { return $0.identifier }
    }
    
    public var canHighlight:Bool = true {
        didSet{
            
            if !canHighlight {
                
                self.borderView.hidden = false
                self.highlighView.hidden = true
//                self.privateObjectInfo.currentPosition = nil
                
            } else {
                self.borderView.hidden = true
//                self.currentPosition = self.layout.positions.first
                self.highlighView.hidden = false
                
            }
            
        }
    }
    
    
    public var currentPosition:GZPosition{
        return self.privateObjectInfo.currentPosition ?? self.layout.positions.first!
    }
    
    public var highlighView:GZHighlightView = GZHighlightView()
    
    internal lazy var borderView:GZHighlightBorderView = {
        
        var border = GZHighlightBorderView()
        
        return border
        
        }()
    
    public var borderColor:UIColor{
        
        set{
            self.borderView.borderColor = newValue
        }
        
        get{
            return self.borderView.borderColor
        }
        
    }
    
    public var borderHidden:Bool = false {
        didSet{
            self.setBorderHidden(borderHidden)
        }
    }
    
    public func setBorderHidden(borderHidden:Bool, animated:Bool = false){
        
        let handler = { () in
            
            self.borderView.alpha = borderHidden ? 0.0 : 1.0
            
        }
        
        if animated {
            UIView.animateWithDuration(0.3, animations: handler)
        }else{
            handler()
        }
        
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.privateObjectInfo = ObjectInfo()
        
        super.init(coder: aDecoder)
        
        self.configure(self.layout)
        
    }
    
    
    public init(layout:GZLayout, frame:CGRect = CGRect()){
        
        self.privateObjectInfo = ObjectInfo()
        
        super.init(frame:frame)
        
        self.configure(layout)
        
    }
    
    private func configure(layout:GZLayout){
        
        self.relayout(layout)
        self.changeCurrentPosition(layout.positions.first)
        
        
        self.borderView.hidden = true
        self.borderView.borderColor = UIColor.grayColor()
        
        self.addSubview(self.borderView)
        self.addSubview(highlighView)
        
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        

//        self.borderView.bezierPath = self.borderBezierPath.copy() as! UIBezierPath
        self.borderView.layout = self.layout
        self.borderView.frame = self.bounds
        
        self.highlighView.applyMask(self.bounds.size)
        
        for identifier in self.positionIdentifiers {
            var positionView = self.positionViews[identifier]
            
            
            var idx = find(self.positionIdentifiers, identifier) ?? 0
            positionView?.position = layout.positions[idx]
            positionView?.applyMask(self.frame.size)

        }
        
//        for i in 0 ..< self.positionViews.count {
//            
//            var positionView = self.positionViews[i]
//            
//            positionView.position = layout.positions[i]
//            positionView.applyMask(self.frame.size)
//            
//        }
        
        
    }
    

    public func positionView(forIdentifier identifier:String)->GZImageEditorPositionView! {

        return self.positionViews[identifier] //filtedPositionViews.first
        
    }
    
    public func setImage(image:UIImage?, forPosition identifier:String){
        
        var positionView = self.positionView(forIdentifier: identifier)
        
        positionView?.image = image
        
    }
    
    public func imageForPosition(identifier:String)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: identifier)
        return positionView?.image
        
    }
    
    public func imageForPosition(position:GZPosition)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: position.identifier)
        return positionView?.image
        
    }
    
    public func setHighlightPositionIdentifier(identifier:String){
        
        var position = self.layout.position(forIdentifier: identifier)
        self.changeCurrentPosition(position)
        
    }
    
    internal func changeCurrentPosition(position:GZPosition?){
        
        if let position = position {
            
            self.privateObjectInfo.currentPosition = position
            
            self.highlighView.position = currentPosition
            self.highlighView.applyMask(self.bounds.size)
            
            self.delegate?.layoutViewDidChangeHighlightPosition(self, didChangeToPosition: self.currentPosition)
        }
        
    }
    
    
    public func relayout(layout:GZLayout){
        
        
        var imagesMetaDataContent = self.imageMetaDataContent
        
        for (identifier,positionView) in self.positionViews{
            
            positionView.removeFromSuperview()
            
        }
        
        self.positionViews.removeAll(keepCapacity: false)
        
        for position in layout.positions {
            
            var identifier = position.identifier
            
            var positionView = GZImageEditorPositionView(layoutView: self, position: position)
            positionView.delegate = self.positionViewDelegate
            self.addSubview(positionView)
            
            
            positionView.applyMask(self.bounds.size)
            positionView.image = imagesMetaDataContent[identifier]//positionViewMetaData.image
            
            self.positionViews[position.identifier] = positionView
            
        }
        
        if let position = layout.position(forIdentifier: currentPosition.identifier){
            self.changeCurrentPosition(position)
        }else{
            self.changeCurrentPosition(layout.positions.first)
        }
        
        self.bringSubviewToFront(self.borderView)
        self.bringSubviewToFront(self.highlighView)
        
        self.privateObjectInfo.layout = layout
        
    }
    
    override public func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        
        var hitView = super.hitTest(point, withEvent: event)
        
        if !self.canHighlight {
            return hitView
        }
        
        do{
            
            hitView = hitView?.superview
            if hitView is GZPositionView {
                
                return hitView
            }
            
        }while  hitView != nil
        
        return hitView
    }
    
    //MARK: Object Info Struct
    
    internal struct ObjectInfo{
        
        var layout:GZLayout = GZLayout.fullLayout()
        var currentPosition:GZPosition! = nil
        
    }
    
    //MARK: Touch Event Handler
    
    
    override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        var anyTouch = touches.first as! UITouch
        var location = anyTouch.locationInView(self)
        
    }
    
    
    override public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        var anyTouch = touches.first as! UITouch
        
        var currentLocation = anyTouch.locationInView(self)
        var previoudLocation = anyTouch.previousLocationInView(self)
        
        var previousTouchScope = CGRect(x: previoudLocation.x - 8, y: previoudLocation.y - 8, width: 16, height: 16)
        
        
        if previousTouchScope.contains(currentLocation) {
            
            var positionView:GZPositionView? = self.hitTest(currentLocation, withEvent: event) as? GZPositionView
            self.changeCurrentPosition(positionView?.position)
            
        }
        
        
    }
    
}

//MARK: - 

public extension GZImageLayoutView {
    
    public func swapPositionMetaDatas(id:String, _ other:String) {
        
        var positionEditorView = self.positionView(forIdentifier: id)
        var otherPositionEditorView = self.positionView(forIdentifier: other)
        
        var metaData = positionEditorView.metaData
        var otherMetaData = otherPositionEditorView.metaData
        otherPositionEditorView.metaData = metaData
        positionEditorView.metaData = otherMetaData
        
    }
    
}





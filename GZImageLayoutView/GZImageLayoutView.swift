//
//  GZImageLayoutView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/22/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation


struct GZScrollViewMetaData {
    
    var contentSize:CGSize
    var contentOffset:CGPoint
    var zoomScale:CGFloat
    var frame:CGRect
    var imageRatio:CGFloat
    
    init(scrollView:UIScrollView, imageRatio ratio:CGFloat){
        self.contentSize = scrollView.contentSize
        self.contentOffset = scrollView.contentOffset
        self.zoomScale = scrollView.zoomScale
        self.frame = scrollView.frame
        self.imageRatio = ratio
    }
    
    var cropInfo:GZCropInfo{
        
        var contentOffset = self.contentOffset
        var zoomScale = self.zoomScale
        var imageRatio = self.imageRatio
        
        var scrollViewSize = self.frame.size
        
//        var cropRatio = zoomScale / imageRatio
        
        var cropWidth = scrollViewSize.width / zoomScale / imageRatio
        var cropHeight = scrollViewSize.height / zoomScale / imageRatio
        var cropX = contentOffset.x / zoomScale / imageRatio
        var cropY = contentOffset.y / zoomScale / imageRatio
        
        return GZCropInfo(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
    }
    
}

struct GZPositionViewImageMetaData{
    var identifier:String
    var image:UIImage!
}

struct GZCropInfo:Printable, DebugPrintable{
    
    let bounds:CGRect

    let angle:CGFloat
    
    var x:CGFloat{
        return self.bounds.minX
    }
    
    var y:CGFloat{
        return self.bounds.minY
    }
    
    var width:CGFloat{
        return self.bounds.width
    }
    
    var height:CGFloat{
        return self.bounds.height
    }
    
    
    init(rect:CGRect, angle:CGFloat){
        self.bounds = rect
        self.angle = angle
    }
    
    init(x:CGFloat, y:CGFloat, width:CGFloat, height:CGFloat, angle:CGFloat){
        
        self.bounds = CGRect(x: x, y: y, width: width, height: height)
        self.angle = angle
        
    }
    
    init(x:CGFloat, y:CGFloat, width:CGFloat, height:CGFloat){
        
        self.bounds = CGRect(x: x, y: y, width: width, height: height)
        self.angle = 0
    }
    
    var description: String {
        return "GZCropInfo:{x:\(self.bounds.minX), y:\(self.bounds.minY), width:\(self.bounds.width), height:\(self.bounds.height), angle:\(self.angle)}"
    }
    
    var debugDescription: String {
        return self.description
    }
    
}


struct GZPositionViewMetaData : Equatable {
    
    var imageMetaData:GZPositionViewImageMetaData
    var scrollViewMetaData:GZScrollViewMetaData
    
    var identifier:String{
        return self.imageMetaData.identifier
    }
    
    var image:UIImage?{
        return self.imageMetaData.image
    }
    
    var cropInfo:GZCropInfo{
        return self.scrollViewMetaData.cropInfo
    }
    
}

func ==(lhs: GZPositionViewMetaData, rhs: GZPositionViewMetaData) -> Bool{
    var lhsImage = lhs.image ?? UIImage()
    return (lhs.identifier == rhs.identifier) && lhsImage.isEqual(rhs.image)
}

struct GZLayoutViewImagesMetaData {
    
    var positionMetaDatas:[GZPositionViewMetaData]
    
    public var content:[String:UIImage]{
        
        var content:[String:UIImage] = [:]
        for positionMetaData in self.positionMetaDatas{
            content[positionMetaData.identifier] = positionMetaData.image
        }
        
        return content
    }
    
    var numberOfImages:Int{
        return self.positionMetaDatas.count
    }
    
    var identifiers:[String]{
        return self.positionMetaDatas.map { return $0.identifier }
    }
    
    var cropInfos:[GZCropInfo]{
        return self.positionMetaDatas.map{ return $0.cropInfo }
    }
    
    func image(forPosition identifier:String)->UIImage!{
        
        if let index = find(self.identifiers, identifier) {
            
            var positionMetaData = self.positionMetaDatas[index]
            return positionMetaData.image
            
        }
        
        return nil
    }
    
    
    func positionViewMetaData(forPosition identifier:String)->GZPositionViewMetaData!{
        
        if let index = find(self.identifiers, identifier) {
            
            var positionMetaData = self.positionMetaDatas[index]
            return positionMetaData
            
        }
        
        return nil
    }
    
    func isExist(forPosition identifier:String)->Bool{
        return find(self.identifiers, identifier) != nil
    }
    

    init(positionViews:[String:GZImageEditorPositionView]){
        
        var positionMetaDatas:[GZPositionViewMetaData] = []
        
        for (identifier, positionView) in positionViews {
            positionMetaDatas.append(positionView.metaData)
        }
        
        self.positionMetaDatas = positionMetaDatas
        
    }
    
}

struct GZLayoutViewMetaData{
    
    
    var layout:GZLayout
    var imagesMetaData:GZLayoutViewImagesMetaData
    
    var numerOfPositions:Int{
        return self.imagesMetaData.numberOfImages
    }
    
    var cropInfos:[GZCropInfo]{
        return self.imagesMetaData.cropInfos
    }
    
    private init(layoutView:GZImageLayoutView){
        
        self.imagesMetaData = GZLayoutViewImagesMetaData(positionViews: layoutView.positionViews)
        self.layout = layoutView.layout
        
        
    }
    
}

class GZImageLayoutView: UIView {
    
    private var privateObjectInfo:ObjectInfo
    
    var imageMetaDataContent:[String:UIImage] = [:]
    
    var delegate:GZImageLayoutViewDelegate?
    
    var metaData:GZLayoutViewMetaData?{
        
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
    
    var layout:GZLayout{
        get{
            return self.privateObjectInfo.layout
        }
    }
    
    var positionViews:[String:GZImageEditorPositionView] = [:]
    var positionViewDelegate:GZImageEditorPositionViewDelegate?{
        didSet{
            for (identifier, positionView) in self.positionViews{
                positionView.delegate = positionViewDelegate
            }
        }
    }
    
    
    
    var cameraView:GZCameraView{
        return self.highlighView.cameraView
    }
    
    var positionIdentifiers:[String] {
        return self.layout.positions.map { return $0.identifier }
    }
    
    var canHighlight:Bool = true {
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
    
    
    var currentPosition:GZPosition{
        return self.privateObjectInfo.currentPosition ?? self.layout.positions.first!
    }
    
    var highlighView:GZHighlightView = GZHighlightView()
    
//    private var borderBezierPath:UIBezierPath {
//        get{
//            
//            var borderBezierPath = UIBezierPath()
//            
//            for position in self.layout.positions {
//                
//                borderBezierPath = position.layoutPoints.reduce(borderBezierPath, combine: { (bezierPath:UIBezierPath, pointUnit:GZLayoutPointUnit) -> UIBezierPath in
//                    pointUnit.applyToBezierPath(bezierPath)
//                    return bezierPath
//                })
//                
//            }
//            
//            borderBezierPath.closePath()
//            
//            return borderBezierPath
//        }
//    }
    
    private lazy var borderView:GZHighlightBorderView = {
        
        var border = GZHighlightBorderView()
        
        return border
        
        }()
    
    var borderColor:UIColor{
        
        set{
            self.borderView.borderColor = newValue
        }
        
        get{
            return self.borderView.borderColor
        }
        
    }
    
    var borderHidden:Bool = false {
        didSet{
            self.setBorderHidden(borderHidden)
        }
    }
    
    func setBorderHidden(borderHidden:Bool, animated:Bool = false){
        
        let handler = { () in
            
            self.borderView.alpha = borderHidden ? 0.0 : 1.0
            
        }
        
        if animated {
            UIView.animateWithDuration(0.3, animations: handler)
        }else{
            handler()
        }
        
    }
    
    required init(coder aDecoder: NSCoder) {
        self.privateObjectInfo = ObjectInfo()
        
        super.init(coder: aDecoder)
        
        self.configure(self.layout)
        
    }
    
    
    init(layout:GZLayout, frame:CGRect = CGRect()){
        
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
    
    override func layoutSubviews() {
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
    

    func positionView(forIdentifier identifier:String)->GZImageEditorPositionView! {

        return self.positionViews[identifier] //filtedPositionViews.first
        
    }
    
    func setImage(image:UIImage?, forPosition identifier:String){
        
        var positionView = self.positionView(forIdentifier: identifier)
        
        positionView?.image = image
        
    }
    
    func imageForPosition(identifier:String)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: identifier)
        return positionView?.image
        
    }
    
    func imageForPosition(position:GZPosition)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: position.identifier)
        return positionView?.image
        
    }
    
    func setHighlightPositionIdentifier(identifier:String){
        
        var position = self.layout.position(forIdentifier: identifier)
        self.changeCurrentPosition(position)
        
    }
    
    private func changeCurrentPosition(position:GZPosition?){
        
        if let position = position {
            
            self.privateObjectInfo.currentPosition = position
            
            self.highlighView.position = currentPosition
            self.highlighView.applyMask(self.bounds.size)
            
            self.delegate?.layoutViewDidChangeHighlightPosition(self, didChangeToPosition: self.currentPosition)
        }
        
    }
    
    
    func relayout(layout:GZLayout){
        
        
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
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        
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
    
    private struct ObjectInfo{
        
        var layout:GZLayout = GZLayout.fullLayout()
        var currentPosition:GZPosition! = nil
        
    }
    
    //MARK: Touch Event Handler
    
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        var anyTouch = touches.first as! UITouch
        var location = anyTouch.locationInView(self)
        
    }
    
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
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

extension GZImageLayoutView {
    
    func swapPositionMetaDatas(id:String, _ other:String) {
        
        var positionEditorView = self.positionView(forIdentifier: id)
        var otherPositionEditorView = self.positionView(forIdentifier: other)
        
        var metaData = positionEditorView.metaData
        var otherMetaData = otherPositionEditorView.metaData
        otherPositionEditorView.metaData = metaData
        positionEditorView.metaData = otherMetaData
        
    }
    
}





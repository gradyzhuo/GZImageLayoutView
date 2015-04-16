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
    
    private var content:[String:UIImage]{
        
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
    
    var delegate:GZImageLayoutViewDelegate?
    
    var metaData:GZLayoutViewMetaData?{
        
        get{
            return GZLayoutViewMetaData(layoutView: self)
        }
        
        set{
            
            if let newMetaData = newValue {
                
                var layout:GZLayout = newMetaData.layout
                
                self.privateObjectInfo.imageMetaDataContent = newMetaData.imagesMetaData.content
                
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
    
    private var borderBezierPath:UIBezierPath {
        get{
            
            var borderBezierPath = UIBezierPath()
            
            for position in self.layout.positions {
                
                borderBezierPath = position.layoutPoints.reduce(borderBezierPath, combine: { (bezierPath:UIBezierPath, pointUnit:GZLayoutPointUnit) -> UIBezierPath in
                    pointUnit.applyToBezierPath(bezierPath)
                    return bezierPath
                })
                
            }
            
            borderBezierPath.closePath()
            
            return borderBezierPath
        }
    }
    
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
        
        var borderBezierPath = UIBezierPath()
        borderBezierPath.appendPath(self.borderBezierPath)
        borderBezierPath.applyTransform(CGAffineTransformMakeScale(self.bounds.width, self.bounds.height))
        
        self.borderView.bezierPath = borderBezierPath
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
        
        
        var imagesMetaDataContent = self.privateObjectInfo.imageMetaDataContent
        
        for (identifier,positionView) in self.positionViews{
            
            positionView.removeFromSuperview()
            
        }
        
        self.positionViews.removeAll(keepCapacity: false)
        
        for position in layout.positions {
            
            var identifier = position.identifier
            
            var positionView = GZImageEditorPositionView(position: position)
            positionView.layoutView = self
            
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
        var imageMetaDataContent:[String:UIImage] = [:]
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

class GZPositionView: UIView {
    
    var position:GZPosition! = GZPosition.fullPosition(){
        didSet{
            if position == nil {
                
                self.layer.mask = nil
                self.frame = CGRect()
                
            }
        }
    }
    
    var identifier:String {
        return self.position.identifier
    }
    
    var maskBezierPath:UIBezierPath!
    
    private var layoutView:GZImageLayoutView? = nil
    
    init(position:GZPosition! = nil, frame:CGRect = CGRect()){
        super.init(frame:frame)
        
        self.configure(position)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure(nil)
        
    }
    
    func configure(position:GZPosition!){
        self.position = position
    }
    
    func applyMask(size:CGSize){
        
        var maskLayer = CAShapeLayer()
        
        if let position = self.position{
            self.maskBezierPath = UIBezierPath()
            self.maskBezierPath.appendPath(self.position.maskBezierPath)
            self.maskBezierPath.applyTransform(CGAffineTransformMakeScale(size.width, size.height))
            maskLayer.path = self.maskBezierPath.CGPath
            
        }
        
        self.layer.mask = maskLayer
        
        //決定position的位置
        var bezierPath = UIBezierPath()
        bezierPath.appendPath(self.position.bezierPath)
        
        bezierPath.applyTransform(CGAffineTransformMakeScale(size.width, size.height))
        
        self.frame = bezierPath.bounds
        
        self.layoutIfNeeded()
    }
    
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        if let maskLayer = self.layer.mask as? CAShapeLayer {
            
            var borderBeizerPath = UIBezierPath(CGPath: maskLayer.path)
            return borderBeizerPath.containsPoint(point)
            
        }
        
        return false
    }
    
}

class GZImageEditorPositionView:GZPositionView {
    
    let minZoomScale : CGFloat = 1.0
    let maxZoomScale : CGFloat = 3.0
    
    var imageRatio : CGFloat = 1.0
    
    private var privateObjectInfo = ObjectInfo()
    
    var metaData:GZPositionViewMetaData{
        
        set{
            
            self.imageMetaData = newValue.imageMetaData
            self.scrollViewMetaData = newValue.scrollViewMetaData
            
            self.privateObjectInfo.metaData = newValue
        }
        
        get{
            
            self.privateObjectInfo.metaData = GZPositionViewMetaData(imageMetaData: self.imageMetaData, scrollViewMetaData: self.scrollViewMetaData)
            
            return self.privateObjectInfo.metaData
        }
    }
    
    var scrollViewMetaData:GZScrollViewMetaData{
        
        set{
            self.scrollView.zoomScale = newValue.zoomScale
            self.scrollView.contentSize = newValue.contentSize
            self.scrollView.contentOffset = newValue.contentOffset
        }
        
        get{
            return GZScrollViewMetaData(scrollView: self.scrollView, imageRatio: self.imageRatio)
        }
        
    }
    
    var imageMetaData:GZPositionViewImageMetaData{
        
        set{
            self.setImage(newValue.image, needResetScrollView: true)
        }
        
        get{
            return GZPositionViewImageMetaData(identifier: self.identifier, image: self.image)
        }
        
    }
    
    var image:UIImage?{
        
        set{
            self.setImage(newValue, needResetScrollView: true)
        }
        
        get{
            return self.imageView.image
        }

    }
    
    private lazy var scrollView:UIScrollView = {
        
        var scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.delegate = self
        
        scrollView.minimumZoomScale = self.minZoomScale
        scrollView.maximumZoomScale = self.maxZoomScale
        
        
        return scrollView
    }()
    
    private lazy var imageView:UIImageView = {
        
        var imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        
        return imageView
    }()
    
    override func configure(position: GZPosition!) {
        super.configure(position)
        
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.imageView)
        
        
        self.scrollView.frame = self.bounds
        
    }
    
    private override var layoutView:GZImageLayoutView?{
        
        didSet{
            
            var image = layoutView?.imageForPosition(self.identifier)
            
            if image == nil && self.image != nil {
                layoutView?.setImage(self.image, forPosition: self.identifier)
            }
        }
        
    }
    
    func setImage(image:UIImage?, needResetScrollView reset:Bool){
        
        self.imageView.image = image
        
        if reset{
            self.resetScrollView(self.scrollView, image: image)
        }
        
        if let parentLayoutView = self.layoutView {
            
            var imageMetaData = parentLayoutView.privateObjectInfo.imageMetaDataContent
            
            if let newImage = image {
                imageMetaData[self.identifier] = newImage
            }else{
                imageMetaData.removeValueForKey(self.identifier)
            }
            
            parentLayoutView.privateObjectInfo.imageMetaDataContent = imageMetaData
            
        }
        
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = self.bounds
        
        var metaData = self.privateObjectInfo.metaData ?? self.metaData
        self.imageMetaData = metaData.imageMetaData
        self.scrollViewMetaData = metaData.scrollViewMetaData
        
    }
    
    
    struct ObjectInfo {
        var metaData:GZPositionViewMetaData! = nil
    }
    
}

//MARK: - Crop & Resize support

extension GZImageEditorPositionView : UIScrollViewDelegate {
    
    private func resetScrollView(scrollView:UIScrollView, image:UIImage?){
        
        self.initializeScrollView(scrollView)
        
        if let vaildImage = image{
            
            //預先取出所需的屬性值
            let scrollViewWidth = scrollView.frame.width
            let scrollViewHeight = scrollView.frame.height
            let vaildImageWidth = vaildImage.size.width
            let vaildImageHeight = vaildImage.size.height
            
            
            //看scrollView的 width > height or width < height 決定那一邊要為基準
            
            var targetSize = scrollView.contentSize
            
            var ratio:CGFloat = 1.0
            
            if scrollViewWidth > scrollViewHeight {
                
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                ratio = scrollViewWidth / vaildImageWidth
                
                //
                targetSize = CGSize(width:scrollViewWidth , height: vaildImageHeight * ratio)
                
                
            }else if scrollViewWidth < scrollViewHeight {
                
                //以scrollView的height為基準計算image原始size與scrollView size的ratio，以便算出相對應的width
                ratio = scrollViewHeight / vaildImageHeight
                
                //
                targetSize = CGSize(width:vaildImageWidth * ratio , height: scrollViewHeight)
                
            }else{
                
                //如果ScrollView是正方形的情況
                //就要改判斷image的原始size，來進行調整，不過基準以image的最短邊拉大的方式計算
                if vaildImageWidth > vaildImageHeight {
                    
                    //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                    ratio = scrollViewHeight / vaildImageHeight
                    
                    //
                    targetSize = CGSize(width:vaildImageWidth * ratio , height: scrollViewHeight)
                    
                }else{
                    
                    //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                    ratio = scrollViewWidth / vaildImageWidth
                    
                    //
                    targetSize = CGSize(width:scrollViewWidth , height: vaildImageHeight * ratio)
                    
                }
                
                
                
            }
            
            self.imageRatio = ratio
            //
            scrollView.contentSize = targetSize
            
            //
            self.imageView.frame.size = targetSize
            
            let xOffsetToCenter:CGFloat = (targetSize.width - scrollViewWidth)/2
            let yOffsetToCenter:CGFloat = (targetSize.height - scrollViewHeight)/2
            
            scrollView.contentOffset.x += xOffsetToCenter
            scrollView.contentOffset.y += yOffsetToCenter
            
            
        }
        
    }
    
    private func initializeScrollView(scrollView:UIScrollView, contentSize:CGSize = CGSizeZero){
        
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = CGPointZero
        scrollView.contentSize = CGSizeZero
        
    }
    
    
    //MARK: scroll view delegate
    internal func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        println(println("scrollViewDidZoom:\(scrollView.zoomScale)"))
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
        println("scrollViewWillBeginZooming:\(scrollView.zoomScale)")
        
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        println("scrollViewDidEndZooming:\(scrollView.zoomScale)")
    }
    
    
}


//MARK: - GZHighlightView

class GZHighlightView: GZPositionView {
    
    var componentConstraints:[String:[AnyObject]] = [:]
    
    private lazy var borderView:GZHighlightBorderView = {
        var borderView = GZHighlightBorderView()
        borderView.setTranslatesAutoresizingMaskIntoConstraints(false)
        return borderView
    }()
    
    private lazy var cameraView:GZCameraView = {
        
        var cameraView = GZCameraView()
        cameraView.userInteractionEnabled = false
        cameraView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        return cameraView
    }()
    
    var borderColor:UIColor{
        
        set{
            self.borderView.borderColor = newValue
        }
        
        get{
            return self.borderView.borderColor
        }
        
    }
    
    override func configure(position: GZPosition!) {
        super.configure(position)
        
        self.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        self.userInteractionEnabled = false
        
        self.addSubview(self.cameraView)
        self.addSubview(self.borderView)
        
        self.setNeedsUpdateConstraints()
        
    }
    
    
    override func applyMask(size: CGSize) {
        super.applyMask(size)
        
        self.borderView.bezierPath = self.maskBezierPath
        self.setNeedsLayout()
        
    }
    
    
    override func updateConstraints() {
        super.updateConstraints()
        
        self.removeConstraints(self.componentConstraints["CameraView"] ?? [])
        self.removeConstraints(self.componentConstraints["BorderView"] ?? [])
        
        var constraints = [AnyObject]()
        
        var metrics:[NSObject:AnyObject] = [:]
        metrics["super_margin_left"] = self.layoutMargins.left
        metrics["super_margin_right"] = self.layoutMargins.right
        metrics["super_margin_top"] = self.layoutMargins.top
        metrics["super_margin_bottom"] = self.layoutMargins.bottom
        
        var viewsDict:[NSObject:AnyObject] = ["camera_view":self.cameraView, "border_view":self.borderView]
        
        var vCameraViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-super_margin_top-[camera_view]-super_margin_bottom-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: viewsDict)
        var hCameraViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-super_margin_left-[camera_view]-super_margin_right-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: viewsDict)
        
        var cameraConstraints = [] + vCameraViewConstraints + hCameraViewConstraints

        
        self.componentConstraints["CameraView"] = cameraConstraints
        
        constraints += cameraConstraints
        
        var vBorderViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-super_margin_top-[border_view]-super_margin_bottom-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: viewsDict)
        var hBorderViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-super_margin_left-[border_view]-super_margin_right-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: viewsDict)
        
        var borderConstraints = [] + vBorderViewConstraints + hBorderViewConstraints
        
        self.componentConstraints["BorderView"] = borderConstraints
        
        constraints += borderConstraints
        
        self.addConstraints(constraints)
        
        
    }
    
    
}

/** 主要呈現出外框用 */
class GZHighlightBorderView: UIView {
    
    var borderColor:UIColor = UIColor.blackColor(){
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var bezierPath:UIBezierPath = UIBezierPath(){
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame : CGRect.zeroRect)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.setNeedsDisplay()
        
    }
    
    
    func setup(){
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }
    
    
    override func drawRect(rect: CGRect) {
        
        var borderBeizerPath = UIBezierPath()
        borderBeizerPath.appendPath(self.bezierPath)
        
        borderBeizerPath.lineWidth = 3.0
        self.borderColor.setStroke()
        borderBeizerPath.stroke()
        
        
    }
    
}

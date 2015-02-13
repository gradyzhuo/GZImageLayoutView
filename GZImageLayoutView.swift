//
//  GZImageLayoutView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/22/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation


protocol Keyable:Hashable, Equatable{
    
}

extension CGPoint {
    
    private init(pointOfLayout point:[CGFloat], multiple value:CGFloat = 1){
        
        self.x = CGFloat(point[0]) * value
        self.y = CGFloat(point[1]) * value
        
    }
    
    private func __pointByMultiple(value:CGSize)->CGPoint{
        
        var copy = self
        copy.x *= value.width
        copy.y *= value.height
        
        return copy
        
    }
    
    private func __pointByOffset(value:CGPoint)->CGPoint{
        
        var copy = self
        copy.x += value.x
        copy.y += value.y
        
        
        return copy
        
    }
    
    var __flipPoint:CGPoint{
        return CGPoint(x: -self.x, y: -self.y)
    }
    
}


enum GZLayoutPointUnit{
    
    init(dataDict:[NSObject:AnyObject]) {
        
        var type = dataDict["type"] as String
        //        var point = CGPoint(pointOfLayout: dataDict["point"] as [CGFloat])
        
        self.init(type:type, point:dataDict["point"] as [CGFloat])
        
    }
    
    
    init(type:String, point:[CGFloat]){
        
        var point = CGPoint(pointOfLayout: point)
        self.init(type:type, point:point)
        
    }
    
    init(type:String, point:CGPoint){
        
        switch type {
        case "line":
            self = GZLayoutPointUnit.Line(point)
            
            /* 曲線暫時不支援       case "curve":
            
            var control1 = CGPoint(pointOfLayout: dataDict["point"] as [CGFloat] )
            var control2 = CGPoint(pointOfLayout: dataDict["point"] as [CGFloat] )
            
            self = GZLayoutPoint.Curve(point, control1, control2)
            */
        default:
            self = GZLayoutPointUnit.Undefined
            
        }
        
    }
    
    case Undefined
    case Line(CGPoint)
    //    case Curve(CGPoint,CGPoint,CGPoint)
    
    var point:CGPoint{
        switch self {
            
        case .Line(var point):
            return point
            //        case .Curve(var point, var control1, var control2):
            //            return point
        case .Undefined:
            return CGPoint()
        }
    }
    
}


//let kGZImageLayoutJSONLayoutIdentifierName = "identifier"
let kGZPositionIdentifierDefaultFull = "Full"
let kGZPositionFullLayout:GZPosition = GZPosition.fullPosition()


class GZPosition {
    
    private var privateObjectInfo:ObjectInfo = ObjectInfo()
    
    var identifier:String{
        return self.privateObjectInfo.identifier
    }
    
    var layoutPoints:[GZLayoutPointUnit]{
        
        return self.privateObjectInfo.layoutPoints
        
        
    }
    
    private class func fullPosition()->GZPosition {
        
        var leftTopPointUnit = GZLayoutPointUnit.Line(CGPoint(x: 0, y: 0))
        var leftBottomPointUnit = GZLayoutPointUnit.Line(CGPoint(x: 0, y: 1))
        var rightBottomPointUnit = GZLayoutPointUnit.Line(CGPoint(x: 1, y: 1))
        var rightTopPointUnit = GZLayoutPointUnit.Line(CGPoint(x: 1, y: 0))
        
        return GZPosition(identifier: kGZPositionIdentifierDefaultFull, layoutPoints: [leftTopPointUnit, leftBottomPointUnit, rightBottomPointUnit, rightTopPointUnit])
        
    }
    
    var bezierPath:UIBezierPath {
        
        var firstPoint = self.layoutPoints.first?.point ?? CGPoint()
        
        var bezier = UIBezierPath()
        bezier.moveToPoint(firstPoint)
        
        var filtedPoint = self.layoutPoints.filter{ return $0.point != firstPoint }
        
        bezier = filtedPoint.reduce(bezier, combine: { (bezierPath:UIBezierPath, pointUnit:GZLayoutPointUnit) -> UIBezierPath in
            bezier.addLineToPoint(pointUnit.point)
            return bezier
        })
        
        
        bezier.closePath()
        
        return bezier
    }
    
    var maskBezierPath:UIBezierPath{
        
        var firstPoint = self.layoutPoints.first?.point ?? CGPoint()
        var bezierPath = UIBezierPath()
        bezierPath.appendPath(self.bezierPath)
        
        bezierPath.applyTransform(CGAffineTransformMakeTranslation(firstPoint.__flipPoint.x, firstPoint.__flipPoint.y))
        
        return bezierPath
    }
    
    convenience init(dataDict:[NSObject:AnyObject]) {
        
        var points:[GZLayoutPointUnit] = (dataDict["points"] as [[NSObject:AnyObject]]).map{ return GZLayoutPointUnit(dataDict: $0)}
        var identifier:String = dataDict["position"] as String
        
        self.init(identifier:identifier, layoutPoints:points )
        
    }
    
    init(identifier:String, layoutPoints:[GZLayoutPointUnit]){
        
        self.privateObjectInfo.identifier = identifier
        self.privateObjectInfo.layoutPoints = layoutPoints
        
    }
    
    func frame(multiple:CGSize)->CGRect{
        return CGRect()
    }
    
    private struct ObjectInfo {
        
        var identifier:String = kGZPositionIdentifierDefaultFull
        var layoutPoints:[GZLayoutPointUnit] = []
        
    }
    
    
}

class GZLayout {
    
    //    var contexts:[[NSObject:AnyObject]] = []
    
    var identifier:String{
        
        if self.privateObjectInfo.identifier == nil {
            var identifier = "Layout::"
            for position in self.positions {
                identifier += "\(position.bezierPath.hashValue)::"
            }
            
            return identifier
        }
        
        return self.privateObjectInfo.identifier
    }
    
    private var privateObjectInfo:ObjectInfo = ObjectInfo()
    
    //    class func emptyLayout()->GZLayout{
    //
    //        var layout = GZLayout(json: nil)
    //
    //
    //        return
    //    }
    
    class func fullLayout()->GZLayout {
        
        var layout = GZLayout()
        layout.privateObjectInfo.positions = [GZPosition.fullPosition()]
        
        return layout
    }
    
    
    var positions:[GZPosition] {
        return self.privateObjectInfo.positions
    }
    
    convenience init(){
        
        var position:[GZPosition] = []
        
        self.init(positions:position)
        
    }
    
    
    convenience init(jsonString:String!){
        
        var jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        self.init(jsonData:jsonData)
        
    }
    
    convenience init(jsonData:NSData!, options:NSJSONReadingOptions = NSJSONReadingOptions.AllowFragments, error:NSErrorPointer = nil){
        
        var jsonObject: [String:AnyObject]? = NSJSONSerialization.JSONObjectWithData(jsonData, options: options, error: error) as? [String:AnyObject]
        self.init(jsonObject:jsonObject ?? [:])
    }
    
    convenience init(jsonObject:[String:AnyObject]){
        
        var identifier:String! = jsonObject["identifier"] as String
        var originalPositions = jsonObject["positions"] as [[NSObject:AnyObject]]
        var position:[GZPosition] = originalPositions.map{GZPosition(dataDict: $0)}
        
        self.init(identifier: identifier, positions:position)
        
    }
    
    convenience init(positions:[GZPosition]) {
        self.init(identifier:nil, positions:positions)
        
    }
    
    init(identifier:String!, positions:[GZPosition]) {
        self.privateObjectInfo.identifier = identifier
        self.privateObjectInfo.positions = positions
        
    }
    
    
    func position(forIdentifier identifier:String)->GZPosition! {
        
        var filtedPositionViews = self.positions.filter{ return ($0 as GZPosition).identifier == identifier  }
        return filtedPositionViews.first
    }
    
    
    private struct ObjectInfo{
        var identifier:String! = nil
        var positions:[GZPosition] = []
        
    }
    
    
}


let GZImageLayoutViewMetaDataLayoutKey = "GZImageLayoutViewMetaDataLayoutKey"
let GZImageLayoutViewMetaDataImagesKey = "GZImageLayoutViewMetaDataImagesKey"


struct GZScrollViewMetaData {
    
    var contentSize:CGSize
    var contentOffset:CGPoint
    var zoomScale:CGFloat
    
    init(scrollView:UIScrollView){
        self.contentSize = scrollView.contentSize
        self.contentOffset = scrollView.contentOffset
        self.zoomScale = scrollView.zoomScale
    }
    
}

struct GZPositionViewImageMetaData{
    var identifier:String
    var image:UIImage!
}

struct GZPositionViewMetaData : Equatable {
    
    var imageMetaData:GZPositionViewImageMetaData
    var scrollViewMetaData:GZScrollViewMetaData
    
    var identifier:String{
        return self.imageMetaData.identifier
    }
    
    var image:UIImage{
        return self.imageMetaData.image
    }
    
    var contentSize:CGSize{
        return self.scrollViewMetaData.contentSize
    }
    
    var contentOffset:CGPoint{
        return self.scrollViewMetaData.contentOffset
    }
    
    var zoomScale:CGFloat{
        return self.scrollViewMetaData.zoomScale
    }
    
}

func ==(lhs: GZPositionViewMetaData, rhs: GZPositionViewMetaData) -> Bool{
    return (lhs.identifier == rhs.identifier) && lhs.image.isEqual(rhs.image)
}

struct GZLayoutViewImagesMetaData {
    
    let positionMetaDatas:[GZPositionViewMetaData]
    
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
    
    func image(forPosition identifier:String)->UIImage!{
        
        if let index = find(self.identifiers, identifier) {
            
            var positionMetaData = self.positionMetaDatas[index]
            return positionMetaData.image
            
        }
        
        return nil
    }
    
    func isExist(forPosition identifier:String)->Bool{
        return find(self.identifiers, identifier) != nil
    }
    

    init(positionViews:[String:GZPositionEditView]){
        
        var positionMetaDatas:[GZPositionViewMetaData] = []
        
        for (identifier, positionView) in positionViews {
            positionMetaDatas.append(positionView.metaData)
        }
        
        self.positionMetaDatas = positionMetaDatas
        
    }
    
}

struct GZLayoutViewMetaData{
    
//    private var content:[NSObject:AnyObject]
    
    var layout:GZLayout
    let imagesMetaData:GZLayoutViewImagesMetaData
    
    var numerOfPositions:Int{
        return self.imagesMetaData.numberOfImages
    }
    
    
    private init(layoutView:GZImageLayoutView){
        
        self.imagesMetaData = GZLayoutViewImagesMetaData(positionViews: layoutView.positionViews)
        self.layout = layoutView.layout
        
        
    }
    
}


protocol GZImageLayoutViewDelegate{
    func layoutViewDidChangeHighlightPosition(layoutView:GZImageLayoutView, didChangeToPosition position:GZPosition?)
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
                
                self.privateObjectInfo.imageMetaData = newMetaData.imagesMetaData.content
                
                self.relayout(layout)
                
                for positionMetaData in newMetaData.imagesMetaData.positionMetaDatas {
                    
                    var positionView:GZPositionEditView = self.positionView(forIdentifier: positionMetaData.identifier) as GZPositionEditView
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
    
    var positionViews:[String:GZPositionEditView] = [:]
    
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
                borderBezierPath.appendPath(position.bezierPath)
            }
            
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
    

    func positionView(forIdentifier identifier:String)->GZPositionView! {

        return self.positionViews[identifier] //filtedPositionViews.first
        
    }
    
    func setImage(image:UIImage?, forPosition identifier:String){
        
        var positionView = self.positionView(forIdentifier: identifier) as? GZPositionEditView
        
        positionView?.image = image
        
//        self.privateObjectInfo.imageMetaData[identifier] = image
        
    }
    
    func imageForPosition(identifier:String)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: identifier) as? GZPositionEditView
        return positionView?.image
        
    }
    
    func imageForPosition(position:GZPosition)->UIImage?{
        
        var positionView = self.positionView(forIdentifier: position.identifier) as? GZPositionEditView
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
        
        var imageMetaData = self.privateObjectInfo.imageMetaData
        
        for (identifier,positionView) in self.positionViews{
            
            positionView.removeFromSuperview()
            
        }
        
        self.positionViews.removeAll(keepCapacity: false)
        
        for position in layout.positions {
            
            var positionView = GZPositionEditView(position: position)
            positionView.layoutView = self
            
            if let image = imageMetaData[position.identifier] {
                positionView.image = image
            }
            
            self.addSubview(positionView)
            
            self.positionViews[position.identifier] = positionView
            
        }
        
        if let position = layout.position(forIdentifier: currentPosition.identifier){
            self.changeCurrentPosition(position)
        }else{
            self.changeCurrentPosition(layout.positions.first)
        }
        
/* 先別刪 要看之後還會不會自動layout
//        for i in 0 ..< self.positionViews.count {
//            
//            var positionView = self.positionViews[i]
//            
//            positionView.position = layout.positions[i]
//            positionView.applyMask(self.frame.size)
//            
//        }
*/
        
        self.bringSubviewToFront(self.borderView)
        self.bringSubviewToFront(self.highlighView)
        
        self.privateObjectInfo.layout = layout
        
//        self.setNeedsLayout()
        
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
        var imageMetaData:[String:UIImage] = [:]
        var currentPosition:GZPosition! = nil
        
    }
    
    //MARK: Touch Event Handler
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        var anyTouch = touches.anyObject() as UITouch
        var location = anyTouch.locationInView(self)
        
    }
    
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        var anyTouch = touches.anyObject() as UITouch
        
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

class GZPositionEditView:GZPositionView {
    
    let minZoomScale: CGFloat = 1.0
    let maxZoomScale: CGFloat = 3.0
    
    var imageViewRatio: CGFloat = 1.0
    
    
    var metaData:GZPositionViewMetaData{
        
        set{
            self.imageMetaData = newValue.imageMetaData
            self.scrollViewMetaData = newValue.scrollViewMetaData
        }
        
        get{
            return GZPositionViewMetaData(imageMetaData: self.imageMetaData, scrollViewMetaData: self.scrollViewMetaData)
        }
    }
    
    var scrollViewMetaData:GZScrollViewMetaData{
        
        set{
            
            self.scrollView.zoomScale = newValue.zoomScale
            self.scrollView.contentSize = newValue.contentSize
            self.scrollView.contentOffset = newValue.contentOffset
            
        }
        
        get{
            return GZScrollViewMetaData(scrollView: self.scrollView)
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
            
            var imageMetaData = parentLayoutView.privateObjectInfo.imageMetaData
            
            if let newImage = image {
                imageMetaData[self.identifier] = newImage
            }else{
                imageMetaData.removeValueForKey(self.identifier)
            }
            
            parentLayoutView.privateObjectInfo.imageMetaData = imageMetaData
            
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = self.bounds
        self.resetScrollView(self.scrollView, image: self.image)
        
    }
    
}

//MARK: - Crop & Resize support

extension GZPositionEditView : UIScrollViewDelegate {
    
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
            
            if scrollViewWidth > scrollViewHeight {
                
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                let ratio = scrollViewWidth / vaildImageWidth
                
                //
                targetSize = CGSize(width:scrollViewWidth , height: vaildImageHeight * ratio)
                
                
            }else if scrollViewWidth < scrollViewHeight {
                
                //以scrollView的height為基準計算image原始size與scrollView size的ratio，以便算出相對應的width
                let ratio = scrollViewHeight / vaildImageHeight
                
                //
                targetSize = CGSize(width:vaildImageWidth * ratio , height: scrollViewHeight)
                
            }else{
                
                //如果ScrollView是正方形的情況
                //就要改判斷image的原始size，來進行調整，不過基準以image的最短邊拉大的方式計算
                if vaildImageWidth > vaildImageHeight {
                    
                    //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                    let ratio = scrollViewHeight / vaildImageHeight
                    
                    //
                    targetSize = CGSize(width:vaildImageWidth * ratio , height: scrollViewHeight)
                    
                }else{
                    
                    //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                    let ratio = scrollViewWidth / vaildImageWidth
                    
                    //
                    targetSize = CGSize(width:scrollViewWidth , height: vaildImageHeight * ratio)
                    
                }
                
                
                
            }
            
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
        scrollView.contentSize = scrollView.frame.size
        
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
    
    private lazy var borderView:GZHighlightBorderView = {
        var borderView = GZHighlightBorderView()
        self.addSubview(borderView)
        return borderView
    }()
    
    private lazy var cameraView:GZCameraView = {
        
        var cameraView = GZCameraView()
        cameraView.userInteractionEnabled = false
        self.addSubview(cameraView)
        
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.userInteractionEnabled = false
        self.cameraView.frame = self.bounds
        
    }
    
    override func applyMask(size: CGSize) {
        super.applyMask(size)
        
        self.borderView.bezierPath = self.maskBezierPath
        self.borderView.frame = self.bounds
        
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
    
    override init() {
        super.init()
        
        self.setup()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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

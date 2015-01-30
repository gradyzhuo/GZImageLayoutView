//
//  GZImageLayoutView.swift
//  GZImageLayoutView
//
//  Created by Grady Zhuo on 1/22/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import UIKit
import AVFoundation


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
    
    convenience init(json:[[NSObject:AnyObject]]){
        
        var position:[GZPosition] = json.map{GZPosition(dataDict: $0)}
        
        self.init(positions:position)

    }
    
    init(positions:[GZPosition]) {
        
        self.privateObjectInfo.positions = positions
        
    }
    
    
    func position(forIdentifier identifier:String)->GZPosition! {
        
        var filtedPositionViews = self.positions.filter{ return ($0 as GZPosition).identifier == identifier  }
        return filtedPositionViews.first
    }
    
    
    private struct ObjectInfo{
        
        var positions:[GZPosition] = []

    }
    
    
}


class GZImageLayoutView: UIView {
    
    var layout:GZLayout = GZLayout.fullLayout()
    
    var positionViews:[GZPositionView] = []
    
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
                self.currentPosition = nil//self.layout.positions.first?.identifier
                
            } else {
                self.borderView.hidden = true
                self.currentPosition = self.layout.positions.first
                self.highlighView.hidden = false
                
            }
            
        }
    }
    
    
    var currentPosition:GZPosition!{
        didSet{
            
            
            if currentPosition != nil {
                self.highlighView.position = currentPosition
                self.highlighView.applyMask(self.frame.size)
                
            }
            
            
        }
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
            self.borderView.borderColor = borderColor
        }
        
        get{
            return self.borderView.borderColor
        }
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure(self.layout)
        
    }
    
    
    init(layout:GZLayout, frame:CGRect = CGRect()){
        super.init(frame:frame)
        
        self.configure(layout)
        
    }
    
    func configure(layout:GZLayout){
        
        self.relayout(layout)
        self.currentPosition = layout.positions.first
        
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
        
    }
    
    func positionView(forIdentifier identifier:String)->GZPositionView! {
        
        var filtedPositionViews = self.positionViews.filter{ return ($0 as GZPositionView).position.identifier == identifier  }
        return filtedPositionViews.first
        
    }
    
    func setImage(image:UIImage?, forPosition identifier:String){
        
        var positionView = self.positionView(forIdentifier: identifier) as GZPositionEditView
        positionView.image = image
        
    }
    
    func relayout(layout:GZLayout){
        
        if self.positionViews.count > layout.positions.count {
            
            for i in 0 ..< self.positionViews.count-layout.positions.count {
                
                var lastPositionView = self.positionViews.removeLast()
                lastPositionView.removeFromSuperview()
            }
            
            
            self.currentPosition = layout.positions.first
            
        }else if self.positionViews.count < layout.positions.count {
            
            for i in 0 ..< layout.positions.count - self.positionViews.count {
                
                var positionView = GZPositionEditView()
//                positionView.backgroundColor = UIColor.greenColor()
                
                positionView.scrollView.contentSize = CGSize(width: 1000, height: 1000)
                
                if let lastPositionView = self.positionViews.last {
                    self.insertSubview(positionView, belowSubview: self.positionViews.last!)
                    
                }else{
                    self.addSubview(positionView)
                }
                
                
                self.positionViews.append(positionView)
                
            }
            
        }
        
        if let currentPosition = self.currentPosition {
            
            
            if let position = layout.position(forIdentifier: currentPosition.identifier){
                self.currentPosition = position
            }else{
                self.currentPosition = layout.positions.first
            }
            
        }
        
        for i in 0 ..< self.positionViews.count {
            
            var positionView = self.positionViews[i]
            
            positionView.position = layout.positions[i]
            positionView.applyMask(self.frame.size)
            
        }
        self.bringSubviewToFront(self.borderView)
        self.bringSubviewToFront(self.highlighView)
        
        self.layout = layout
        
        self.setNeedsDisplay()
        
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
            self.currentPosition = positionView?.position            
            
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
    
    var maskBezierPath:UIBezierPath!

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
        self.layoutSubviews()
    }
    

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        if let maskLayer = self.layer.mask as? CAShapeLayer {
            
            var borderBeizerPath = UIBezierPath(CGPath: maskLayer.path)
            return borderBeizerPath.containsPoint(point)
            
        }
        
        return false
    }
    
}

class GZPositionEditView:GZPositionView, UIScrollViewDelegate {
    
    var image:UIImage!{
        didSet{
            self.imageView.image = image
        }
    }
    
    private lazy var scrollView:UIScrollView = {
        
        var scrollView = UIScrollView()
        self.addSubview(scrollView)
        
        return scrollView
    }()
    
    private lazy var imageView:UIImageView = {
        
        var imageView = UIImageView()
        self.scrollView.addSubview(imageView)
        
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        
        return imageView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = self.bounds
        self.imageView.frame = self.bounds
    }
    
    //MARK: scroll view delegate
    internal func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}


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

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.userInteractionEnabled = false
        self.cameraView.frame = self.bounds
        
    }
    
    override func applyMask(size: CGSize) {
        super.applyMask(size)

        self.borderView.bezierPath = self.maskBezierPath
        self.borderView.frame = self.bounds
//        self.borderView.setNeedsDisplay()
        
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

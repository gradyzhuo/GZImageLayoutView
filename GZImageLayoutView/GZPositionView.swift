//
//  GZPositionView.swift
//  Flingy
//
//  Created by Grady Zhuo on 6/17/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import Foundation

//MARK: -
public class GZPositionView: UIView {
    
    var position:GZPosition! = GZPosition.fullPosition(){
        didSet{
            if position == nil {
                
                self.layer.mask = nil
                self.frame = CGRect()
                
            }
        }
    }
    
    public var identifier:String {
        return self.position.identifier
    }
    
    public var maskBezierPath:UIBezierPath!
    
    internal(set) var layoutView:GZImageLayoutView?
    
    public init(layoutView:GZImageLayoutView? = nil, position:GZPosition! = nil, frame:CGRect = CGRect()){
        super.init(frame:frame)
        
        self.layoutView = layoutView
        self.configure(position)
        
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure(nil)
        
    }
    
    internal func configure(position:GZPosition!){
        self.position = position
    }
    
    internal func applyMask(size:CGSize){
        
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
    
    
    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        if let maskLayer = self.layer.mask as? CAShapeLayer {
            
            var borderBeizerPath = UIBezierPath(CGPath: maskLayer.path)
            return borderBeizerPath.containsPoint(point)
            
        }
        
        return false
    }
    
}


//MARK: - GZHighlightView

public class GZHighlightView: GZPositionView {
    
    private var componentConstraints:[String:[AnyObject]] = [:]
    
    private lazy var borderView:GZHighlightBorderView = {
        var borderView = GZHighlightBorderView()
        borderView.setTranslatesAutoresizingMaskIntoConstraints(false)
        return borderView
        }()
    
    internal lazy var cameraView:GZCameraView = {
        
        var cameraView = GZCameraView()
        cameraView.userInteractionEnabled = false
        cameraView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        return cameraView
        }()
    
    public var borderColor:UIColor{
        
        set{
            self.borderView.borderColor = newValue
        }
        
        get{
            return self.borderView.borderColor
        }
        
    }
    
    public var borderWidth:CGFloat {
        set{
            self.borderView.borderWidth = newValue
        }
        
        get{
            return self.borderView.borderWidth
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
        
        //        self.borderView.bezierPath = self.maskBezierPath
        self.setNeedsLayout()
        
    }
    
    
    override public func updateConstraints() {
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
public class GZHighlightBorderView: UIView {
    
    public var borderWidth:CGFloat = 2.0{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    public var borderColor:UIColor = UIColor.blackColor(){
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    public var layout:GZLayout = GZLayout.fullLayout()
    
    public init() {
        super.init(frame : CGRect.zeroRect)
        self.setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
        
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.setNeedsDisplay()
        
    }
    
    
    private func setup(){
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }
    
    
    override public func drawRect(rect: CGRect) {
        let halfBorderWidth = self.borderWidth * 0.5
        let borderBeizerPath = self.layout.unitBorderBezierPath()
        
        borderBeizerPath.lineWidth = self.borderWidth
        
        var transform = CGAffineTransformMakeTranslation(halfBorderWidth, halfBorderWidth)
        transform = CGAffineTransformScale(transform, self.bounds.width-self.borderWidth, self.bounds.height-self.borderWidth)
        borderBeizerPath.applyTransform(transform)
        
        
        
        self.borderColor.setStroke()
        borderBeizerPath.stroke()
        
        
    }
    
}


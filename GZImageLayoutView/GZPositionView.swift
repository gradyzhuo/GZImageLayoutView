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
    
    private func configure(position:GZPosition!){
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

public class GZImageEditorPositionView:GZPositionView {
    
    public let minZoomScale : CGFloat = 1.0
    public let maxZoomScale : CGFloat = 3.0
    
    public var imageRatio : CGFloat = 1.0
    
    private var privateObjectInfo = ObjectInfo()
    
    public var delegate:GZImageEditorPositionViewDelegate?
    
    public var metaData:GZPositionViewMetaData{
        
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
    
    public var scrollViewMetaData:GZScrollViewMetaData{
        
        set{
            self.scrollView.zoomScale = newValue.zoomScale
            self.scrollView.contentSize = newValue.contentSize
            self.scrollView.contentOffset = newValue.contentOffset
        }
        
        get{
            return GZScrollViewMetaData(scrollView: self.scrollView, imageRatio: self.imageRatio)
        }
        
    }
    
    public var imageMetaData:GZPositionViewImageMetaData{
        
        set{
            self.setImage(newValue.image, needResetScrollView: true)
        }
        
        get{
            return GZPositionViewImageMetaData(identifier: self.identifier, image: self.image)
        }
        
    }
    
    public var image:UIImage?{
        
        set{
            self.setImage(newValue, needResetScrollView: true)
        }
        
        get{
            return self.imageView.image
        }
        
    }
    
    private lazy var scrollView:GZImageCropperScrollView = {
        
        var scrollView = GZImageCropperScrollView(imageEditorPositionView: self)
        scrollView.scrollsToTop = false
        //        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
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
    
    internal override var layoutView:GZImageLayoutView?{
        
        didSet{
            
            var image = layoutView?.imageForPosition(self.identifier)
            
            if image == nil && self.image != nil {
                layoutView?.setImage(self.image, forPosition: self.identifier)
            }
        }
        
    }
    
    public func setImage(image:UIImage?, needResetScrollView reset:Bool){
        
        self.imageView.image = image
        
        if reset{
            self.resetScrollView(self.scrollView, image: image)
        }
        
        if let parentLayoutView = self.layoutView {
            
            var imageMetaData = parentLayoutView.imageMetaDataContent
            
            if let newImage = image {
                imageMetaData[self.identifier] = newImage
            }else{
                imageMetaData.removeValueForKey(self.identifier)
            }
            
            parentLayoutView.imageMetaDataContent = imageMetaData
            
        }
        
        
        
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = self.bounds
        
        var metaData = self.privateObjectInfo.metaData ?? self.metaData
        self.imageMetaData = metaData.imageMetaData
        self.scrollViewMetaData = metaData.scrollViewMetaData
        
    }
    
    
    struct ObjectInfo {
        var metaData:GZPositionViewMetaData! = nil
    }
    
    
    override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        if let touch = touches.first as? UITouch {
            let point = touch.locationInView(self)
            
            let hitView = self.hitTest(point, withEvent: event)
            
            if hitView == self.scrollView {
                
                self.delegate?.imageEditorPositionViewWillBeginEditing(self)
                
            }
            
        }
        
        
        
    }
    
}


//MARK: - Crop & Resize support

extension GZImageEditorPositionView {
    
    internal func resetScrollView(scrollView:UIScrollView, image:UIImage?){
        
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
    
    internal func initializeScrollView(scrollView:UIScrollView, contentSize:CGSize = CGSizeZero){
        
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = CGPointZero
        scrollView.contentSize = CGSizeZero
        
    }
    
    
}


extension GZImageEditorPositionView:UIScrollViewDelegate{
    //    //MARK: scroll view delegate
    //    internal func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    //        return self.imageView
    //    }
    //
    //    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    //        self.delegate?.scrollViewDidEndDecelerating?(scrollView)
    //    }
    //
    //    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    //        self.delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    //    }
    //
    //    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
    //        self.delegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    //    }
    //
    //    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
    //
    //        self.delegate?.imageEditorPositionViewDidEndEditByZooming(self)
    //        self.delegate?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
    //
    //    }
    //
    //    func scrollViewDidScroll(scrollView: UIScrollView) {
    //        self.delegate?.imageEditorPositionViewDidEditByScrolling(self)
    //        self.delegate?.scrollViewDidScroll?(scrollView)
    //    }
    //
    //    func scrollViewDidZoom(scrollView: UIScrollView) {
    //        self.delegate?.imageEditorPositionViewDidEditByZooming(self)
    //        self.delegate?.scrollViewDidZoom?(scrollView)
    //    }
    //
    //    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
    //        return false
    //    }
    //
    ////    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
    ////
    ////    }
    //
    //    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
    //        self.delegate?.imageEditorPositionViewWillBeginEditing(self)
    //        self.delegate?.scrollViewWillBeginDecelerating?(scrollView)
    //    }
    //
    //    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    //        self.delegate?.scrollViewWillBeginDragging?(scrollView)
    //    }
    //
    //    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
    //        self.delegate?.scrollViewWillBeginZooming?(scrollView, withView: view)
    //    }
    //
    //    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    //
    //        var metaData = self.scrollViewMetaData
    //        metaData.contentOffset = targetContentOffset.memory
    //
    //        self.delegate?.imageEditorPositionViewWillEndEditing(self, targetScrollViewMetaData: metaData)
    //        self.delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    //    }
    
    
    
    
    
    
    
    
    
    
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


//
extension GZImageCropperScrollView {
    
    //MARK: scroll view delegate
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageEditorPositionView.imageView
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.imageEditorPositionView.delegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.imageEditorPositionView.delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.imageEditorPositionView.delegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        
        
        if let imageEditorPositionView = self.imageEditorPositionView {
            imageEditorPositionView.delegate?.imageEditorPositionViewDidEndEditByZooming(imageEditorPositionView)
            imageEditorPositionView.delegate?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
        }
        
        
        
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        
        self.imageEditorPositionView.delegate?.scrollViewDidScroll?(scrollView)
        
        
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        self.imageEditorPositionView?.delegate?.imageEditorPositionViewDidEditByZooming(self.imageEditorPositionView!)
        self.imageEditorPositionView.delegate?.scrollViewDidZoom?(scrollView)
    }
    
    public func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return false
    }
    
    //    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
    //
    //    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.imageEditorPositionView.delegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.imageEditorPositionView.delegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
        self.imageEditorPositionView.delegate?.scrollViewWillBeginZooming?(scrollView, withView: view)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        var metaData = self.imageEditorPositionView.scrollViewMetaData
        metaData.contentOffset = targetContentOffset.memory
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillEndEditing(self.imageEditorPositionView, targetScrollViewMetaData: metaData)
        
        self.imageEditorPositionView.delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

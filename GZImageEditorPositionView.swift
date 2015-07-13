//
//  GZImageEditorPositionView.swift
//  Flingy
//
//  Created by Grady Zhuo on 7/2/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import Foundation

internal let GZImageEditorDefaultZoomScale : CGFloat = 1.0

public class GZImageEditorPositionView:GZPositionView {
    
    public var minZoomScale : CGFloat = GZImageEditorDefaultZoomScale
    public var maxZoomScale : CGFloat = 3.0
    
    internal var ratio:CGFloat = 1.0

    
    private var privateObjectInfo = ObjectInfo()
    
    public var delegate:GZImageEditorPositionViewDelegate?
    
    internal var resizeContentMode:GZImageEditorResizeContentMode = .AspectFill
    
    public var metaData:GZPositionViewMetaData{
        
        set{
            
            self.resizeContentMode = newValue.resizeContentMode
            
            self.imageMetaData = newValue.imageMetaData
            self.scrollViewMetaData = newValue.scrollViewMetaData
            
            self.privateObjectInfo.metaData = newValue
        }
        
        get{
            
            self.privateObjectInfo.metaData = GZPositionViewMetaData(resizeContentMode: self.resizeContentMode, imageMetaData: self.imageMetaData, scrollViewMetaData: self.scrollViewMetaData)
            
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
            return GZScrollViewMetaData(scrollView: self.scrollView, imageRatio: self.ratio)
        }
        
    }
    
    public var imageMetaData:GZPositionViewImageMetaData{
        
        set{
            self.setImage(self.resizeContentMode ,image: newValue.image, needResetScrollView: true)
        }
        
        get{
            return GZPositionViewImageMetaData(identifier: self.identifier, image: self.image)
        }
        
    }
    
    public var image:UIImage?{
        
        set{
            self.setImage(self.resizeContentMode, image: newValue, needResetScrollView: true)
        }
        
        get{
            return self.scrollView.imageView.image
        }
        
    }
    
    private lazy var scrollView:GZImageCropperScrollView = {
        
        var scrollView = GZImageCropperScrollView(imageEditorPositionView: self)
        scrollView.scrollsToTop = false
        scrollView.delaysContentTouches = false
        
        scrollView.minimumZoomScale = self.minZoomScale
        scrollView.maximumZoomScale = self.maxZoomScale
        
        return scrollView
        }()
    
//    public internal(set) lazy var imageView:UIImageView = {
//        
//        var imageView = UIImageView()
//        imageView.contentMode = UIViewContentMode.ScaleAspectFill
//        
//        
//        return imageView
//    }()
    
    override func configure(position: GZPosition!) {
        super.configure(position)
        
        self.addSubview(self.scrollView)
//        self.scrollView.addSubview(self.imageView)
        
        
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
    
    public func setImage(resizeContentMode: GZImageEditorResizeContentMode,image:UIImage?, needResetScrollView reset:Bool){
        
        self.scrollView.imageView.image = image
        
        if reset{
            self.resetScrollView(resizeContentMode: resizeContentMode, scrollView: self.scrollView, image: image)
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
    
    internal func resetResizeContentMode(resizeContentMode : GZImageEditorResizeContentMode = .AspectFill){
        self.resetScrollView(resizeContentMode: resizeContentMode, scrollView: self.scrollView, image: self.image)
    }
    
    internal func resetScrollView(resizeContentMode : GZImageEditorResizeContentMode = .AspectFill, scrollView:UIScrollView, image:UIImage?){
        
        self.initializeScrollView(scrollView)
        
        if let vaildImage = image{
            
            //預先取出所需的屬性值
            let scrollViewWidth = scrollView.frame.width
            let scrollViewHeight = scrollView.frame.height
            let vaildImageWidth = vaildImage.size.width
            let vaildImageHeight = vaildImage.size.height
            
            var zoomScaleToFillScreen:CGFloat = 1.0
            var targetSize = CGSize.zeroSize
             (self.ratio, targetSize, zoomScaleToFillScreen) = resizeContentMode.targetContentSize(scrollSize: scrollView.frame.size, imageSize: vaildImage.size)
            scrollView.maximumZoomScale = ceil(zoomScaleToFillScreen) + 2
            
            //
            scrollView.contentSize = targetSize
            
            //
            self.scrollView.imageView.frame.size = targetSize
            
            let xOffsetToCenter:CGFloat = (targetSize.width - scrollViewWidth)/2
            let yOffsetToCenter:CGFloat = (targetSize.height - scrollViewHeight)/2
            
            scrollView.contentOffset.x += xOffsetToCenter
            scrollView.contentOffset.y += yOffsetToCenter
            
            scrollView.setZoomScale(zoomScaleToFillScreen, animated: false)
            
        }
        
    }
    
    internal func initializeScrollView(scrollView:UIScrollView, contentSize:CGSize = CGSizeZero){
        
        scrollView.zoomScale = self.minZoomScale
        scrollView.contentOffset = CGPointZero
        scrollView.contentSize = CGSizeZero
        
    }
    
    
}

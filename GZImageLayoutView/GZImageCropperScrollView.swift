//
//  GYImageCropperScrollView.swift
//  Flingy
//
//  Created by Grady Zhuo on 5/31/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import UIKit

public class GZImageCropperScrollView: UIScrollView {

    static var touchCount:Int = 0
    
    public internal(set) lazy var imageView:UIImageView = {
        
        var imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        return imageView
    }()
    
    public internal(set) var imageEditorPositionView:GZImageEditorPositionView!
    
    internal var resizeContentMode:GZImageEditorResizeContentMode = .AspectFill
    
    internal init(imageEditorPositionView:GZImageEditorPositionView){
        super.init(frame: CGRect.zero)
        self.imageEditorPositionView = imageEditorPositionView
        self.delegate = self
        self.addSubview(self.imageView)
    }

    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        //讓imageView 縮到最小時還可以置中的方式
        
        let boundsSize = self.bounds.size
        var frameToCenter = self.imageView.frame
        
        if frameToCenter.width < boundsSize.width {
            self.contentOffset.x = -(boundsSize.width - frameToCenter.width) / 2
        }

        if frameToCenter.height < boundsSize.height {
            self.contentOffset.y = -( boundsSize.height - frameToCenter.height ) / 2
        }else{
            frameToCenter.origin.y = 0
        }
        
//        self.imageView.frame = frameToCenter
        
//        // center the image as it becomes smaller than the size of the screen
//        CGSize boundsSize = self.bounds.size;
//        CGRect frameToCenter = tileContainerView.frame;
//        
//        // center horizontally
//        if (frameToCenter.size.width < boundsSize.width)
//        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
//        else
//        frameToCenter.origin.x = 0;
//        
//        // center vertically
//        if (frameToCenter.size.height < boundsSize.height)
//        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
//        else
//        frameToCenter.origin.y = 0;
//        
//        tileContainerView.frame = frameToCenter;
        
    }
    
    public override func touchesShouldBegin(touches: Set<UITouch>, withEvent event: UIEvent?, inContentView view: UIView) -> Bool {
        
        GZImageCropperScrollView.touchCount = 0
        
        return true
    }

    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        print("touches.count:\(touches.count)")
        
        GZImageCropperScrollView.touchCount += touches.count
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillBeginEditing(self.imageEditorPositionView)
        
    }
    
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        GZImageCropperScrollView.touchCount -= touches.count
        
        if GZImageCropperScrollView.touchCount == 0 {
            self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEndEditing(self.imageEditorPositionView)
        }
        
        
    }
    

    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        GZImageCropperScrollView.touchCount -= touches?.count ?? 0
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEditByScrolling(imageEditorPositionView)
        
    }
    
}


//
extension GZImageCropperScrollView : UIScrollViewDelegate {
    
    //MARK: scroll view delegate
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
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
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        
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
    
    public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        self.imageEditorPositionView.delegate?.scrollViewWillBeginZooming?(scrollView, withView: view)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let targetOffset = targetContentOffset.memory
        
        var metaData = self.imageEditorPositionView.scrollViewMetaData
        metaData.contentOffset = targetOffset
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillEndEditing(self.imageEditorPositionView, targetScrollViewMetaData: metaData)
        
        self.imageEditorPositionView.delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        
        
//        //讓imageView 縮到最小時還可以置中的方式
//        
//        let boundsSize = self.bounds.size
//        var frameToCenter = self.imageView.frame
//        
//        if frameToCenter.width < boundsSize.width {
//            targetOffset.x = (boundsSize.width - frameToCenter.width) / 2
//        }
//        
//        if frameToCenter.height < boundsSize.height {
//            targetOffset.y = ( boundsSize.height - frameToCenter.height ) / 2
//        }
//        
//        targetContentOffset.memory = targetOffset
        
    }
}

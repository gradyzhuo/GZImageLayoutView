//
//  GYImageCropperScrollView.swift
//  Flingy
//
//  Created by Grady Zhuo on 5/31/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import UIKit

public class GZImageCropperScrollView: UIScrollView, UIScrollViewDelegate {

    static var touchCount:Int = 0
    
    public var imageEditorPositionView:GZImageEditorPositionView!
    
    internal init(imageEditorPositionView:GZImageEditorPositionView){
        super.init(frame: CGRect.zeroRect)
        self.imageEditorPositionView = imageEditorPositionView
        self.delegate = self
    }

    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func touchesShouldBegin(touches: Set<NSObject>!, withEvent event: UIEvent!, inContentView view: UIView!) -> Bool {
        
        GZImageCropperScrollView.touchCount = 0
        
        return true
    }

    override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        println("touches.count:\(touches.count)")
        
        GZImageCropperScrollView.touchCount += touches.count
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillBeginEditing(self.imageEditorPositionView)
        
    }
    
    
    override public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        GZImageCropperScrollView.touchCount -= touches.count
        
        if GZImageCropperScrollView.touchCount == 0 {
            self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEndEditing(self.imageEditorPositionView)
        }
        
        
    }
    

    public override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        GZImageCropperScrollView.touchCount -= touches.count
    }
    
    override public func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEditByScrolling(imageEditorPositionView)
        
    }
    
}

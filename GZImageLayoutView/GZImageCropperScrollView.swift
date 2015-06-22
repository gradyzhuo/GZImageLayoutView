//
//  GYImageCropperScrollView.swift
//  Flingy
//
//  Created by Grady Zhuo on 5/31/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import UIKit

public class GZImageCropperScrollView: UIScrollView, UIScrollViewDelegate {

    public var imageEditorPositionView:GZImageEditorPositionView!
    
    internal init(imageEditorPositionView:GZImageEditorPositionView){
        super.init(frame: CGRect.zeroRect)
        self.imageEditorPositionView = imageEditorPositionView
        self.delegate = self
    }

    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillBeginEditing(self.imageEditorPositionView)
        
    }
    
    
    override public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEndEditing(self.imageEditorPositionView)
    }
    
    override public func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEditByScrolling(imageEditorPositionView)
        
    }
    
}

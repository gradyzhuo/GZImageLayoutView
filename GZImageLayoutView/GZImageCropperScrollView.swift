//
//  GYImageCropperScrollView.swift
//  Flingy
//
//  Created by Grady Zhuo on 5/31/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import UIKit

class GZImageCropperScrollView: UIScrollView, UIScrollViewDelegate {

    var imageEditorPositionView:GZImageEditorPositionView!
    
    init(imageEditorPositionView:GZImageEditorPositionView){
        super.init(frame: CGRect.zeroRect)
        self.imageEditorPositionView = imageEditorPositionView
        self.delegate = self
    }

    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewWillBeginEditing(self.imageEditorPositionView)
        
    }
    
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEndEditing(self.imageEditorPositionView)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)
        
        self.imageEditorPositionView.delegate?.imageEditorPositionViewDidEditByScrolling(imageEditorPositionView)
        
    }
    
}

//
//  GZImageEditorResizeContentMode.swift
//  Flingy
//
//  Created by Grady Zhuo on 7/2/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import Foundation

public enum GZImageEditorResizeContentMode : Int {
    
    case AspectFit
    case AspectFill
    
    /// return (ratio, targetContentSize:base on zoomscale 1, zoomScaleToFillScreen)
    internal func targetContentSize(#scrollSize:CGSize, imageSize:CGSize)->(ratio:CGFloat,targetContentSiz:CGSize, zoomScaleToFillScreen:CGFloat) {
        
        switch self {
        case .AspectFill:
            return self.aspectFillTargetContentSize(scrollSize : scrollSize, imageSize : imageSize)
        case .AspectFit:
            return self.aspectFitTargetContentSize(scrollSize : scrollSize, imageSize : imageSize)
            
        }
        
    }
    
    
    private func aspectFillTargetContentSize(#scrollSize:CGSize, imageSize:CGSize)->(ratio:CGFloat,targetContentSiz:CGSize, zoomScaleToFillScreen:CGFloat){
        //看scrollView的 width > height or width < height 決定那一邊要為基準
        
        var targetSize:CGSize = CGSize.zeroSize
        var ratio:CGFloat = 1.0
        
        if scrollSize.width > scrollSize.height {
            
            //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
            ratio = scrollSize.width / imageSize.width
            
            //
            targetSize = CGSize(width:scrollSize.width , height: imageSize.height * ratio)
            
            
        }else if scrollSize.width < scrollSize.height {
            
            //以scrollView的height為基準計算image原始size與scrollView size的ratio，以便算出相對應的width
            ratio = scrollSize.height / imageSize.height
            
            //
            targetSize = CGSize(width:imageSize.width * ratio , height: scrollSize.height)
            
        }else{
            
            //如果ScrollView是正方形的情況
            //就要改判斷image的原始size，來進行調整，不過基準以image的最短邊拉大的方式計算
            if imageSize.width > imageSize.height {
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                ratio = scrollSize.height / imageSize.height
                
                //
                targetSize = CGSize(width:imageSize.width * ratio , height: scrollSize.height)
                
            }else{
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                ratio = scrollSize.width / imageSize.width
                
                //
                targetSize = CGSize(width:scrollSize.width , height: imageSize.height * ratio)
                
            }
            
            
            
        }
        
        return (ratio:ratio, targetContentSiz:targetSize, zoomScaleToFillScreen:1.0)
        
    }
    
    private func aspectFitTargetContentSize(#scrollSize:CGSize, imageSize:CGSize)->(ratio:CGFloat,targetContentSiz:CGSize, zoomScaleToFillScreen:CGFloat){
        
        //看scrollView的 width > height or width < height 決定那一邊要為基準
        
        var targetSize:CGSize = CGSize.zeroSize
        var ratio:CGFloat = 1.0
        
        var zoomScale:CGFloat = 1.0
        
        if scrollSize.width > scrollSize.height {
            
            //以scrollView的height為基準計算image原始size與scrollView size的ratio，以便算出相對應的width
            ratio = scrollSize.height / imageSize.height
            
            //
            let targetWidth = imageSize.width * ratio
            targetSize = CGSize(width: targetWidth, height: scrollSize.height)
            zoomScale = (scrollSize.width/targetWidth)
            
        }else if scrollSize.width < scrollSize.height {
            
            //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
            ratio = scrollSize.width / imageSize.width
            
            //
            let targetHeight = imageSize.height * ratio
            targetSize = CGSize(width:scrollSize.width , height: targetHeight)
            zoomScale = (scrollSize.height/targetHeight)
            
        }else{
            
            //如果ScrollView是正方形的情況
            //就要改判斷image的原始size，來進行調整，不過基準以image的最長邊拉大的方式計算
            if imageSize.width > imageSize.height {
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                ratio = scrollSize.width / imageSize.width
                
                //
                let targetHeight = imageSize.height * ratio
                targetSize = CGSize(width:scrollSize.width , height: imageSize.height * ratio)
                
                zoomScale = (scrollSize.height/targetHeight)
                
            }else{
                
                //以scrollView的width為基準計算image原始size與scrollView size的ratio，以便算出相對應的height
                ratio = scrollSize.height / imageSize.height
                
                //
                let targetWidth = imageSize.width * ratio
                targetSize = CGSize(width:imageSize.width * ratio , height: scrollSize.height)
                zoomScale = (scrollSize.width/targetWidth)
                
            }
            
            
            
        }
        
        return (ratio:ratio,targetContentSiz:targetSize,zoomScaleToFillScreen:zoomScale)
    }
    
}

extension GZImageEditorResizeContentMode {
    
}

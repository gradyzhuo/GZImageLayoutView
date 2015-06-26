//
//  MetaDataDefines.swift
//  Flingy
//
//  Created by Grady Zhuo on 6/18/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import Foundation

public struct GZScrollViewMetaData {
    
    public var contentSize:CGSize
    public var contentOffset:CGPoint
    public var zoomScale:CGFloat
    public var frame:CGRect
    public var imageRatio:CGFloat
    
    internal init(scrollView:UIScrollView, imageRatio ratio:CGFloat){
        self.contentSize = scrollView.contentSize
        self.contentOffset = scrollView.contentOffset
        self.zoomScale = scrollView.zoomScale
        self.frame = scrollView.frame
        self.imageRatio = ratio
    }
    
    public var cropInfo:GZCropInfo{
        
        var contentOffset = self.contentOffset
        var zoomScale = self.zoomScale
        var imageRatio = self.imageRatio
        
        var scrollViewSize = self.frame.size
        
        //        var cropRatio = zoomScale / imageRatio
        
        var cropWidth = scrollViewSize.width / zoomScale / imageRatio
        var cropHeight = scrollViewSize.height / zoomScale / imageRatio
        var cropX = contentOffset.x / zoomScale / imageRatio
        var cropY = contentOffset.y / zoomScale / imageRatio
        
        return GZCropInfo(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
    }
    
}

public struct GZPositionViewImageMetaData{
    public var identifier:String
    public var image:UIImage!
}

public struct GZCropInfo:Printable, DebugPrintable{
    
    public let bounds:CGRect
    
    public let angle:CGFloat
    
    public var x:CGFloat{
        return self.bounds.minX
    }
    
    public var y:CGFloat{
        return self.bounds.minY
    }
    
    public var width:CGFloat{
        return self.bounds.width
    }
    
    public var height:CGFloat{
        return self.bounds.height
    }
    
    
    internal init(rect:CGRect, angle:CGFloat){
        self.bounds = rect
        self.angle = angle
    }
    
    internal init(x:CGFloat, y:CGFloat, width:CGFloat, height:CGFloat, angle:CGFloat){
        
        self.bounds = CGRect(x: x, y: y, width: width, height: height)
        self.angle = angle
        
    }
    
    init(x:CGFloat, y:CGFloat, width:CGFloat, height:CGFloat){
        
        self.bounds = CGRect(x: x, y: y, width: width, height: height)
        self.angle = 0
    }
    
    public var description: String {
        return "GZCropInfo:{x:\(self.bounds.minX), y:\(self.bounds.minY), width:\(self.bounds.width), height:\(self.bounds.height), angle:\(self.angle)}"
    }
    
    public var debugDescription: String {
        return self.description
    }
    
}


public struct GZPositionViewMetaData : Equatable {
    
    public var imageMetaData:GZPositionViewImageMetaData
    public var scrollViewMetaData:GZScrollViewMetaData
    
    public var identifier:String{
        return self.imageMetaData.identifier
    }
    
    public var image:UIImage?{
        return self.imageMetaData.image
    }
    
    public var cropInfo:GZCropInfo{
        return self.scrollViewMetaData.cropInfo
    }
    
}

public func ==(lhs: GZPositionViewMetaData, rhs: GZPositionViewMetaData) -> Bool{
    var lhsImage = lhs.image ?? UIImage()
    return (lhs.identifier == rhs.identifier) && lhsImage.isEqual(rhs.image)
}

public struct GZLayoutViewImagesMetaData {
    
    public var positionMetaDatas:[GZPositionViewMetaData]
    
    public var content:[String:UIImage]{
        
        var content:[String:UIImage] = [:]
        for positionMetaData in self.positionMetaDatas{
            content[positionMetaData.identifier] = positionMetaData.image
        }
        
        return content
    }
    
    public var numberOfImages:Int{
        return self.positionMetaDatas.count
    }
    
    public var identifiers:[String]{
        return self.positionMetaDatas.map { return $0.identifier }
    }
    
    public var cropInfos:[GZCropInfo]{
        return self.positionMetaDatas.map{ return $0.cropInfo }
    }
    
    public func image(forPosition identifier:String)->UIImage!{
        
        if let index = find(self.identifiers, identifier) {
            
            var positionMetaData = self.positionMetaDatas[index]
            return positionMetaData.image
            
        }
        
        return nil
    }
    
    
    public func positionViewMetaData(forPosition identifier:String)->GZPositionViewMetaData!{
        
        if let index = find(self.identifiers, identifier) {
            
            var positionMetaData = self.positionMetaDatas[index]
            return positionMetaData
            
        }
        
        return nil
    }
    
    public func isExist(forPosition identifier:String)->Bool{
        return find(self.identifiers, identifier) != nil
    }
    
    
    internal init(positionViews:[GZImageEditorPositionView]){
        
        var positionMetaDatas:[GZPositionViewMetaData] = []
        
        for positionView in positionViews {
            positionMetaDatas.append(positionView.metaData)
        }
        
        self.positionMetaDatas = positionMetaDatas
        
    }
    
}

public struct GZLayoutViewMetaData{
    
    
    public var layout:GZLayout
    public var imagesMetaData:GZLayoutViewImagesMetaData
    
    public var numerOfPositions:Int{
        return self.imagesMetaData.numberOfImages
    }
    
    public var cropInfos:[GZCropInfo]{
        return self.imagesMetaData.cropInfos
    }
    
    internal init(layoutView:GZImageLayoutView){
        
        self.imagesMetaData = GZLayoutViewImagesMetaData(positionViews: layoutView.positionViews)
        self.layout = layoutView.layout
        
    }
    
}
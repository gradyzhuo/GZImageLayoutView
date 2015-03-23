//
//  GZLayout.swift
//  Flingy
//
//  Created by Grady Zhuo on 3/4/15.
//  Copyright (c) 2015 Skytiger Studio. All rights reserved.
//

import Foundation

enum GZLayoutPointUnit:Printable{
    
    init(dataDict:[NSObject:AnyObject]) {
        
        var type = dataDict["type"] as String
        var point = dataDict["point"] as [CGFloat]
        var control1:[CGFloat]? = dataDict["control1"] as? [CGFloat]
        var control2:[CGFloat]? = dataDict["control2"] as? [CGFloat]
        
        self.init(type:type, point:point, control1:control1, control2:control2)
        
    }
    
    
    init(type:String, point:[CGFloat], control1:[CGFloat]?, control2:[CGFloat]?){
        
        var point:CGPoint = {
            var x = CGFloat(point[0])
            var y = CGFloat(point[1])
            return CGPoint(x: x, y: y)
        }()
        
        var controlPoint1:CGPoint? = {
            
            if let control1 = control1 {
                var x = CGFloat(control1[0])
                var y = CGFloat(control1[1])
                return CGPoint(x:x, y:y)
            }
            
            return nil
        }()
        
        var controlPoint2:CGPoint? = {
            if let control2 = control2 {
                var x = CGFloat(control2[0])
                var y = CGFloat(control2[1])
                return CGPoint(x:x, y:y)
            }
            return nil
        }()
        
        self.init(type:type, point:point, controlPoint1:controlPoint1, controlPoint2:controlPoint2)
        
    }
    
    init(type:String, point:CGPoint, controlPoint1 control1:CGPoint?, controlPoint2 control2:CGPoint?){
        
        switch type {
        case "move":
            self = GZLayoutPointUnit.Move(toPoint: point)
            
        case "line":
            self = GZLayoutPointUnit.Line(toPoint: point)
            
        case "curve":
            var controlPoint1 = control1 ?? point
            var controlPoint2 = control2 ?? point
            self = GZLayoutPointUnit.Curve(toPoint:point, controlPoint1:controlPoint1, controlPoint2:controlPoint2)

        default:
            self = GZLayoutPointUnit.Undefined
            
        }
        
    }
    
    case Undefined
    case Move(toPoint:CGPoint)
    case Line(toPoint:CGPoint)
    case Curve(toPoint:CGPoint,controlPoint1:CGPoint,controlPoint2:CGPoint)
    
    func isMove()->Bool{
        switch self {
        case let .Move:
            return true
        default:
            return false
        }
    }
    
    func isLine()->Bool{
        switch self {
        case .Line:
            return true
        default:
            return false
        }
    }
    
    func isCurve()->Bool{
        switch self {
        case .Curve:
            return true
        default:
            return false
        }
    }
    
    func convertToMoveUnit()->GZLayoutPointUnit{
        switch self {
        case let .Move(toPoint: point):
            return self
        case let .Line(toPoint: point):
            return GZLayoutPointUnit.Move(toPoint: point)
        case let .Curve(toPoint:point, controlPoint1:controlPoint1, controlPoint2:controlPoint2):
            return GZLayoutPointUnit.Move(toPoint: point)
        default:
            return GZLayoutPointUnit.Move(toPoint: CGPoint())
        }
    }
    
    func applyToBezierPath(bezierPath:UIBezierPath){
        switch self {
        case let .Move(toPoint: point):
            bezierPath.moveToPoint(point)
        case let .Line(toPoint: point):
            bezierPath.addLineToPoint(point)
        case let .Curve(toPoint:point,controlPoint1:controlPoint1,controlPoint2:controlPoint2):
            bezierPath.addCurveToPoint(point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            
        case .Undefined:
            println("Error: illegal Point Unit:\(self)")
        }
    }
    
    
    var description:String{
        switch self {
        case .Move:
            return "Move"
        case .Line:
            return "Line"
        case .Curve:
            return "Curve"
        case .Undefined:
            return "Undefined"
        }
    }
}


//let kGZImageLayoutJSONLayoutIdentifierName = "identifier"
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
    
    var shouldClosePath:Bool{
        return self.privateObjectInfo.shouldClosePath
    }
    
    var bezierPath:UIBezierPath {
        
        self.privateObjectInfo.layoutPoints[0] = self.layoutPoints[0].convertToMoveUnit()
        
        var bezier = self.layoutPoints.reduce(UIBezierPath(), combine: { (bezierPath:UIBezierPath, pointUnit:GZLayoutPointUnit) -> UIBezierPath in
            pointUnit.applyToBezierPath(bezierPath)
            return bezierPath
        })
        
        if self.shouldClosePath {
            bezier.closePath()
        }
        
        return bezier
    }
    
    var maskBezierPath:UIBezierPath{
        
        var bezierPath = UIBezierPath()
        bezierPath.appendPath(self.bezierPath)
        
        var firstPoint = bezierPath.bounds.origin
        
        bezierPath.applyTransform(CGAffineTransformMakeTranslation(-firstPoint.x, -firstPoint.y))
        
        return bezierPath
    }
    
    convenience init(dataDict:[NSObject:AnyObject]) {
        
        var points:[GZLayoutPointUnit] = (dataDict["points"] as [[NSObject:AnyObject]]).map{ return GZLayoutPointUnit(dataDict: $0)}
        var identifier:String = dataDict["identifier"] as String
        
        var shouldClosePath = dataDict["closePath"] as Bool
        
        self.init(identifier:identifier, layoutPoints:points, closePath: shouldClosePath)
        
    }
    
    init(identifier:String, layoutPoints:[GZLayoutPointUnit], closePath:Bool){
        
        self.privateObjectInfo.identifier = identifier
        self.privateObjectInfo.layoutPoints = layoutPoints
        self.privateObjectInfo.shouldClosePath = closePath
    }
    
    func frame(multiple:CGSize)->CGRect{
        return CGRect()
    }
    
    private struct ObjectInfo {
        
        var identifier:String = kGZPositionIdentifierDefaultFull
        var layoutPoints:[GZLayoutPointUnit] = []
        var shouldClosePath:Bool = true
    }
    
    
}

extension GZPosition {
    
    class func fullPosition(identifier:String = kGZPositionIdentifierDefaultFull)->GZPosition {
        
        var moveToPointUnit = GZLayoutPointUnit.Move(toPoint: CGPoint(x: 0, y: 0))
        var leftBottomPointUnit = GZLayoutPointUnit.Line(toPoint: CGPoint(x: 0, y: 1))
        var rightBottomPointUnit = GZLayoutPointUnit.Line(toPoint: CGPoint(x: 1, y: 1))
        var rightTopPointUnit = GZLayoutPointUnit.Line(toPoint: CGPoint(x: 1, y: 0))
        
        return GZPosition(identifier: kGZPositionIdentifierDefaultFull, layoutPoints: [moveToPointUnit, leftBottomPointUnit, rightBottomPointUnit, rightTopPointUnit], closePath:true)
        
    }
    
}

class GZLayout {
    
    //    var contexts:[[NSObject:AnyObject]] = []
    
    var identifier:String{
        
        if self.privateObjectInfo.identifier == nil {
            var identifier = "Layout::"
            for position in self.positions {
                identifier += "\(position.bezierPath.hashValue)::"
            }
            
            return identifier
        }
        
        return self.privateObjectInfo.identifier
    }
    
    private var privateObjectInfo:ObjectInfo = ObjectInfo()
    
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
    
    
    convenience init(jsonString:String!){
        
        var jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        self.init(jsonData:jsonData)
        
    }
    
    convenience init(jsonData:NSData!, options:NSJSONReadingOptions = NSJSONReadingOptions.AllowFragments, error:NSErrorPointer = nil){
        
        var jsonObject: [String:AnyObject]? = NSJSONSerialization.JSONObjectWithData(jsonData, options: options, error: error) as? [String:AnyObject]
        self.init(jsonObject:jsonObject ?? [:])
    }
    
    convenience init(jsonObject:[String:AnyObject]){
        
        var identifier:String! = jsonObject["identifier"] as String
        var originalPositions = jsonObject["positions"] as [[NSObject:AnyObject]]
        var position:[GZPosition] = originalPositions.map{GZPosition(dataDict: $0)}
        
        self.init(identifier: identifier, positions:position)
        
    }
    
    convenience init(positions:[GZPosition]) {
        self.init(identifier:nil, positions:positions)
        
    }
    
    init(identifier:String!, positions:[GZPosition]) {
        self.privateObjectInfo.identifier = identifier
        self.privateObjectInfo.positions = positions
        
    }
    
    
    func position(forIdentifier identifier:String)->GZPosition! {
        
        var filtedPositionViews = self.positions.filter{ return ($0 as GZPosition).identifier == identifier  }
        return filtedPositionViews.first
    }
    
    
    private struct ObjectInfo{
        var identifier:String! = nil
        var positions:[GZPosition] = []
        
    }
    
    
}
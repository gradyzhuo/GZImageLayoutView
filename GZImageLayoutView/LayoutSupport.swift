//
//  Layouts.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/11/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation






public let GZLayoutSingle:GZLayout = {
    let singleJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Single", ofType: "json")!)
    return GZLayout(jsonData:singleJsonData)
}()

public let GZLayoutLeftRight:GZLayout = {
    let leftRightJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Left-Right", ofType: "json")!)
    return GZLayout(jsonData:leftRightJsonData)
    }()
public let GZLayoutTopDown:GZLayout = {
    let topDownJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Top-Down", ofType: "json")!)
    return GZLayout(jsonData:topDownJsonData)
}()



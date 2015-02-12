//
//  Layouts.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/11/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation

let singleJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Single", ofType: "json")!)
let leftRightJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Left-Right", ofType: "json")!)
let topDownJsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("Top-Down", ofType: "json")!)


let layoutSingle = GZLayout(jsonData:singleJsonData)
let layoutLeftRight = GZLayout(jsonData:leftRightJsonData)
let layoutTopDown = GZLayout(jsonData:topDownJsonData)


